{pkgs, ...}: {
  services.dunst = {
    enable = true;
    configFile = pkgs.writeText "dunstrc" (builtins.readFile ./config/dunst/dunstrc);
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
      size = "32x32";
    };
  };
}
