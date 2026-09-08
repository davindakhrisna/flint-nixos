{
  flake.nixosModules.desktop = {pkgs, ...}: {
    # Hyprland UWSM
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };

    # Wayland session flags & display manager
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      AQ_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card0";
    };

    # PAM authentication for Hyprlock (instant zero-delay login)
    security.pam.services.hyprlock = {};

    # Global Fonts & Glyphs
    fonts = {
      fontconfig = {
        enable = true;
        defaultFonts = {
          monospace = ["Iosevka Nerd Font Mono"];
          sansSerif = ["Iosevka Nerd Font Mono"];
          serif = ["Iosevka Nerd Font Mono"];
          emoji = ["Noto Color Emoji"];
        };
      };
      packages = with pkgs; [
        nerd-fonts.iosevka
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        font-awesome
        nerd-fonts.symbols-only
      ];
    };
  };
}
