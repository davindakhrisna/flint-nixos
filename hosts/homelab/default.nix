{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.homelab = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit inputs self;};
    modules = [
      ./_hardware.nix
      inputs.home-manager.nixosModules.home-manager
      inputs.hermes-agent.nixosModules.default
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
        };
      }

      self.nixosModules.system

      # Services
      self.nixosModules.tailscale-server
      self.nixosModules.nas
      self.nixosModules.server-tmpfiles
      self.nixosModules.services
      self.nixosModules.couchdb
      self.nixosModules.glance
      self.nixosModules.torrents
      self.nixosModules.browser

      ({pkgs, ...}: {
        security.sudo.wheelNeedsPassword = false;
        networking.hostName = "homelab";

        time.timeZone = "Asia/Jakarta";
        i18n.defaultLocale = "en_US.UTF-8";

        users.users.kryisnn = {
          isNormalUser = true;
          uid = 1001;
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

        services.logind.settings.Login = {
          HandleLidSwitch = "ignore";
          HandleLidSwitchExternalPower = "ignore";
          HandleLidSwitchDocked = "ignore";
        };

        var = {
          flakePath = "/home/kryisnn/.config/flint";
          cpu = "amd";
          gpu = "amd";
          dualBoot = {
            enable = true;
            windowsEntry = "uuid(dc68ee6b-9b35-49c8-b40f-3995d7f44547):/EFI/Microsoft/Boot/bootmgfw.efi";
          };
          features = {
            # Desktop
            desktop = false;
            developerKernelAccess = true;
            audio = true;
            bluetooth = false;

            # AI
            ollama = false;

            # Virtualization
            tailscale = true;
            docker = true;
            waydroid = false;
            libvirt = true;

            # Gaming
            gaming = false;
            steamLocalTransfers = false;
          };
        };

        home-manager.users.kryisnn = {
          home.stateVersion = "26.05";
          programs.zsh.enable = true;
        };

        system.stateVersion = "26.05";
      })
    ];
  };
}
