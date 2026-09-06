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
            inputs.nvf.homeManagerModules.default
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
            "video"
            "audio"
            "input"
            "adbusers"
          ];
        };

        # Hardware & Flake Path
        var = {
          flakePath = "/home/kryisnn/.config/flint"; # Path to your flint flake repository
          cpu = "intel";
          gpu = "nvidia";
          nvidia.mode = "desktop";
          dualBoot = {
            enable = true;
            windowsEntry = "uuid(XXXX-XXXX):/EFI/Microsoft/Boot/bootmgfw.efi";
          };
        };

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

          # Dev Environment Profile: "off" | "min" | "mid" | "max"
          dev = "max";
        };

        system.stateVersion = "26.05";
      })
    ];
  };
}
