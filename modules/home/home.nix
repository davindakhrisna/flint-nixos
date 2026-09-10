{
  flake.homeModules.home-manager = {
    config,
    lib,
    pkgs,
    osConfig ? {},
    ...
  }: let
    flakePath = osConfig.var.flakePath or "${config.home.homeDirectory}/.config/flint";
  in {
    xdg.enable = true;

    home = {
      stateVersion = "26.05";

      sessionVariables = {
        EDITOR = "nvim";
        FLINT_DIR = flakePath;
        NH_FLAKE = flakePath;

        # NVIDIA & OpenGL cache
        CUDA_CACHE_PATH = "$HOME/.cache/nv";
        __GL_SHADER_DISK_CACHE_PATH = "$HOME/.cache/nv";

        # Xwayland compatibility cache. Hyprland remains the only session.
        XCOMPOSECACHE = "$HOME/.cache/X11/compose";

        # Shell & tool history / configs
        HISTFILE = "$HOME/.local/state/bash/history";
        WGETRC = "$HOME/.config/wgetrc";
        DOCKER_CONFIG = "$HOME/.config/docker";
      };

      pointerCursor = {
        enable = true;
        name = "Bibata-Modern-Classic";
        package = pkgs.bibata-cursors;
        size = 24;
        gtk.enable = true;
        x11.enable = true; # Cursor support for Xwayland clients only.
        hyprcursor.enable = true;
      };

      # Prevent Home Manager from linking legacy dotfiles directly in $HOME root
      file =
        {
          ".zshenv".enable = false;
        }
        // (lib.optionalAttrs (config.gtk.theme.name != null) {
          ".themes/${config.gtk.theme.name}".enable = false;
        });
    };

    # Relocate .gtkrc-2.0 and .Xresources away from $HOME
    gtk = {
      theme = {
        name = "adw-gtk3-dark";
        package = pkgs.adw-gtk3;
      };
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      cursorTheme = {
        name = "Bibata-Modern-Classic";
        package = pkgs.bibata-cursors;
        size = 24;
      };
      font = {
        name = "Noto Sans";
        size = 11;
      };
      gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
      gtk2.force = true;
    };

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = "adw-gtk3-dark";
        icon-theme = "Papirus-Dark";
        cursor-theme = "Bibata-Modern-Classic";
        cursor-size = 24;
        font-name = "Noto Sans 11";
        document-font-name = "Noto Serif 11";
        monospace-font-name = "Iosevka Nerd Font 12";
      };
    };

    qt = {
      enable = true;
      platformTheme.name = "gtk3";
      style.name = "adwaita-dark";
    };

    # Xresources are consumed only by legacy applications under Xwayland.
    xresources.path = "${config.xdg.configHome}/X11/Xresources";

    programs.home-manager.enable = true;
  };
}
