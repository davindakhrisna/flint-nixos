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
            inputs.nixvim.homeModules.default
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
            "adbusers"
          ];
        };

        # Hardware & Flake Path
        var = {
          # CHANGEME (your hardware specs & flake path)
          flakePath = "/etc/nixos"; # CHANGEME: Path to your flake repository
          # Set cpu/gpu after inspecting the target hardware. Nvidia hosts must
          # also choose nvidia.open and explicit PRIME bus IDs when applicable.
          dualBoot.enable = false; # Set to true if dual-booting with Windows
          # Opt in to tailscale, ollama, docker, waydroid, or gaming under
          # var.features as needed.
          features = {
            desktop = true;
            audio = true;
            removableStorage = true;
          };
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

          # Dev Environment Profile: "minimal" | "full"
          dev = "minimal"; # CHANGEME
        };

        system.stateVersion = "26.05";
      })
    ];
  };
}
