{pkgs, ...}: {
  home.packages = [
    pkgs.awww
  ];

  xdg.configFile."awww" = {
    source = ./config/awww;
    recursive = true;
    force = true;
  };
}
