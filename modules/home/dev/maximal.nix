_: {
  flake.homeModules.dev-maximal = {
    config,
    lib,
    pkgs,
    ...
  }: let
    installFullTools = pkgs.writeShellApplication {
      name = "flint-install-maximal-tools";
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
  in {
    config = {
      home = {
        packages = lib.mkIf (config.dev == "maximal") (with pkgs; [
          godot_4
          blender
          libresprite
          winboat
          graphify
          nodejs
          installFullTools
          pkgs.rtk
          headroom
        ]);

        sessionVariables = lib.mkIf (config.dev == "maximal") {
          HEADROOM_BEACON = "off";
          HEADROOM_TELEMETRY = "off";
          RTK_TELEMETRY_DISABLED = "1";
        };

        file.".codex/skills/token-optimizer" = lib.mkIf (config.dev == "maximal") {
          source = ./config/token-optimizer;
          recursive = true;
        };

        file.".codex/AGENTS.md" = lib.mkIf (config.dev == "maximal") {
          text = ''
            # Maximal-profile coding tools

            - Always use `rtk` for supported noisy commands such as Git history, broad searches, builds, tests, and logs. Use raw commands only when exact output, complete diagnostics, unsupported flags, or security-sensitive evidence require it.
            - Always use Headroom's MCP `headroom_compress` for large, eligible text already in context. Keep its hash and use `headroom_retrieve` when omitted details matter. Skip short text, secrets, and exact source patches. Do not proxy Codex traffic, change its OpenAI endpoint, or read its authentication files for Headroom.
            - Before codebase exploration, check whether `./graphify-out/graph.json` exists in the current working directory. If it does, use `graphify query "<question>"` to locate likely code paths and `graphify update .` after relevant code changes. Verify results against source. If it does not exist, ask the user whether to initialize Graphify; run `graphify extract . --code-only` only after they agree. Continue with normal file search if they decline or Graphify does not support the language.
            - 9Router is an optional local CLI. Do not redirect Codex or Oh My Pi through it unless the user explicitly requests a provider configuration compliant with that provider's terms.
          '';
        };

        file.".omp/agent/RULES.md" = lib.mkIf (config.dev == "maximal") {
          text = ''
            # Graphify

            Before codebase exploration, check for `./graphify-out/graph.json` in the current working directory. If it exists, use `graphify query "<question>"` to locate likely code paths and `graphify update .` after relevant code changes. Verify results against source. If it does not exist, ask the user whether to initialize Graphify; run `graphify extract . --code-only` only after they agree. Use normal file search if they decline or Graphify does not support the language.
          '';
        };

        activation.installFullTools = lib.hm.dag.entryAfter ["writeBoundary"] ''
          if [[ ${lib.escapeShellArg config.dev} == maximal && -z "''${DRY_RUN_CMD:-}" ]]; then
            ${pkgs.coreutils}/bin/timeout 300 ${lib.getExe installFullTools} ||
              echo "Warning: 9Router installation failed; run flint-install-maximal-tools to retry." >&2
          fi
        '';

        activation.manageHeadroomMcp = lib.hm.dag.entryAfter ["updateAiTools"] ''
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

          if [[ ${lib.escapeShellArg config.dev} == maximal ]]; then
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

        activation.removeSerena = lib.hm.dag.entryAfter ["updateAiTools"] ''
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
}
