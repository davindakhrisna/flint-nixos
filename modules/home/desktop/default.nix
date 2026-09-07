{
  flake.homeModules.desktop = {...}: {
    imports = [
      ./_pkgs/base.nix
      ./_pkgs/hyprland.nix
      ./_pkgs/waybar.nix
      ./_pkgs/wallpaper.nix
      ./_pkgs/lockscreen.nix
      ./_pkgs/dunst.nix
    ];
  };
}
