{
  flake.homeModules.coding = {
    lib,
    config,
    osConfig ? {},
    pkgs,
    ...
  }: let
    enabled = osConfig.var.features.coding or false;
  in {
    imports = [
      ./config/_lazyvim.nix
      ./config/_mkenv.nix
    ];

    config = lib.mkIf enabled {
      programs = {
        git = {
          enable = true;
          settings = {
            # CHANGEME
            user = {
              name = "davindakhrisna";
              email = "arpeggio.gns@gmail.com";
            };
            init.defaultBranch = "main";
            safe.directory = [
              (osConfig.var.flakePath or "${config.home.homeDirectory}/.config/flint")
            ];
          };
        };

        gh = {
          enable = true;
          gitCredentialHelper.enable = true;
        };

        direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
      };

      home = {
        sessionPath = [
          "$HOME/.local/bin"
          "${config.home.profileDirectory}/bin"
        ];

        packages = with pkgs; [
          lazygit
          bubblewrap
          jq
          lazydocker
        ];
      };
    };
  };
}
