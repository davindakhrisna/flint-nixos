{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.portable = inputs.nixpkgs.lib.nixosSystem {
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
        networking.hostName = "portable";

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

        var = {
          flakePath = "/home/kryisnn/.config/flint";
          cpu = "amd";
          gpu = "amd";
          features = {
            # Desktop
            desktop = true;
            developerKernelAccess = true;
            audio = true;
            bluetooth = true;

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
            creative = false;
          };

          extra = {
            xinu = true;
            stealth = false;
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
