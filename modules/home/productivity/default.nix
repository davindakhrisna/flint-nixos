{
  flake.homeModules.productivity = {pkgs, ...}: {
    services.flatpak = {
      enable = true;
      packages = [
        "com.obsproject.Studio"
      ];
    };

    home.packages = with pkgs; [
      # TUI Productivity Suite
      obsidian
      xournalpp
      onlyoffice-desktopeditors
      freecad
    ];
  };
}
