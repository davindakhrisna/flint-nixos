_: {
  flake.homeModules.dev-minimal = {
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

    config = lib.mkIf (builtins.elem config.dev ["minimal" "full"]) {
      programs = {
        git = {
          enable = true;
          settings = {
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

        zed-editor = {
          enable = true;
          userSettings = {
            tab_size = 4;
            vim_mode = true;
            cursor_blink = true;
          };
        };
      };

      home.packages = with pkgs; [
        lazygit
        jq
        lazydocker
        netcat-gnu
        dbgate
        bruno
        google-antigravity-ide
        codex
        opencode
      ];
    };
  };
}
