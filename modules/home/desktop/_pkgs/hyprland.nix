{
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false;
  };

  xdg.configFile."hypr" = {
    source = ./config/hypr;
    recursive = true;
    force = true;
  };
}
