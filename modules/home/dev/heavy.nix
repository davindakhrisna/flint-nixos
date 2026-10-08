_: {
  flake.homeModules.dev-heavy = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf (config.dev == "heavy") {
      programs.zed-editor = {
        enable = true;
        userSettings = {
          tab_size = 4;
          vim_mode = true;
          cursor_blink = true;
        };
      };

      home.packages = with pkgs; [
        dbgate
        godot_4
        blender
        libresprite
        winboat
      ];
    };
  };
}
