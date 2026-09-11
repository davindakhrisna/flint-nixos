{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.powerhouse = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit inputs self;};
    modules = [
      ./_hardware.nix
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = {inherit inputs self;};
          backupFileExtension = "backup";
          sharedModules = [
            inputs.nix-flatpak.homeManagerModules.nix-flatpak
            inputs.nixvim.homeModules.default
          ];
        };
      }

      # System modules
      self.nixosModules.system

      # Host-specific Configuration
      ({pkgs, ...}: {
        networking.hostName = "powerhouse";
        time.timeZone = "Asia/Jakarta";
        i18n.defaultLocale = "en_US.UTF-8";

        # User Account (System-level)
        users.users.kryisnn = {
          isNormalUser = true;
          shell = pkgs.zsh;
          extraGroups = [
            "seat"
            "wheel"
            "networkmanager"
            "docker"
            "adbusers"
          ];
        };

        # Hardware & Flake Path
        var = {
          flakePath = "/home/kryisnn/.config/flint"; # Path to your flint flake repository
          cpu = "intel";
          gpu = "nvidia";
          nvidia = {
            open = true;
            mode = "desktop";
            intelBusId = "PCI:0:2:0";
            nvidiaBusId = "PCI:1:0:0";
          };
          dualBoot = {
            enable = true;
            windowsEntry = "uuid(0694-C779):/EFI/Microsoft/Boot/bootmgfw.efi";
          };
          features = {
            desktop = true;
            audio = true;
            bluetooth = true;
            removableStorage = true;
            tailscale = true;
            ollama = true;
            docker = true;
            waydroid = true;
            gaming = true;
            steamLocalTransfers = true;
            developerKernelAccess = true;
          };
        };

        # Prefer the Intel iGPU for Hyprland while keeping the Nvidia GPU
        # available for render offload and outputs wired to it.
        # Aquamarine uses ':' as the device-list separator, so PCI by-path
        # names (which contain ':') cannot be used here.  Keep the integrated
        # Intel GPU primary and the NVIDIA GPU secondary for hybrid rendering.
        environment.sessionVariables.AQ_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card0";

        # User Configuration (Home Manager level)
        home-manager.users.kryisnn = {...}: {
          imports = with self.homeModules; [
            home-manager
            desktop
            shell
            productivity
            dev
            entertainment-social
            entertainment-gaming
          ];

          # Dev Environment Profile: "minimal" | "full"
          dev = "full";
        };

        system.stateVersion = "26.05";
      })
    ];
  };
}
