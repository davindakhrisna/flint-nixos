# This is my Homelab configured to be portable
# You might want to change it since its not true-headless
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
      # ./_disko.nix
      # inputs.disko.nixosModules.disko
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = {inherit inputs self;};
          backupFileExtension = "backup";
        };
      }

      # Services
      self.nixosModules.system
      self.nixosModules.server

      ({
        pkgs,
        lib,
        ...
      }: {
        boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_18;

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
          features = {
            # Desktop
            desktop = true;
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

            # Coding
            coding = true;
            agents = true;
            tools = true;
            creative = true;
          };

          extra = {
            xinu = false;
            stealth = false;
          };
        };

        home-manager.users.kryisnn = {lib, ...}: {
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

          services.hypridle.enable = lib.mkForce false;
          xdg.configFile."hypr/modules/lid.lua".text = ''
            hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("hyprctl dispatch dpms off"), { locked = true })
            hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("hyprctl dispatch dpms on"), { locked = true })
          '';
        };

        system.stateVersion = "26.05";
      })
    ];
  };
}
