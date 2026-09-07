{
  flake.nixosModules.hardware = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.var;
  in {
    options.var = {
      cpu = lib.mkOption {
        type = lib.types.nullOr (lib.types.enum ["intel" "amd"]);
        default = null;
        description = "CPU type: intel or amd";
      };

      gpu = lib.mkOption {
        type = lib.types.nullOr (lib.types.enum ["nvidia" "amd" "intel"]);
        default = null;
        description = "GPU type: nvidia, amd, or intel";
      };

      nvidia = {
        mode = lib.mkOption {
          type = lib.types.enum ["desktop" "offload" "sync"];
          default = "desktop";
          description = "Nvidia mode: desktop (dedicated GPU) or offload/sync (hybrid laptop PRIME)";
        };
        intelBusId = lib.mkOption {
          type = lib.types.str;
          default = "PCI:0:2:0";
          description = "Intel iGPU PCI Bus ID for PRIME";
        };
        nvidiaBusId = lib.mkOption {
          type = lib.types.str;
          default = "PCI:1:0:0";
          description = "Nvidia GPU PCI Bus ID for PRIME";
        };
      };
    };

    config = lib.mkMerge [
      # CPU: Intel
      (lib.mkIf (cfg.cpu == "intel") {
        hardware.cpu.intel.updateMicrocode = true;
        services.thermald.enable = true;
      })

      # CPU: AMD
      (lib.mkIf (cfg.cpu == "amd") {
        hardware.cpu.amd.updateMicrocode = true;
      })

      # GPU: Nvidia
      (lib.mkIf (cfg.gpu == "nvidia") {
        services.xserver.videoDrivers = ["nvidia"];
        hardware.graphics = {
          enable = true;
          extraPackages = with pkgs; [
            nvidia-vaapi-driver
          ];
        };
        hardware.nvidia = {
          open = false;
          modesetting.enable = true;
          package = config.boot.kernelPackages.nvidiaPackages.stable;
          powerManagement.enable = true;
          powerManagement.finegrained = cfg.nvidia.mode == "offload";
          nvidiaPersistenced = true;

          prime = lib.mkIf (cfg.nvidia.mode != "desktop") {
            offload = {
              enable = cfg.nvidia.mode == "offload";
              enableOffloadCmd = cfg.nvidia.mode == "offload";
            };
            sync.enable = cfg.nvidia.mode == "sync";
            inherit (cfg.nvidia) intelBusId nvidiaBusId;
          };
        };
        environment.sessionVariables = {
          LIBVA_DRIVER_NAME = "nvidia";
          GBM_BACKEND = "nvidia-drm";
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
          NVD_BACKEND = "direct";
        };

        systemd.services.nvidia-sync-clocks = lib.mkIf (cfg.nvidia.mode == "sync") {
          description = "NVIDIA Sync Mode Minimum GPU Clock Lock for 144Hz Stutter Prevention";
          after = ["nvidia-persistenced.service"];
          requires = ["nvidia-persistenced.service"];
          wantedBy = ["multi-user.target"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "nvidia-sync-clock-tune" ''
              NVSMI="${config.hardware.nvidia.package.bin}/bin/nvidia-smi"
              if [ "$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/A*/online 2>/dev/null | ${pkgs.coreutils}/bin/head -n 1)" = "1" ]; then
                $NVSMI -lgc 1200,2100 || true
              else
                $NVSMI -rgc || true
              fi
            '';
            ExecStop = "${config.hardware.nvidia.package.bin}/bin/nvidia-smi -rgc";
          };
        };

        services.udev.extraRules = lib.mkIf (cfg.nvidia.mode == "sync") ''
          SUBSYSTEM=="power_supply", ACTION=="change", RUN+="${pkgs.systemd}/bin/systemctl restart --no-block nvidia-sync-clocks.service"
        '';
      })

      # GPU: AMD
      (lib.mkIf (cfg.gpu == "amd") {
        services.xserver.videoDrivers = ["amdgpu"];
        hardware.graphics = {
          enable = true;
          extraPackages = with pkgs; [
            vaapiVdpau
            libvdpau-va-gl
          ];
        };
      })
    ];
  };
}
