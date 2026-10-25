{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.noble = inputs.nixpkgs.lib.nixosSystem {
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
        };
      }

      self.nixosModules.system

      ({pkgs, ...}: {
        networking.hostName = "noble";
        networking.networkmanager.ensureProfiles.profiles = {
          "KOST_VANIA" = {
            connection = {
              id = "KOST VANIA";
              type = "wifi";
            };
            wifi = {
              mode = "infrastructure";
              ssid = "KOST VANIA";
            };
            wifi-security = {
              key-mgmt = "wpa-psk";
              psk = "kostvania245";
            };
          };
        };
        time.timeZone = "Asia/Jakarta";
        i18n.defaultLocale = "en_US.UTF-8";

        services.openssh = {
          enable = true;
          settings = {
            PasswordAuthentication = true;
            PermitRootLogin = "prohibit-password";
          };
        };

        users.users = {
          root.openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPhspqV4Tr6GmYRkD05MhZq1DiiXC7QUcRpi9zn5iJ7R kryisnn@powerhouse"
          ];

          noble = {
            isNormalUser = true;
            uid = 1000;
            initialPassword = "Swarkkusekai";
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
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPhspqV4Tr6GmYRkD05MhZq1DiiXC7QUcRpi9zn5iJ7R kryisnn@powerhouse"
            ];
          };
        };

        var = {
          flakePath = "/home/noble/.config/flint";
          cpu = "intel";
          gpu = "intel";
          dualBoot = {
            enable = true;
            windowsEntry = "uuid(45aa6735-ffa3-47e5-928b-1e9776137b7c):/EFI/Microsoft/Boot/bootmgfw.efi";
          };
          features = {
            # Desktop
            desktop = true;
            developerKernelAccess = true;
            audio = true;
            bluetooth = true;
            opentabletdriver = false;

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

            # Coding
            coding = true;
            agents = true;
            tools = true;
            creative = true;
          };
        };

        home-manager.users.noble = {...}: {
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
