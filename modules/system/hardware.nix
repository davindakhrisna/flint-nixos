{
  flake.nixosModules.hardware = {
    config,
    lib,
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
        open = lib.mkOption {
          type = lib.types.nullOr lib.types.bool;
          default = null;
          description = "Use Nvidia's open kernel modules; recommended for Turing and newer GPUs";
        };
        mode = lib.mkOption {
          type = lib.types.enum ["desktop" "offload"];
          default = "desktop";
          description = "Nvidia mode for Hyprland Wayland: dedicated desktop GPU or hybrid PRIME offload";
        };
        igpu = lib.mkOption {
          type = lib.types.enum ["intel" "amd"];
          default = "intel";
          description = "Integrated GPU vendor used with Nvidia PRIME offload";
        };
        intelBusId = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Intel iGPU PCI Bus ID for PRIME";
        };
        nvidiaBusId = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Nvidia GPU PCI Bus ID for PRIME";
        };
        amdgpuBusId = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "AMD integrated GPU PCI Bus ID for PRIME";
        };
      };
    };

    config = lib.mkMerge [
      {
        assertions = [
          {
            assertion = cfg.gpu != "nvidia" || cfg.nvidia.open != null;
            message = "Set var.nvidia.open explicitly when var.gpu is nvidia (true for Turing and newer; false for older GPUs).";
          }
          {
            assertion =
              cfg.gpu
              != "nvidia"
              || cfg.nvidia.mode == "desktop"
              || (
                cfg.nvidia.nvidiaBusId
                != ""
                && (
                  (cfg.nvidia.igpu == "intel" && cfg.nvidia.intelBusId != "")
                  || (cfg.nvidia.igpu == "amd" && cfg.nvidia.amdgpuBusId != "")
                )
              );
            message = "Nvidia offload requires explicit dGPU and matching Intel/AMD iGPU PRIME bus IDs.";
          }
        ];
      }

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
        services.xserver.videoDrivers =
          lib.optionals (cfg.nvidia.mode == "offload") [
            (
              if cfg.nvidia.igpu == "intel"
              then "modesetting"
              else "amdgpu"
            )
          ]
          ++ ["nvidia"];
        hardware.graphics.enable = true;
        hardware.nvidia = {
          open = cfg.nvidia.open;
          modesetting.enable = true;
          package = config.boot.kernelPackages.nvidiaPackages.stable;
          powerManagement.enable = true;
          powerManagement.finegrained = cfg.nvidia.mode == "offload";
          nvidiaPersistenced = cfg.nvidia.mode != "offload";
          videoAcceleration = true;

          prime = lib.mkIf (cfg.nvidia.mode != "desktop") {
            offload = {
              enable = cfg.nvidia.mode == "offload";
              enableOffloadCmd = cfg.nvidia.mode == "offload";
            };
            inherit (cfg.nvidia) nvidiaBusId;
            intelBusId = lib.optionalString (cfg.nvidia.igpu == "intel") cfg.nvidia.intelBusId;
            amdgpuBusId = lib.optionalString (cfg.nvidia.igpu == "amd") cfg.nvidia.amdgpuBusId;
          };
        };
        # Preserve VRAM across suspend without consuming tmpfs-backed /tmp.
        boot.kernelParams = ["nvidia.NVreg_TemporaryFilePath=/var/tmp"];
      })

      # GPU: AMD
      (lib.mkIf (cfg.gpu == "amd") {
        services.xserver.videoDrivers = ["amdgpu"];
        hardware.graphics.enable = true;
      })

      # GPU: Intel (Mesa is provided by hardware.graphics).
      (lib.mkIf (cfg.gpu == "intel") {
        hardware.graphics.enable = true;
      })
    ];
  };
}
