_: {
  flake.nixosModules.options = {
    config,
    lib,
    ...
  }: {
    options.var = {
      flakePath = lib.mkOption {
        type = lib.types.str;
        default = "/etc/nixos";
        description = "Path to the NixOS configuration flake directory";
      };

      dualBoot = {
        enable = lib.mkEnableOption "Windows dual-boot support";
        windowsEntry = lib.mkOption {
          type = lib.types.str;
          default = "boot():/EFI/Microsoft/Boot/bootmgfw.efi";
          description = "Path or UUID to the Windows EFI bootloader in Limine format";
        };
      };

      features = {
        desktop = lib.mkEnableOption "the UWSM-managed Hyprland Wayland workstation";
        audio = lib.mkEnableOption "PipeWire audio";
        bluetooth = lib.mkEnableOption "Bluetooth support";
        removableStorage = lib.mkEnableOption "UDisks removable-storage support";
        tailscale = lib.mkEnableOption "Tailscale networking";
        ollama = lib.mkEnableOption "the Ollama model server";
        docker = lib.mkEnableOption "Docker containers";
        waydroid = lib.mkEnableOption "Waydroid Android containers";
        gaming = lib.mkEnableOption "Steam and system gaming support";
        steamRemotePlay = lib.mkEnableOption "Steam Remote Play firewall ports";
        steamDedicatedServer = lib.mkEnableOption "Steam dedicated-server firewall ports";
        steamLocalTransfers = lib.mkEnableOption "Steam local-transfer firewall ports";
        developerKernelAccess = lib.mkEnableOption "debugging and performance profiling";
      };
    };

    config.assertions = [
      {
        assertion = !config.var.features.steamRemotePlay || config.var.features.gaming;
        message = "var.features.steamRemotePlay requires var.features.gaming.";
      }
      {
        assertion = !config.var.features.steamDedicatedServer || config.var.features.gaming;
        message = "var.features.steamDedicatedServer requires var.features.gaming.";
      }
      {
        assertion = !config.var.features.steamLocalTransfers || config.var.features.gaming;
        message = "var.features.steamLocalTransfers requires var.features.gaming.";
      }
      {
        assertion = !config.var.features.waydroid || config.var.features.desktop;
        message = "var.features.waydroid requires var.features.desktop.";
      }
      {
        assertion = !config.var.features.bluetooth || config.var.features.desktop;
        message = "var.features.bluetooth requires var.features.desktop.";
      }
      {
        assertion = !config.var.features.removableStorage || config.var.features.desktop;
        message = "var.features.removableStorage requires var.features.desktop.";
      }
    ];
  };
}
