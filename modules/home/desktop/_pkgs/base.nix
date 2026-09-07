{
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = lib.optional (inputs ? helium) inputs.helium.homeModules.default;

  home.packages = with pkgs; [
    # Launchers & Secrets
    rofi
    rbw
    rofi-rbw-wayland
    wtype
    pinentry-gnome3

    # File manager
    kdePackages.dolphin

    # Audio & Bluetooth
    wiremix
    bluetui
    pamixer
    pulseaudio
    gazelle-tui

    # Display & Monitor Management
    hyprmon
    wlr-randr
    hyprsunset
    socat

    # Screenshots & Recording
    grim
    slurp
    satty
    swappy
    wl-screenrec

    # System & Clipboard
    cliphist
    polkit_gnome

    # Theme assets
    bibata-cursors
    papirus-icon-theme
    adw-gtk3
    gsettings-desktop-schemas
    kitty
  ];

  programs = {
    btop.enable = true;
    helium.enable = true;
  };

  xdg.configFile = {
    "rofi" = {
      source = ./config/rofi;
      recursive = true;
      force = true;
    };
    "kitty" = {
      source = ./config/kitty;
      recursive = true;
      force = true;
    };
    "gtk-3.0" = {
      source = ./config/gtk-3.0;
      recursive = true;
      force = true;
    };
    "gtk-4.0" = {
      source = ./config/gtk-4.0;
      recursive = true;
      force = true;
    };
    "fontconfig/fonts.conf" = {
      source = ./config/fontconfig/fonts.conf;
      force = true;
    };
    "kdeglobals" = {
      source = ./config/kdeglobals;
      force = true;
    };
    "electron-flags.conf" = {
      source = ./config/electron-flags.conf;
      force = true;
    };
    "code-flags.conf" = {
      source = ./config/code-flags.conf;
      force = true;
    };
    "vesktop-flags.conf" = {
      source = ./config/vesktop-flags.conf;
      force = true;
    };
    "obsidian-flags.conf" = {
      source = ./config/obsidian-flags.conf;
      force = true;
    };
    "spotify-flags.conf" = {
      source = ./config/spotify-flags.conf;
      force = true;
    };
  };

  xdg.desktopEntries.helium = {
    name = "Helium";
    genericName = "Web Browser";
    exec = "helium --ozone-platform=x11 %U";
    icon = "helium";
    terminal = false;
    categories = ["Network" "WebBrowser"];
    mimeType = [
      "text/html"
      "text/xml"
      "application/xhtml+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];
  };

  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    Unit = {
      Description = "polkit-gnome-authentication-agent-1";
      WantedBy = ["graphical-session.target"];
      Wants = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };
}
