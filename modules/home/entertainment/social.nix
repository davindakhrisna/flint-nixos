{
  flake.homeModules.entertainment-social = {pkgs, ...}: let
    vesktopWayland = pkgs.vesktop.overrideAttrs (oldAttrs: {
      postFixup =
        (oldAttrs.postFixup or "")
        + ''
          wrapProgram $out/bin/vesktop \
            --add-flags "--ozone-platform=wayland"
        '';
    });
  in {
    home.packages = [
      vesktopWayland
      pkgs.spotify
    ];
  };
}
