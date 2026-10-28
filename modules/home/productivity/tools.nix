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
        set +e
        INPUT=$(cat)
        [[ -z "$INPUT" ]] && exit 0

        TOOL_NAME=$(jq -r '(.tool_name // .toolName // .tool // .toolCall.name // "") | tostring' <<< "$INPUT" 2>/dev/null)
        FILE_PATH=$(jq -r '(.tool_input.file_path // .tool_input.filePath // .tool_input.path // .tool_input.AbsolutePath // .tool_input.FilePath // .toolCall.args.AbsolutePath // .toolCall.args.Path // .toolCall.args.FilePath // .toolCall.args.file_path // .toolCall.args.path // .toolCall.args.TargetFile // "") | tostring' <<< "$INPUT" 2>/dev/null)
        CONTENT=$(jq -r '(.tool_input.content // .tool_input.new_str // .tool_input.new_string // .tool_input.patch // .tool_input.edits // .tool_input.input // (.tool_input | strings) // .toolCall.args.Content // .toolCall.args.Replacement // .toolCall.args.CodeContent // .toolCall.args.ReplacementContent // "") | tostring' <<< "$INPUT" 2>/dev/null)

        # Fallback: extract target file from diff/patch headers for apply_patch (Codex)
        if [[ -z "$FILE_PATH" && -n "$CONTENT" ]]; then
          FILE_PATH=$(grep -E "^(\+\+\+|---|\*\*\*) " <<< "$CONTENT" 2>/dev/null | grep -v "/dev/null" | head -n 1 | awk '{print $2}' | sed -E 's/^[ab]\///')
        fi

        deny() {
          echo "DENIED: $1" >&2
          exit 2
        }

        # Gate 1: Enforce surgical retrieval (block reading full files over 150 lines)
        if [[ "$TOOL_NAME" =~ ^(View|view|Read|read|read_file|view_file)$ ]] && [[ -n "$FILE_PATH" ]]; then
          if [[ ! -f "$FILE_PATH" ]]; then
            CWD=$(jq -r '.cwd // empty' <<< "$INPUT" 2>/dev/null)
            if [[ -n "$CWD" && -f "$CWD/$FILE_PATH" ]]; then
              FILE_PATH="$CWD/$FILE_PATH"
            fi
          fi
          if [[ -f "$FILE_PATH" ]]; then
            LINES=$(wc -l < "$FILE_PATH" 2>/dev/null || echo 0)
            if (( LINES > 150 )); then
              START_RAW=$(jq -r '(.tool_input.view_range[0] // .tool_input.offset // .toolCall.args.StartLine // 1) | tonumber? // 1' <<< "$INPUT" 2>/dev/null)
              START=''${START_RAW:-1}
              END_RAW=$(jq -r '(.tool_input.view_range[1] // .toolCall.args.EndLine // 0) | tonumber? // 0' <<< "$INPUT" 2>/dev/null)
              LIMIT_RAW=$(jq -r '(.tool_input.limit // 0) | tonumber? // 0' <<< "$INPUT" 2>/dev/null)
              if (( END_RAW > 0 )); then
                WINDOW=$(( END_RAW - START + 1 ))
              else
                WINDOW=''${LIMIT_RAW:-0}
              fi
              if (( WINDOW <= 0 || WINDOW > 150 )); then
                deny "$FILE_PATH is $LINES lines. Full-file reads over 150 lines are banned. Use codebase-memory, Serena, or ast-grep first, or pass offset and limit (under 80 lines)."
              fi
            fi
          fi
        fi

        # Gate 2 & 3: Protect linter configs and block suppression directives
        if [[ "$TOOL_NAME" =~ ^(Edit|MultiEdit|Write|edit|write|write_file|edit_file|apply_patch|write_to_file|replace_file_content|multi_replace_file_content)$ ]]; then
          PROTECTED=(
            "*tsconfig*.json"
            "*biome.json"
            "*biome.jsonc"
            "*.eslintrc*"
            "*ruff.toml"
            "*selene.toml"
            "*statix.toml"
          )
          BASE_NAME="$(basename "$FILE_PATH")"
          for cfg in "''${PROTECTED[@]}"; do
            # shellcheck disable=SC2053
            if [[ "$BASE_NAME" == $cfg ]]; then
              deny "Modifying $BASE_NAME is forbidden. Fix the code instead of weakening the linter."
            fi
          done

          CHECK_CONTENT="$CONTENT"
          if grep -qE "(^@@\s|^(---|\+\+\+)\s)" <<< "$CONTENT"; then
            CHECK_CONTENT=$(grep -E "^\+[^+]" <<< "$CONTENT" 2>/dev/null || true)
          fi

          if grep -qE "${"@" + "ts-ignore"}|${"@" + "ts-expect-error"}|${"eslint-" + "disable"}|#\s*type:\s*ignore|--\s*selene:\s*allow|#\s*statix\s*ignore" <<< "$CHECK_CONTENT"; then
            deny "Suppression comments are banned."
          fi
        fi

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
        set +e
        INPUT=$(cat)
        [[ -z "$INPUT" ]] && exit 0

        FILE_PATH=$(jq -r '(.tool_input.file_path // .tool_input.filePath // .tool_input.path // .tool_input.AbsolutePath // .tool_input.FilePath // .toolCall.args.AbsolutePath // .toolCall.args.Path // .toolCall.args.FilePath // .toolCall.args.file_path // .toolCall.args.path // .toolCall.args.TargetFile // "") | tostring' <<< "$INPUT" 2>/dev/null)
        CONTENT=$(jq -r '(.tool_input.content // .tool_input.new_str // .tool_input.new_string // .tool_input.patch // .tool_input.edits // .tool_input.input // (.tool_input | strings) // .toolCall.args.Content // .toolCall.args.Replacement // .toolCall.args.CodeContent // .toolCall.args.ReplacementContent // "") | tostring' <<< "$INPUT" 2>/dev/null)

        # Fallback: extract target file from diff/patch headers for apply_patch (Codex)
        if [[ -z "$FILE_PATH" && -n "$CONTENT" ]]; then
          FILE_PATH=$(grep -E "^(\+\+\+|---|\*\*\*) " <<< "$CONTENT" 2>/dev/null | grep -v "/dev/null" | head -n 1 | awk '{print $2}' | sed -E 's/^[ab]\///')
        fi
        if [[ ! -f "$FILE_PATH" ]]; then
          CWD=$(jq -r '.cwd // empty' <<< "$INPUT" 2>/dev/null)
          if [[ -n "$CWD" && -f "$CWD/$FILE_PATH" ]]; then
            FILE_PATH="$CWD/$FILE_PATH"
          fi
        fi
        [[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]] && exit 0

        fail_verify() {
          echo "VERIFICATION FAILED ($1) in $FILE_PATH:" >&2
          echo "$2" >&2
          exit 2
        }

        case "$FILE_PATH" in
          *.ts|*.tsx|*.js|*.jsx|*.svelte|*.json)
            biome format --write "$FILE_PATH" >/dev/null 2>&1
            OUT=$(biome check "$FILE_PATH" --max-diagnostics=4 2>&1) || fail_verify "Biome" "$(tail -n 12 <<< "$OUT")"
            ;;
          *.nix)
            alejandra --quiet "$FILE_PATH" >/dev/null 2>&1
            OUT=$(nix-instantiate --parse "$FILE_PATH" 2>&1) || fail_verify "Nix Syntax" "$(head -n 8 <<< "$OUT")"
            OUT=$(statix check "$FILE_PATH" 2>&1) || fail_verify "Statix" "$(head -n 10 <<< "$OUT")"
            OUT=$(deadnix --fail "$FILE_PATH" 2>&1) || fail_verify "Deadnix" "$(head -n 10 <<< "$OUT")"
            ;;
          *.py)
            ruff format "$FILE_PATH" >/dev/null 2>&1
            OUT=$(ruff check --output-format=concise "$FILE_PATH" 2>&1) || fail_verify "Ruff" "$(head -n 10 <<< "$OUT")"
            ;;
          *.lua|*.luau)
            stylua "$FILE_PATH" >/dev/null 2>&1
            OUT=$(selene "$FILE_PATH" 2>&1) || fail_verify "Selene" "$(head -n 10 <<< "$OUT")"
            ;;
          *.sh|*.bash)
            shfmt -w "$FILE_PATH" >/dev/null 2>&1
            OUT=$(shellcheck -f gcc "$FILE_PATH" 2>&1) || fail_verify "ShellCheck" "$(head -n 10 <<< "$OUT")"
            ;;
        esac

        exit 0
      '';
    };

    hooksJson = builtins.toJSON {
      hooks = {
        PreToolUse = [
          {
            matcher = "View|view|Read|read|Edit|edit|MultiEdit|Write|write|read_file|view_file|write_file|edit_file|apply_patch|write_to_file|replace_file_content|multi_replace_file_content";
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
            matcher = "Edit|MultiEdit|Write|edit|write|write_file|edit_file|apply_patch|write_to_file|replace_file_content|multi_replace_file_content";
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
