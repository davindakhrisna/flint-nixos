{
  lib,
  pkgs,
  inputs,
  ...
}: let
  # Hyprland also ships a direct launcher named start-hyprland.  Install this
  # wrapper at a higher Home Manager package priority so every shell resolves
  # the UWSM-managed entry point, independent of ~/.local/bin ordering.
  startHyprland = lib.hiPrio (pkgs.writeShellScriptBin "start-hyprland" ''
    if ! ${pkgs.uwsm}/bin/uwsm check may-start; then
      echo "A UWSM session cannot be started from this login context." >&2
      exit 1
    fi
    exec ${pkgs.uwsm}/bin/uwsm start -e -D Hyprland -- hyprland.desktop
  '');

  flintLaunch = pkgs.writeShellScriptBin "flint-launch" ''
    exec ${pkgs.uwsm}/bin/uwsm app -- "$@"
  '';
in {
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
    hyprpicker
    imagemagick

    # System & Clipboard
    cliphist
    polkit_gnome

    # Theme assets
    bibata-cursors
    papirus-icon-theme
    adw-gtk3
    gsettings-desktop-schemas
    kitty
    startHyprland
    flintLaunch

    (writeShellScriptBin "flint-rofi-tools" ''
      exec "$HOME/.config/hypr/scripts/rofi-tools.sh" "$@"
    '')
    (writeShellScriptBin "flint-wallpaper-picker" ''
      exec "$HOME/.config/awww/wallpaper-picker.sh" "$@"
    '')
  ];

  programs = {
    btop.enable = true;

    helium = {
      enable = true;

      policies = {
        BrowserSignin = 0;
        SyncDisabled = true;
        SigninAllowed = false;

        PasswordManagerEnabled = false;
        AutofillAddressEnabled = false;
        AutofillCreditCardEnabled = false;
        SafeBrowsingEnabled = true;
        MetricsReportingEnabled = false;
        SpellCheckServiceEnabled = false;
        DefaultCookiesSetting = 1;
        DefaultGeolocationSetting = 2;
        DefaultNotificationsSetting = 2;
        DefaultPopupsSetting = 2;

        DefaultBrowserSettingEnabled = false;
        DeveloperToolsAvailability = 1;

        DnsOverHttpsMode = "automatic";
        DnsOverHttpsTemplates = "https://dns.quad9.net/dns-query";

        DefaultSearchProviderEnabled = true;
        DefaultSearchProviderName = "Duckduckgo";
        DefaultSearchProviderSearchURL = "https://www.duckduckgo.com/?q={searchTerms}";
        DefaultSearchProviderSuggestURL = "https://www.duckduckgo.com/?q={searchTerms}";

        NewTabPageLocation = "http://127.0.0.1:8888";
        HomepageIsNewTabPage = false;
        HomepageLocation = "http://127.0.0.1:8888";
        ShowHomeButton = false;
        RestoreOnStartup = 4;

        BookmarkBarEnabled = false;

        ExtensionInstallForcelist = [
          "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimiu
          "gcknhkkoolaabfmlnjonogaaifnjlfnp" # FoxyProxy
          "ghmbeldphafepmbegfdlkpapadhbakde" # Proton Pass
          "mdjildafknihdffpkfmmpnpoiajfjnjd" # Consent-O-Matic
          "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # Privacy Badger
        ];
      };
    };
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
    "obsidian-flags.conf" = {
      source = ./config/obsidian-flags.conf;
      force = true;
    };
    "spotify-flags.conf" = {
      source = ./config/spotify-flags.conf;
      force = true;
    };
    "systemd/user/xdg-desktop-portal-gtk.service.d/theme.conf" = {
      force = true;
      text = ''
        [Service]
        Environment=GTK_THEME=adw-gtk3-dark
      '';
    };
  };

  # A user-local desktop entry takes precedence over the package entry. Manage
  # it directly so upgrades cannot leave an old X11 launcher shadowing this
  # Wayland/dark-mode command.
  xdg.dataFile."applications/helium.desktop" = {
    force = true;
    text = ''
      [Desktop Entry]
      Type=Application
      Version=1.0
      Name=Helium
      GenericName=Web Browser
      Comment=Browse the web
      Exec=helium --ozone-platform=wayland --force-dark-mode %U
      Icon=helium
      Terminal=false
      Categories=Network;WebBrowser;
      MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
      StartupNotify=true
      StartupWMClass=Helium
    '';
  };

  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    Unit = {
      Description = "polkit-gnome-authentication-agent-1";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session-pre.target"];
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
