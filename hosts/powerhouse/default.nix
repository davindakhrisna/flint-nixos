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
      ./_disko.nix
      inputs.disko.nixosModules.disko
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = {inherit inputs self;};
          backupFileExtension = "backup";
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
            "libvirtd"
            "uinput"
            "input"
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
            # Desktop
            desktop = true;
            developerKernelAccess = true;
            audio = true;
            bluetooth = true;
            opentabletdriver = true;

            # Mesh VPN
            tailscale = true;

            # AI
            ollama = false;

            # Virtualization
            docker = true;
            waydroid = true;
            libvirt = true;

            # Gaming
            gaming = false;
            steamLocalTransfers = false;

            # Coding
            coding = true;
            agents = true;
            tools = true;
            creative = true;
          };

          extra = {
            xinu = true;
            stealth = true;
          };
        };

        home-manager.users.kryisnn = {...}: {
          imports = with self.homeModules; [
            home-manager
            desktop
            shell
            productivity
            entertainment-social
            entertainment-gaming
            coding
            agents
            tools
            creative
          ];
        };

        system.stateVersion = "26.05";
      })
    ];
  };
}
