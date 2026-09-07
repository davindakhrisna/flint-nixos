{
  services.dunst = {
    enable = true;
    configFile = ./config/dunst/dunstrc;
  };

  xdg.configFile."dunst/dunstrc".force = true;
}
