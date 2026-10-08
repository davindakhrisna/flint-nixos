_: {
  flake.homeModules.dev-light = {
    config,
    lib,
    pkgs,
    osConfig ? {},
    ...
  }: let
    updateAiTools = pkgs.writeShellApplication {
      name = "flint-update-ai-tools";
      runtimeInputs = with pkgs; [
        coreutils
        curl
        findutils
        gawk
        gnugrep
        gnused
        gnutar
        gzip
        patchelf
        procps
        util-linux
      ];
      text = ''
        interpreter=${lib.escapeShellArg pkgs.stdenv.cc.bintools.dynamicLinker}
        export PATH="$HOME/.local/bin:$PATH"
        mkdir -p "$HOME/.local/bin"
        # Activation and the timer share installers with fixed staging paths.
        mkdir -p "$HOME/.cache/flint"
        exec 9>"$HOME/.cache/flint/update-ai-tools.lock"
        flock 9
        status=0

        patch_for_nixos() {
          local binary="$1"
          local current
          local replacement

          current="$(patchelf --print-interpreter "$binary" 2>/dev/null || true)"
          [[ "$current" == "$interpreter" ]] && return 0

          replacement="$(mktemp "$HOME/.local/bin/.$(basename "$binary").XXXXXX")"
          if cp --reflink=auto "$binary" "$replacement" &&
            chmod +x "$replacement" &&
            patchelf --set-interpreter "$interpreter" "$replacement" &&
            mv -f "$replacement" "$binary"; then
            return 0
          fi

          rm -f "$replacement"
          return 1
        }

        (curl -fsSL https://chatgpt.com/codex/install.sh |
          CODEX_NON_INTERACTIVE=1 CODEX_INSTALL_DIR="$HOME/.local/bin" sh) || status=1

        (curl -fsSL https://omp.sh/install |
          PI_INSTALL_DIR="$HOME/.local/bin" sh -s -- --binary) || true
        if [[ -x "$HOME/.local/bin/omp" ]]; then
          patch_for_nixos "$HOME/.local/bin/omp" || status=1
          "$HOME/.local/bin/omp" --version >/dev/null || status=1
        else
          status=1
        fi

        agy_stage="$(mktemp -d "$HOME/.local/bin/.agy-update.XXXXXX")"
        if (curl -fsSL https://antigravity.google/cli/install.sh |
          bash -s -- --dir "$agy_stage") &&
          [[ -x "$agy_stage/agy" ]] &&
          patch_for_nixos "$agy_stage/agy" &&
          "$agy_stage/agy" --version >/dev/null; then
          mv -f "$agy_stage/agy" "$HOME/.local/bin/agy"
        else
          status=1
        fi
        rm -f "$agy_stage/agy"
        rmdir "$agy_stage" 2>/dev/null || true

        exit "$status"
      '';
    };
  in {
    imports = [
      ./config/_lazyvim.nix
      ./config/_mkenv.nix
      ./config/_skills.nix
      ./config/_study.nix
    ];

    config = lib.mkIf (builtins.elem config.dev ["light" "medium" "heavy"]) {
      programs = {
        # Keep terminal sessions local so Ctrl+C does not leave a shared daemon.
        zsh.shellAliases.codex = "codex --disable daemon_auto_start";

        git = {
          enable = true;
          settings = {
            user = {
              name = "davindakhrisna";
              email = "arpeggio.gns@gmail.com";
            };
            init.defaultBranch = "main";
            safe.directory = [
              (osConfig.var.flakePath or "${config.home.homeDirectory}/.config/flint")
            ];
          };
        };

        gh = {
          enable = true;
          gitCredentialHelper.enable = true;
        };

        direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
      };

      home = {
        sessionPath = [
          "$HOME/.local/bin"
          "${config.home.profileDirectory}/bin"
        ];

        packages = with pkgs; [
          lazygit
          bubblewrap
          jq
          lazydocker
          updateAiTools
        ];

        activation.updateAiTools = lib.hm.dag.entryAfter ["writeBoundary"] ''
          if [[ -z "''${DRY_RUN_CMD:-}" ]]; then
            ${pkgs.systemd}/bin/systemctl --user start --no-block flint-update-ai-tools.service ||
              echo "Warning: AI CLI update could not start; the user timer will retry." >&2
          fi
        '';
      };

      systemd.user = {
        services.flint-update-ai-tools = {
          Unit.Description = "Update Codex, OhMyPi, and Antigravity CLI";
          Service = {
            Type = "oneshot";
            TimeoutStartSec = "5min";
            ExecStart = lib.getExe updateAiTools;
          };
        };

        timers.flint-update-ai-tools = {
          Unit.Description = "Keep AI CLI tools current";
          Timer = {
            OnStartupSec = "1m";
            OnUnitActiveSec = "1h";
            Persistent = true;
            Unit = "flint-update-ai-tools.service";
          };
          Install.WantedBy = ["timers.target"];
        };
      };
    };
  };
}
