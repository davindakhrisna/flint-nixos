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

      self.nixosModules.system

      ({pkgs, ...}: {
        networking.hostName = "powerhouse";
        time.timeZone = "Asia/Jakarta";
        i18n.defaultLocale = "en_US.UTF-8";

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

        var = {
          flakePath = "/home/kryisnn/.config/flint";
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
            windowsEntry = "uuid(dc68ee6b-9b35-49c8-b40f-3995d7f44547):/EFI/Microsoft/Boot/bootmgfw.efi";
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

        environment.sessionVariables.AQ_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card0";
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

          dev = "full";
        };

        system.stateVersion = "26.05";
      })
    ];
  };
}
