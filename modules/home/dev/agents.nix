{
  flake.homeModules.agents = {
    lib,
    pkgs,
    osConfig ? {},
    ...
  }: let
    enabled = osConfig.var.features.agents or false;

    skillsDir = ./config/instructions/skills;
    rulesDir = ./config/instructions/rules;

    ruleFiles = lib.filterAttrs (
      name: type: type == "regular" && lib.hasSuffix ".md" name
    ) (builtins.readDir rulesDir);

    combinedRules = lib.concatMapStringsSep "\n\n---\n\n" (
      name: builtins.readFile (rulesDir + "/${name}")
    ) (builtins.attrNames ruleFiles);

    updateAiTools = pkgs.writeShellApplication {
      name = "update-ai-tools";
      runtimeInputs = with pkgs; [
        coreutils
        curl
        gnugrep
        gnutar
        gzip
        nodejs
        patchelf
        pnpm
        util-linux
      ];
      text = ''
                export PATH="$HOME/.local/bin:$PATH"
                export PNPM_HOME="$HOME/.local/share/pnpm"
                mkdir -p "$HOME/.local/bin" "$HOME/.cache" "$PNPM_HOME"

                exec 9>"$HOME/.cache/update-ai-tools.lock"
                flock -n 9 || exit 0

                # 1. Codex + seed MCP servers into writable ~/.codex/config.toml
                curl -fsSL https://chatgpt.com/codex/install.sh |
                  CODEX_NON_INTERACTIVE=1 CODEX_INSTALL_DIR="$HOME/.local/bin" sh

                mkdir -p "$HOME/.codex"
                touch "$HOME/.codex/config.toml"
                if ! grep -q "\[mcp_servers.codebase-memory\]" "$HOME/.codex/config.toml"; then
                  cat >> "$HOME/.codex/config.toml" << 'EOF'

        [features]
        hooks = true

        [mcp_servers.codebase-memory]
        command = "codebase-memory-mcp"

        [mcp_servers.serena]
        command = "serena-mcp"
        startup_timeout_sec = 30
        EOF
                fi

                curl -fsSL https://antigravity.google/cli/install.sh |
                  bash -s -- --dir "$HOME/.local/bin"
                patchelf --set-interpreter ${lib.escapeShellArg pkgs.stdenv.cc.bintools.dynamicLinker} \
                  "$HOME/.local/bin/agy"

                pnpm install -g @deepseek-ai/dsh @deepseek-harness-tui/dsh-tui
                for bin in "$PNPM_HOME"/*; do
                  [[ -f "$bin" && -x "$bin" ]] || continue
                  target="$HOME/.local/bin/$(basename "$bin")"
                  # shellcheck disable=SC2016
                  printf '#!/usr/bin/env bash\nexport PATH="%s:$PATH"\nexec "%s" "$@"\n' \
                    "${pkgs.nodejs}/bin" "$bin" > "$target"
                  chmod +x "$target"
                done
      '';
    };
  in {
    config = lib.mkIf enabled {
      home = {
        sessionPath = ["$HOME/.local/bin"];
        packages = [updateAiTools];

        file = {
          ".codex/AGENTS.md".text = combinedRules;
          ".dsh/AGENTS.md".text = combinedRules;
          ".gemini/GEMINI.md".text = combinedRules;

          ".agents/rules" = {
            source = rulesDir;
            recursive = true;
          };
          ".gemini/antigravity-cli/rules" = {
            source = rulesDir;
            recursive = true;
          };

          ".agents/skills" = {
            source = skillsDir;
            recursive = true;
          };
          ".gemini/antigravity-cli/skills" = {
            source = skillsDir;
            recursive = true;
          };
        };

        activation.updateAiTools = lib.hm.dag.entryAfter ["reloadSystemd"] ''
          [[ -n "''${DRY_RUN_CMD:-}" ]] ||
            ${pkgs.systemd}/bin/systemctl --user start --no-block update-ai-tools.service || true
        '';
      };

      systemd.user = {
        services.update-ai-tools = {
          Unit.Description = "Install and update AI CLI tools";
          Service = {
            Type = "oneshot";
            TimeoutStartSec = "5min";
            ExecStart = lib.getExe updateAiTools;
          };
        };

        timers.update-ai-tools = {
          Unit.Description = "Keep AI CLI tools current";
          Timer = {
            OnStartupSec = "1m";
            OnUnitActiveSec = "1h";
            Persistent = true;
          };
          Install.WantedBy = ["timers.target"];
        };
      };
    };
  };
}
