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

  systemd.user.services.flint-battery-monitor = {
    Unit = {
      Description = "Flint battery notification monitor";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session-pre.target" "dunst.service"];
    };
    Service = {
      ExecStart = "%h/.config/hypr/scripts/battery-monitor.sh";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
