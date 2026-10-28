{
  flake.homeModules.productivity = {pkgs, ...}: {
    home.packages = with pkgs; [
      obs-studio
      obsidian
      xournalpp
      onlyoffice-desktopeditors
      freecad
    ];
  };

  flake.homeModules.programs = {pkgs, ...}: {
    home.packages = with pkgs; [
      obs-studio
      obsidian
      xournalpp
      onlyoffice-desktopeditors
      freecad
    ];
  };
}
