{
  flake.homeModules.entertainment-social = {pkgs, ...}: let
    # The upstream wrapper uses an automatic Ozone hint, which may fall back to
    # XWayland when DISPLAY is present. An XWayland client cannot capture a
    # complete Wayland output, so make Vesktop's backend unambiguous.
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
      # Voice & Chat
      vesktopWayland # Discord with native Wayland screenshare + audio

      # Media & Audio
      pkgs.spotify # Music
    ];
  };
}
