_: {
  flake.homeModules.dev-medium = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (pkgs.headroom) tiktokenCache;
    headroomExe = lib.getExe pkgs.headroom;
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
    jq = lib.getExe pkgs.jq;

    sharedToolBullets = ''
      - Always use `rtk` for supported noisy commands such as Git history, broad searches, builds, tests, and logs. Use raw commands only when exact output, complete diagnostics, unsupported flags, or security-sensitive evidence require it.
      - Always use Headroom's MCP `headroom_compress` for large, eligible text already in context. Keep its hash and use `headroom_retrieve` when omitted details matter. Skip short text, secrets, and exact source patches. Do not proxy agent traffic, change provider endpoints, or read authentication files for Headroom.'';

    graphifyFallback = "Continue with normal file search if Graphify does not support the language or extraction fails; report that limitation once, without repeatedly retrying in the same session.";

    antigravityGraphifyRule = "- Before codebase exploration, check whether `./graphify-out/graph.json` exists in the current working directory. If it does, use `graphify query \"<question>\"` to locate likely code paths and `graphify update .` after relevant code changes. Verify results against source. If it does not exist, the user has authorized initializing Graphify for this coding session: run `graphify extract . --code-only` once without asking again. This is also part of `/init`. ${graphifyFallback}";

    codexGraphifyRule = "- Before codebase exploration, check whether `./graphify-out/graph.json` exists in the current working directory. If it does, use `graphify query \"<question>\"` to locate likely code paths and `graphify update .` after relevant code changes. Verify results against source. If it does not exist, ask the user whether to initialize Graphify; run `graphify extract . --code-only` only after they agree. Continue with normal file search if they decline. ${graphifyFallback}";
  in {
    config = lib.mkMerge [
      (lib.mkIf (builtins.elem config.dev ["medium" "heavy"]) {
        home = {
          packages = with pkgs; [
            graphify
            rtk
            headroom
          ];

          sessionVariables = {
            HEADROOM_BEACON = "off";
            HEADROOM_TELEMETRY = "off";
            RTK_TELEMETRY_DISABLED = "1";
          };

          file = {
            ".gemini/config/AGENTS.md".text = lib.mkAfter ''
              ## Medium/heavy-profile coding tools

              ${sharedToolBullets}
              ${antigravityGraphifyRule}
              Apply these tool rules to Antigravity CLI as well. Headroom is a local stdio MCP server registered as headroom; call headroom_compress for large eligible text, retain its hash, and call headroom_retrieve when omitted details matter. Never compress secrets or exact source patches. Do not proxy agent traffic, alter provider endpoints, or read authentication files for token optimization.
            '';

            ".codex/AGENTS.md" = {
              force = true;
              text = ''
                # Medium/heavy-profile coding tools

                ${sharedToolBullets}
                ${codexGraphifyRule}
              '';
            };
          };
        };

        programs.dsh.profiles.web = {
          bundles = with pkgs.dsh.bundles; [
            web-app
            pkgs.dsh-agy-safe
            better-sidebar
            at-file
            experimental-tool-worktree
            security-audit
            modlens
          ];
          mode = "managed";
        };
      })

      {
        home.activation = {
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
        };
      }
    ];
  };
}
