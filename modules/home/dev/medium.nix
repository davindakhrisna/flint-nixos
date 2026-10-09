_: {
  flake.homeModules.dev-medium = {
    config,
    lib,
    pkgs,
    ...
  }: let
    installFullTools = pkgs.writeShellApplication {
      name = "flint-install-medium-tools";
      runtimeInputs = with pkgs; [nodejs];
      text = ''
        mkdir -p "$HOME/.local/bin"
        if [[ ! -x "$HOME/.local/bin/9router" ]]; then
          npm install --global --prefix "$HOME/.local" 9router
        fi
      '';
    };
    headroom = pkgs.callPackage ../../system/packages/_headroom.nix {};
    # Byte-identical mirror of the vocabulary hash pinned by OpenAI's tiktoken.
    tiktokenO200k = pkgs.fetchurl {
      url = "https://huggingface.co/baseten/o200k-base-tiktoken/resolve/64365eed65a7d76989528cb3f3571b423518ab57/o200k_base.tiktoken";
      hash = "sha256-RGqVOMtsNI41FhINfAiwn1fDZJXirP/+WaW/iwz7Gi0=";
    };
    tiktokenCache = pkgs.runCommandLocal "tiktoken-o200k-base-cache" {} ''
      mkdir -p "$out"
      ln -s ${tiktokenO200k} "$out/fb374d419588a4632f3f557e76b4b70aebbca790"
    '';

    headroomExe = lib.getExe headroom;
    jq = lib.getExe pkgs.jq;
    headroomServer = {
      command = headroomExe;
      args = ["mcp" "serve"];
      env = {
        HEADROOM_BEACON = "off";
        HEADROOM_MCP_CHECK_PROXY = "0";
        HEADROOM_TELEMETRY = "off";
        TIKTOKEN_CACHE_DIR = "${tiktokenCache}";
      };
    };
    manageJsonHeadroom = pkgs.writeShellApplication {
      name = "flint-manage-headroom-mcp";
      runtimeInputs = [pkgs.coreutils pkgs.diffutils pkgs.jq];
      text = builtins.readFile ./config/headroom-mcp.sh;
    };
    toolRules = initialize: ''
      # Medium/heavy-profile coding tools

      - Always use `rtk` for supported noisy commands such as Git history, broad searches, builds, tests, and logs. Use raw commands only when exact output, complete diagnostics, unsupported flags, or security-sensitive evidence require it.
      - Always use Headroom's MCP `headroom_compress` for large, eligible text already in context. Keep its hash and use `headroom_retrieve` when omitted details matter. Skip short text, secrets, and exact source patches. Do not proxy agent traffic, change provider endpoints, or read authentication files for Headroom.
      - Before codebase exploration, check whether `./graphify-out/graph.json` exists in the current working directory. If it does, use `graphify query "<question>"` to locate likely code paths and `graphify update .` after relevant code changes. Verify results against source. ${initialize} Continue with normal file search if Graphify does not support the language or extraction fails; report that limitation once, without repeatedly retrying in the same session.
      - 9Router is an optional local CLI. Do not redirect any harness through it unless the user explicitly requests a provider configuration compliant with that provider's terms.
    '';
  in {
    config = {
      home = {
        packages = lib.mkIf (builtins.elem config.dev ["medium" "heavy"]) (with pkgs; [
          graphify
          nodejs
          installFullTools
          pkgs.rtk
          headroom
        ]);

        sessionVariables = lib.mkIf (builtins.elem config.dev ["medium" "heavy"]) {
          HEADROOM_BEACON = "off";
          HEADROOM_TELEMETRY = "off";
          RTK_TELEMETRY_DISABLED = "1";
        };

        file = {
          ".gemini/config/skills/token-optimizer" = lib.mkIf (builtins.elem config.dev ["medium" "heavy"]) {
            source = ./config/token-optimizer;
            recursive = true;
          };

          ".gemini/config/AGENTS.md" = lib.mkIf (builtins.elem config.dev ["medium" "heavy"]) {
            text = ''
              # Codex-style engineering workflow

              Act as a practical, candid engineering partner. Treat requests to fix or build something as instructions to complete the work. Inspect the source, make the smallest correct change, run meaningful checks, and report the result and any remaining limitations honestly. Continue until the task is complete or genuinely blocked. Never claim a tool ran or a check passed without evidence.

              Read the project's AGENTS.md and follow the user's current instructions. Proceed with authorized, reversible work without repeated confirmation. Ask only for missing information that affects correctness or for actions outside the authorized scope. Preserve unrelated user changes. Do not commit, push, switch systems, or publish unless requested.

              Give concise progress updates during sustained work. Explain what changed and how it was checked in plain language, with file paths when useful. Use available terminal, file, browser, and MCP tools directly; report missing capabilities instead of inventing tool calls.

              For substantial tasks, keep a short plan and carry it through implementation and verification. Treat follow-up messages as steering the current task unless the user changes the goal. Ask focused questions only when the answer changes correctness; continue independent work while waiting. Do not stop after proposing a fix when implementation is requested.

              Prefer rg for source discovery and inspect relevant callers before changing behavior. Batch independent reads when supported, but keep dependent edits and checks sequential. Use the project's existing validation commands, investigate failures, and distinguish existing failures from regressions. Do not broaden the task with unrelated refactors or dependencies. Use subagents only when requested or when an applicable project instruction or skill requires them.

              ## Provisioned skills

              Discover CLI skills in ~/.gemini/antigravity-cli/skills (shared with ~/.gemini/config/skills) and project .agents/skills directories. Read the relevant SKILL.md before applying it and follow its referenced resources. Before each task, match the request against installed skill descriptions and automatically read the relevant skills without waiting for a slash command. Always honor explicitly named skills. Announce the selected skills briefly; do not load unrelated skills or every skill body. Use ponytail for every coding change, fix, refactor, review, or coding design decision, frontend-design and impeccable for UI work, and codebase-design for module design. Use improve-codebase-architecture and thermo-nuclear-code-quality-review when their scope matches the request, and study for Obsidian study sessions. Use Antigravity's built-in /grill-me for that workflow. User instructions take precedence over skill guidance.

              ## Medium/heavy-profile coding tools

              ${toolRules "If it does not exist, the user has authorized initializing Graphify for this coding session: run `graphify extract . --code-only` once without asking again. This is also part of `/init`."}

              Apply these tool rules to Antigravity CLI as well. Headroom is a local stdio MCP server registered as headroom; call headroom_compress for large eligible text, retain its hash, and call headroom_retrieve when omitted details matter. Never compress secrets or exact source patches. Do not proxy agent traffic, alter provider endpoints, or read authentication files for token optimization. Do not route Antigravity through 9Router unless explicitly requested.
            '';
          };

          ".codex/skills/token-optimizer" = lib.mkIf (builtins.elem config.dev ["medium" "heavy"]) {
            source = ./config/token-optimizer;
            recursive = true;
          };

          ".codex/AGENTS.md" = lib.mkIf (builtins.elem config.dev ["medium" "heavy"]) {
            text = toolRules "If it does not exist, ask the user whether to initialize Graphify; run `graphify extract . --code-only` only after they agree. Continue with normal file search if they decline.";
          };

          ".omp/agent/skills/token-optimizer" = lib.mkIf (builtins.elem config.dev ["medium" "heavy"]) {
            source = ./config/token-optimizer;
            recursive = true;
          };

          ".omp/agent/RULES.md" = lib.mkIf (builtins.elem config.dev ["medium" "heavy"]) {
            text =
              config.home.file.".codex/AGENTS.md".text
              + ''

                Select relevant installed skills automatically from their descriptions.
                Read SKILL.md before applying a skill and briefly announce it. Use
                ponytail for coding work. Headroom is registered in OMP's native
                mcp.json; use its compression, retrieval, and stats tools directly.
              '';
          };
        };

        activation = {
          manageAntigravityHeadroomMcp = lib.hm.dag.entryAfter ["writeBoundary"] ''
            $DRY_RUN_CMD ${lib.getExe manageJsonHeadroom} ${
              if config.dev == "light"
              then "disable"
              else "enable"
            } \
              "$HOME/.gemini/config/mcp_config.json" \
              "$HOME/.local/state/flint/antigravity-headroom-mcp-command" \
              ${lib.escapeShellArg (builtins.toJSON headroomServer)}
          '';

          manageOmpHeadroomMcp = lib.hm.dag.entryAfter ["writeBoundary"] ''
            $DRY_RUN_CMD ${lib.getExe manageJsonHeadroom} ${
              if config.dev == "light"
              then "disable"
              else "enable"
            } \
              "$HOME/.omp/agent/mcp.json" \
              "$HOME/.local/state/flint/omp-headroom-mcp-command" \
              ${lib.escapeShellArg (builtins.toJSON (headroomServer // {type = "stdio";}))}
          '';

          installFullTools = lib.hm.dag.entryAfter ["writeBoundary"] ''
            if [[ ${lib.escapeShellArg config.dev} != light && -z "''${DRY_RUN_CMD:-}" ]]; then
              ${pkgs.coreutils}/bin/timeout 300 ${lib.getExe installFullTools} ||
                echo "Warning: 9Router installation failed; run flint-install-medium-tools to retry." >&2
            fi
          '';

          manageHeadroomMcp = lib.hm.dag.entryAfter ["updateAiTools"] ''
            state_dir="$HOME/.local/state/flint"
            state_file="$state_dir/headroom-mcp-command"
            codex="$HOME/.local/bin/codex"

            current_headroom() {
              [[ -x "$codex" ]] && "$codex" mcp get headroom --json 2>/dev/null || true
            }

            matches_managed_headroom() {
              ${jq} -e --arg command "$1" \
                '.transport.command == $command
                  and .transport.args == ["mcp", "serve"]' \
                >/dev/null 2>&1
            }

            matches_current_headroom() {
              ${jq} -e \
                --arg command ${lib.escapeShellArg headroomExe} \
                --arg cache ${lib.escapeShellArg "${tiktokenCache}"} \
                '.transport.command == $command
                  and .transport.args == ["mcp", "serve"]
                  and .transport.env.TIKTOKEN_CACHE_DIR == $cache
                  and .transport.env.HEADROOM_BEACON == "off"
                  and .transport.env.HEADROOM_MCP_CHECK_PROXY == "0"
                  and .transport.env.HEADROOM_TELEMETRY == "off"' \
                >/dev/null 2>&1
            }

            if [[ ${lib.escapeShellArg config.dev} != light ]]; then
              if [[ ! -x "$codex" ]]; then
                echo "Warning: Codex is not installed yet; skipping Headroom MCP registration." >&2
              else
                current="$(current_headroom)"
                if ! printf '%s' "$current" | matches_current_headroom; then
                  if [[ -n "$current" ]]; then
                    $DRY_RUN_CMD "$codex" mcp remove headroom
                  fi
                  $DRY_RUN_CMD "$codex" mcp add \
                    --env HEADROOM_BEACON=off \
                    --env HEADROOM_MCP_CHECK_PROXY=0 \
                    --env HEADROOM_TELEMETRY=off \
                    --env TIKTOKEN_CACHE_DIR=${tiktokenCache} \
                    headroom -- ${headroomExe} mcp serve
                fi
                $DRY_RUN_CMD mkdir -p "$state_dir"
                if [[ -z "''${DRY_RUN_CMD:-}" ]]; then
                  printf '%s\n' ${lib.escapeShellArg headroomExe} > "$state_file"
                fi
              fi
            elif [[ -f "$state_file" ]]; then
              managed_command="$(<"$state_file")"
              current="$(current_headroom)"
              if printf '%s' "$current" | matches_managed_headroom "$managed_command"; then
                $DRY_RUN_CMD "$codex" mcp remove headroom
              fi
              $DRY_RUN_CMD rm -f "$state_file"
            fi
          '';

          removeSerena = lib.hm.dag.entryAfter ["updateAiTools"] ''
            codex="$HOME/.local/bin/codex"
            if [[ -x "$codex" ]] && "$codex" mcp get serena --json >/dev/null 2>&1; then
              $DRY_RUN_CMD "$codex" mcp remove serena
            fi
            if [[ -x "$HOME/.local/bin/serena" ]]; then
              $DRY_RUN_CMD ${lib.getExe pkgs.uv} tool uninstall serena-agent
            fi
            $DRY_RUN_CMD rm -f "$HOME/.local/state/flint/serena-mcp-command"
          '';
        };
      };
    };
  };
}
