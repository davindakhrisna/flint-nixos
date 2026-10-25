{
  flake.homeModules.agents = {
    lib,
    pkgs,
    osConfig ? {},
    ...
  }: let
    enabled = osConfig.var.features.agents or false;
    skillsDir = ./config/instructions/skills;

    updateAiTools = pkgs.writeShellApplication {
      name = "update-ai-tools";
      runtimeInputs = with pkgs; [
        coreutils
        curl
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

        curl -fsSL https://chatgpt.com/codex/install.sh |
          CODEX_NON_INTERACTIVE=1 CODEX_INSTALL_DIR="$HOME/.local/bin" sh

        curl -fsSL https://antigravity.google/cli/install.sh |
          bash -s -- --dir "$HOME/.local/bin"
        patchelf --set-interpreter ${lib.escapeShellArg pkgs.stdenv.cc.bintools.dynamicLinker} \
          "$HOME/.local/bin/agy"

        pnpm install -g @deepseek-ai/dsh @deepseek-harness-tui/dsh-tui
        for bin in "$PNPM_HOME"/*; do
          [[ -f "$bin" && -x "$bin" ]] || continue
          target="$HOME/.local/bin/$(basename "$bin")"
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
          Unit.Description = "Install and update AI tools";
          Service = {
            Type = "oneshot";
            TimeoutStartSec = "5min";
            ExecStart = lib.getExe updateAiTools;
          };
        };

        timers.update-ai-tools = {
          Unit.Description = "Keep AI tools current";
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
