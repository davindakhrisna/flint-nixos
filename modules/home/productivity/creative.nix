{
  flake.homeModules.creative = {
    lib,
    osConfig ? {},
    pkgs,
    ...
  }: let
    enabled = osConfig.var.features.creative or false;
  in {
    config = lib.mkIf enabled {
      home.packages = with pkgs; [
        godot_4
        blender
        libresprite
      ];
    };
  };
}
