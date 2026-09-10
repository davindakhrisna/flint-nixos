{
  flake.homeModules.entertainment-gaming = {
    lib,
    osConfig ? {},
    pkgs,
    ...
  }: let
    enabled = osConfig.var.features.gaming or false;
  in {
    config = lib.mkIf enabled {
      programs.mangohud = {
        enable = true;
        enableSessionWide = false;
        settings = {
          fps_limit = [0 144 60];
          toggle_fps_limit = "F1";
          toggle_hud = "Shift_R+F12";

          cpu_stats = true;
          cpu_temp = true;
          gpu_stats = true;
          gpu_temp = true;
          ram = true;
          vram = true;
          fps = true;
          frametime = true;
          frame_timing = 1;
        };
      };

      services.flatpak = {
        enable = true;
        packages = [
          "org.vinegarhq.Sober"
        ];
      };

      home.packages = with pkgs; [
        # Game Compatibility & Launchers
        protonup-qt
        heroic
        gamescope
      ];
    };
  };
}
