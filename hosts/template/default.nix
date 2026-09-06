{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.template = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit inputs self;};
    modules = [
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
      ./_hardware.nix

      # System modules
      self.nixosModules.system

      # Host-specific Configuration
      ({pkgs, ...}: {
        # CHANGEME
        networking.hostName = "template"; # CHANGEME: Hostname
        time.timeZone = "Asia/Jakarta"; # CHANGEME: Timezone
        i18n.defaultLocale = "en_US.UTF-8";

        # User Account (System-level)
        users.users.yourusername = {
          # CHANGEME: Username
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
          # CHANGEME (your hardware specs & flake path)
          flakePath = "/etc/nixos"; # CHANGEME: Path to your flake repository
          cpu = "intel";
          gpu = "nvidia";
          nvidia.mode = "desktop"; # ["desktop" "offload" "sync"] -- or just comment it if you dont use nvidia
          dualBoot.enable = false; # Set to true if dual-booting with Windows
        };

        # User Configuration (Home Manager level)
        home-manager.users.yourusername = {...}: {
          # CHANGEME (to your liking)
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
          dev = "mid"; # CHANGEME
        };

        system.stateVersion = "26.05";
      })
    ];
  };
}
