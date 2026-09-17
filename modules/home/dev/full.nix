_: {
  flake.homeModules.dev-full = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf (config.dev == "full") {
      home.packages = with pkgs; [
        godot_4
        blender
        libresprite
        winboat
      ];
    };
  };
}
