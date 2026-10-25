{
  flake.homeModules.tools = {
    lib,
    pkgs,
    osConfig ? {},
    ...
  }: let
    enabled = osConfig.var.features.tools or false;

    lspDeps = with pkgs; [
      nixd
      typescript-language-server
      vtsls
      svelte-language-server
      tailwindcss-language-server
      luau-lsp
      pyright
      rust-analyzer
    ];

    serenaMcp = pkgs.writeShellApplication {
      name = "serena-mcp";
      runtimeInputs = [pkgs.uv pkgs.git] ++ lspDeps;
      text = ''
        exec uvx --from git+https://github.com/oraios/serena serena start-mcp-server "$@"
      '';
    };

    agentPreGuard = pkgs.writeShellApplication {
      name = "agent-pre-guard";
      runtimeInputs = with pkgs; [coreutils gnugrep jq];
      text = ''
        INPUT=$(cat)
        IS_AGY=$(jq -r 'has("toolCall")' <<< "$INPUT")
        TOOL_NAME=$(jq -r '.tool_name // .tool // .toolCall.name // empty' <<< "$INPUT")
        FILE_PATH=$(jq -r '.tool_input.file_path // .tool_input.path // .toolCall.args.file_path // .toolCall.args.path // .toolCall.args.TargetFile // empty' <<< "$INPUT")
        CONTENT=$(jq -r '.tool_input.content // .tool_input.new_str // .tool_input.new_string // .tool_input.patch // .toolCall.args.CodeContent // .toolCall.args.ReplacementContent // empty' <<< "$INPUT")

        deny() {
          local msg="$1"
          if [[ "$IS_AGY" == "true" ]]; then
            jq -nc --arg reason "$msg" '{decision: "deny", reason: $reason}'
            exit 0
          else
            echo "DENIED: $msg" >&2
            exit 2
          fi
        }

        # Gate 1: Enforce surgical retrieval (block reading full files over 150 lines)
        if [[ "$TOOL_NAME" =~ ^(Read|read|read_file|view_file)$ ]] && [[ -n "$FILE_PATH" ]] && [[ -f "$FILE_PATH" ]]; then
          LIMIT=$(jq -r '.tool_input.limit // .toolCall.args.EndLine // 0' <<< "$INPUT")
          LINES=$(wc -l < "$FILE_PATH")
          if (( LINES > 150 )) && (( LIMIT == 0 || LIMIT > 150 )); then
            deny "$FILE_PATH is $LINES lines. Full-file reads over 150 lines are banned. Use codebase-memory-mcp, Serena, or ast-grep first, or pass an exact offset and limit (under 80 lines)."
          fi
        fi

        # Gate 2 & 3: Protect linter configs and block suppression directives
        if [[ "$TOOL_NAME" =~ ^(Edit|Write|edit|write|write_file|edit_file|apply_patch|write_to_file|replace_file_content|multi_replace_file_content)$ ]]; then
          PROTECTED=("tsconfig.json" "biome.json" ".eslintrc" ".ruff.toml" "selene.toml" "statix.toml")
          for cfg in "''${PROTECTED[@]}"; do
            if [[ "$FILE_PATH" == *"$cfg" ]]; then
              deny "Modifying $cfg is forbidden. Fix the code instead of weakening the linter."
            fi
          done

          if grep -qE "@ts-ignore|@ts-expect-error|eslint-disable|# type: ignore|-- selene: allow|# statix ignore" <<< "$CONTENT"; then
            deny "Suppression comments (@ts-ignore, eslint-disable, type: ignore, selene: allow) are banned."
          fi
        fi

        [[ "$IS_AGY" == "true" ]] && echo "{}"
        exit 0
      '';
    };

    agentPostVerify = pkgs.writeShellApplication {
      name = "agent-post-verify";
      runtimeInputs = with pkgs; [
        alejandra
        biome
        coreutils
        deadnix
        jq
        nix
        ruff
        selene
        shellcheck
        shfmt
        statix
        stylua
      ];
      text = ''
        INPUT=$(cat)
        IS_AGY=$(jq -r 'has("toolCall")' <<< "$INPUT")
        FILE_PATH=$(jq -r '.tool_input.file_path // .tool_input.path // .toolCall.args.file_path // .toolCall.args.path // .toolCall.args.TargetFile // empty' <<< "$INPUT")

        fail_verify() {
          local tool="$1"
          local out="$2"
          if [[ "$IS_AGY" == "true" ]]; then
            echo "{}"
            exit 0
          else
            echo "VERIFICATION FAILED ($tool) in $FILE_PATH:" >&2
            echo "$out" >&2
            exit 2
          fi
        }

        if [[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]]; then
          [[ "$IS_AGY" == "true" ]] && echo "{}"
          exit 0
        fi

        case "$FILE_PATH" in
          *.ts|*.tsx|*.js|*.jsx|*.svelte|*.json)
            biome format --write "$FILE_PATH" >/dev/null 2>&1 || true
            OUT=$(biome check "$FILE_PATH" --max-diagnostics=4 2>&1) || fail_verify "Biome" "$(tail -n 12 <<< "$OUT")"
            ;;
          *.nix)
            alejandra --quiet "$FILE_PATH" >/dev/null 2>&1 || true
            OUT=$(nix-instantiate --parse "$FILE_PATH" 2>&1) || fail_verify "Nix Syntax" "$(head -n 8 <<< "$OUT")"
            OUT=$(statix check "$FILE_PATH" 2>&1) || fail_verify "Statix" "$(head -n 10 <<< "$OUT")"
            OUT=$(deadnix --fail "$FILE_PATH" 2>&1) || fail_verify "Deadnix" "$(head -n 10 <<< "$OUT")"
            ;;
          *.py)
            ruff format "$FILE_PATH" >/dev/null 2>&1 || true
            OUT=$(ruff check --output-format=concise "$FILE_PATH" 2>&1) || fail_verify "Ruff" "$(head -n 10 <<< "$OUT")"
            ;;
          *.lua|*.luau)
            stylua "$FILE_PATH" >/dev/null 2>&1 || true
            OUT=$(selene "$FILE_PATH" 2>&1) || fail_verify "Selene" "$(head -n 10 <<< "$OUT")"
            ;;
          *.sh|*.bash)
            shfmt -w "$FILE_PATH" >/dev/null 2>&1 || true
            OUT=$(shellcheck -f gcc "$FILE_PATH" 2>&1) || fail_verify "ShellCheck" "$(head -n 10 <<< "$OUT")"
            ;;
        esac

        [[ "$IS_AGY" == "true" ]] && echo "{}"
        exit 0
      '';
    };

    hooksJson = builtins.toJSON {
      hooks = {
        PreToolUse = [
          {
            matcher = ".*";
            hooks = [
              {
                type = "command";
                command = lib.getExe agentPreGuard;
              }
            ];
          }
        ];
        PostToolUse = [
          {
            matcher = "Edit|Write|edit|write|write_file|edit_file|apply_patch|write_to_file|replace_file_content|multi_replace_file_content";
            hooks = [
              {
                type = "command";
                command = lib.getExe agentPostVerify;
              }
            ];
          }
        ];
      };
    };

    mcpServersJson = builtins.toJSON {
      mcpServers = {
        codebase-memory = {
          command = lib.getExe pkgs.codebase-memory-mcp;
          args = [];
        };
        serena = {
          command = lib.getExe serenaMcp;
          args = [];
        };
      };
    };
  in {
    config = lib.mkIf enabled {
      home.packages = with pkgs; [
        agentPreGuard
        agentPostVerify
        serenaMcp
        codebase-memory-mcp

        ast-grep
        semgrep
        tree-sitter
        universal-ctags

        repomix
        code2prompt

        ripgrep
        fd
        jq
        yq-go
        typos
      ];

      home.file = {
        ".codex/hooks.json".text = hooksJson;
        ".dsh/hooks.json".text = hooksJson;
        ".gemini/config/hooks.json".text = hooksJson;
        ".gemini/config/mcp_config.json".text = mcpServersJson;
      };
    };
  };
}
