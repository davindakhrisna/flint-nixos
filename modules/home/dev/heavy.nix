_: {
  flake.homeModules.dev-heavy = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf (config.dev == "heavy") {
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
