_: {
  flake.homeModules.dev-min = {
    config,
    lib,
    pkgs,
    osConfig ? {},
    ...
  }: {
    imports = [
      ./_nixvim.nix
      ./_mkenv.nix
    ];

    config = lib.mkIf (config.dev != "off") {
      programs = {
        git = {
          enable = true;
          settings = {
            user = {
              name = "davindakhrisna";
              email = "arpeggio.gns@gmail.com";
            };
            init.defaultBranch = "main";
            safe.directory = [(osConfig.var.flakePath or "${config.home.homeDirectory}/.config/flint") "*"];
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

      home.packages = with pkgs; [
        # Core Build & Compiler Tools
        gcc
        gnumake
        pkg-config

        # Core Database CLI
        sqlite

        # Core CLI & TUI Dev Tools
        fzf
        lazygit
        jq
        alejandra
        nixfmt
      ];
    };
  };
}
