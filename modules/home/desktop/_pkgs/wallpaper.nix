{pkgs, ...}: {
  home.packages = [
    pkgs.awww
  ];

  # Keep the wallpaper library in the Flint checkout.  Deploy only the
  # runtime scripts, so Home Manager does not duplicate the image library
  # under ~/.config/awww.
  xdg.configFile = {
    "awww/init.sh" = {
      source = ./config/awww/init.sh;
      force = true;
    };
    "awww/wallpaper-picker.sh" = {
      source = ./config/awww/wallpaper-picker.sh;
      force = true;
    };
  };

  systemd.user.services = {
    awww = {
      Unit = {
        Description = "AWWW wallpaper daemon";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session-pre.target"];
      };
      Service = {
        ExecStart = "${pkgs.awww}/bin/awww-daemon";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    awww-restore = {
      Unit = {
        Description = "Restore the selected wallpaper";
        After = ["awww.service"];
        Requires = ["awww.service"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "%h/.config/awww/init.sh";
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
