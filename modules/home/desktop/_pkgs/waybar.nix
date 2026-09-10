{
  lib,
  pkgs,
  ...
}: let
  # Hyprland 0.56 uses Lua dispatch expressions while Waybar still emits
  # legacy workspace IPC. The shim also preserves the vertical-bar tooltip
  # placement. Keep it scoped to Waybar and build it from reviewed source.
  compatibilityShim = pkgs.stdenv.mkDerivation {
    pname = "flint-waybar-hyprland-compat";
    version = "0.56";
    src = lib.cleanSourceWith {
      src = ./config/waybar/shim;
      filter = path: type: type == "directory" || lib.hasSuffix ".c" path;
    };
    dontConfigure = true;
    buildPhase = ''
      runHook preBuild
      $CC -O2 -fPIC -Wall -Wextra -Werror \
        hyprland_ipc_shim.c -shared -ldl -o libhypr_waybar_shim.so
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      install -Dm755 libhypr_waybar_shim.so \
        $out/lib/libhypr_waybar_shim.so
      runHook postInstall
    '';
  };
in {
  home.packages = [
    pkgs.waybar
  ];

  xdg.configFile."waybar" = {
    source = ./config/waybar;
    recursive = true;
    force = true;
  };

  systemd.user.services.waybar = {
    Unit = {
      Description = "Waybar status bar";
      Documentation = ["https://github.com/Alexays/Waybar/wiki"];
      PartOf = ["graphical-session.target"];
      After = ["graphical-session-pre.target"];
    };
    Service = {
      ExecStart = "${pkgs.waybar}/bin/waybar";
      Environment = "LD_PRELOAD=${compatibilityShim}/lib/libhypr_waybar_shim.so";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
