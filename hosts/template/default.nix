{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.template = inputs.nixpkgs.lib.nixosSystem {
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
          ];
        };
      }

      # System modules
      self.nixosModules.system

      # Host-specific Configuration
      ({pkgs, ...}: {
        networking.hostName = "template"; # CHANGEME: Hostname
        time.timeZone = "Asia/Jakarta"; # CHANGEME: Timezone
        i18n.defaultLocale = "en_US.UTF-8";

        # User Account (System-level)
        users.users.yourusername = { # CHANGEME: Username
          isNormalUser = true;
          shell = pkgs.zsh;
          extraGroups = [
            "seat"
            "wheel"
            "networkmanager"
            "docker"
            "adbusers"
            "libvirtd"
          ];
        };

        # Hardware & Flake Path
        var = {
          flakePath = "/etc/nixos"; # CHANGEME: Path to your flake repository
          # CHANGEME: your hardware specs
          cpu = "intel"; # intel/amd/null
          gpu = "amd";   # nvidia/amd/intel/null

          # nvidia = {
          #   open = true;
          #   mode = "desktop";
          #   intelBusId = "PCI:0:2:0";
          #   nvidiaBusId = "PCI:1:0:0";
          # };
          # dualBoot = {
          #   enable = true;
          #   windowsEntry = "uuid(dc68ee6b-9b35-49c8-b40f-3995d7f44547):/EFI/Microsoft/Boot/bootmgfw.efi";
          # };

          # CHANGEME: Opt features as needed, see options.nix for various options to be enabled
          features = {
            # Desktop
            desktop = true;
            developerKernelAccess = true;
            audio = true;
            bluetooth = true;
            removableStorage = true;

            # Mesh VPN
            tailscale = true;

            # AI
            ollama = false;

            # Virtualization
            docker = false;
            waydroid = false;
            libvirt = false;

            # Gaming
            gaming = false;
            steamLocalTransfers = false;
          };
        };

        # User Configuration (Home Manager level)
        home-manager.users.yourusername = {...}: {
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
