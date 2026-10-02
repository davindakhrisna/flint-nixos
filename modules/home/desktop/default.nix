{
  flake.homeModules.desktop = {lib, ...}: {
    imports = [
      ./_pkgs/base.nix
      ./_pkgs/hyprland.nix
      ./_pkgs/waybar.nix
      ./_pkgs/wallpaper.nix
      ./_pkgs/lockscreen.nix
      ./_pkgs/dunst.nix
    ];

    home.activation.reloadDesktop = lib.hm.dag.entryAfter ["writeBoundary" "reloadSystemd"] ''
      if [[ -z "''${DRY_RUN_CMD:-}" ]]; then
        if [[ -x "$HOME/.config/hypr/scripts/reload-desktop.sh" ]]; then
          $HOME/.config/hypr/scripts/reload-desktop.sh || true
        fi
      fi
    '';
  };
}
