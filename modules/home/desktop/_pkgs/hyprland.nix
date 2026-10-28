{
  lib,
  osConfig ? {},
  ...
}: {
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false;
  };

  xdg.configFile."hypr" = {
    source = ./config/hypr;
    recursive = true;
    force = true;
  };

  xdg.configFile."hypr/modules/extra.lua" = lib.mkIf (osConfig.var.extra.stealth or false) {
    text = ''
      local mainMod = "SUPER"
      local app = "flint-launch "

      hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd(app .. "flint-stealth"), { desc = "Stealth" })
      hl.bind(mainMod .. " + X", hl.dsp.exec_cmd(app .. "flint-stealth --simulate"), { desc = "Stealth Simulate" })
      hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(app .. "flint-stealth --clear"), { desc = "Stealth Clear" })
    '';
  };

  systemd.user.services.flint-battery-monitor = {
    Unit = {
      Description = "Flint battery notification monitor";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session-pre.target"];
    };
    Service = {
      ExecStart = "%h/.config/hypr/scripts/battery-monitor.sh";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
