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
        # Winboat 0.9.0 is currently tied to Electron 40 by its locked native
        # dependency toolchain. The exact runtime exception lives in base.nix.
        winboat
      ];
    };
  };
}
