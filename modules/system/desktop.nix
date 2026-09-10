{
  flake.nixosModules.desktop = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.var.features.desktop {
      # Hyprland UWSM
      programs.hyprland = {
        enable = true;
        withUWSM = true;
        xwayland.enable = true;
      };

      # Display Manager
      services.displayManager.ly.enable = true;

      # Hyprland owns Wayland capture. GTK is retained only as the fallback
      xdg.portal = {
        enable = true;
        xdgOpenUsePortal = true;
        config.hyprland = {
          default = ["hyprland" "gtk"];
          "org.freedesktop.impl.portal.ScreenCast" = ["hyprland"];
          "org.freedesktop.impl.portal.RemoteDesktop" = ["hyprland"];
          "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
        };
      };

      # Wayland session flags & display manager
      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        GTK_THEME = "adw-gtk3-dark";
        QT_QPA_PLATFORMTHEME = "gtk3";
        QT_STYLE_OVERRIDE = "adwaita-dark";
      };

      # PAM authentication for Hyprlock (instant zero-delay login)
      security.pam.services.hyprlock = {};

      hardware.bluetooth = {
        enable = config.var.features.bluetooth;
        powerOnBoot = config.var.features.bluetooth;
      };
      services.udisks2.enable = config.var.features.removableStorage;

      # Global Fonts & Glyphs
      fonts = {
        fontconfig = {
          enable = true;
          defaultFonts = {
            monospace = ["Iosevka Nerd Font Mono"];
            sansSerif = ["Noto Sans"];
            serif = ["Noto Serif"];
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
  };
}
