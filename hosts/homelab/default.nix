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
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = {inherit inputs self;};
          backupFileExtension = "backup";
          sharedModules = [inputs.nix-flatpak.homeManagerModules.nix-flatpak];
        };
      }

      self.nixosModules.system

      # Services
      self.nixosModules.tailscale-server
      self.nixosModules.nas
      self.nixosModules.server-tmpfiles
      self.nixosModules.services
      self.nixosModules.hermes
      self.nixosModules.couchdb
      self.nixosModules.glance
      self.nixosModules.torrents
      self.nixosModules.browser

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
            "hermes"
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
          };
        };

        home-manager.users.kryisnn = {lib, ...}: {
          imports = with self.homeModules; [
            home-manager
            desktop
            dev
            entertainment-social
            entertainment-gaming
            shell
            productivity
          ];

          dev = "maximal";
          home.activation.disableLegacyHermesGateway = lib.hm.dag.entryAfter ["writeBoundary"] ''
            if [[ -z "''${DRY_RUN_CMD:-}" ]] &&
              [[ -e "$HOME/.config/systemd/user/hermes-gateway.service" ]]; then
              ${pkgs.systemd}/bin/systemctl --user disable --now hermes-gateway.service
              ${pkgs.systemd}/bin/systemctl --user reset-failed hermes-gateway.service || true
            fi
          '';
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
