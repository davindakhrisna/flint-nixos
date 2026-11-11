{pkgs, ...}: {
  programs.hyprlock.enable = true;
  services.hypridle.enable = true;

  # Don't (re)start hypridle while focus mode is active (e.g. after a switch or relogin).
  systemd.user.services.hypridle.Service.ExecCondition = "${pkgs.coreutils}/bin/test ! -e %t/flint/hypr_focusmode_active";
}
