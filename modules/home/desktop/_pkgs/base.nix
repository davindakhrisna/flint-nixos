{
  lib,
  pkgs,
  inputs,
  ...
}: let
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

  heliumExtensionSources = {
    nngceckbapebfimnlniiiahkandclblb = {
      name = "bitwarden";
      hash = "sha256-0aWULZwjTQM4LamSeZMgVQZMquejLMmxV5QMhjFl1Z8=";
    };
  };

  heliumExtensions =
    lib.mapAttrs (
      extensionId: extension:
        pkgs.stdenvNoCC.mkDerivation {
          pname = "helium-extension-${extension.name}";
          version = "${extensionId}-2026-09-11";
          src = pkgs.fetchurl {
            url = "https://clients2.google.com/service/update2/crx?response=redirect&prodversion=150.0.0.0&acceptformat=crx2,crx3&x=id%3D${extensionId}%26installsource%3Dondemand%26uc";
            inherit (extension) hash;
          };
          dontUnpack = true;
          nativeBuildInputs = [pkgs.unzip];
          installPhase = ''
            mkdir -p "$out"
            # CRX3 prefixes a valid ZIP archive with its own header.  unzip
            # extracts it correctly but returns 1 to report that prefix.
            unzip -q "$src" -d "$out" || test -f "$out/manifest.json"
          '';
        }
    )
    heliumExtensionSources;
in {
  imports = lib.optional (inputs ? helium) inputs.helium.homeModules.default;

  home.packages = with pkgs; [
    # Launchers & Secrets
    rofi
    rbw
    rofi-rbw-wayland
    wtype
    pinentry-gnome3
    lua

    # File manager & network storage
    kdePackages.dolphin
    kdePackages.kio-extras
    kdePackages.kio-fuse
    kdePackages.kwallet
    kdePackages.kwalletmanager

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
    (writeShellScriptBin "flint-powermenu" ''
      exec "$HOME/.config/hypr/scripts/powermenu.sh" "$@"
    '')
  ];

  programs = {
    btop.enable = true;

    helium = {
      enable = true;

      flags = [
        "--ozone-platform=wayland"
        "--enable-features=WaylandWindowDecorations"
        "--load-extension=${lib.concatStringsSep "," (map toString (builtins.attrValues heliumExtensions))}"
      ];

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

        DefaultSearchProviderEnabled = true;
        DefaultSearchProviderName = "Duckduckgo";
        DefaultSearchProviderSearchURL = "https://www.duckduckgo.com/?q={searchTerms}";
        DefaultSearchProviderSuggestURL = "https://www.duckduckgo.com/?q={searchTerms}";

        HomepageIsNewTabPage = true;
        HomepageLocation = "https://homelab.auxois-searobin.ts.net/";
        ShowHomeButton = true;
        RestoreOnStartup = 4;

        BookmarkBarEnabled = false;
      };
    };
  };

  xdg = {
    configFile = {
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
      "kwalletrc" = {
        force = true;
        text = ''
          [Wallet]
          Default Wallet=kdewallet
          Enabled=false
        '';
      };
      "systemd/user/xdg-desktop-portal-gtk.service.d/theme.conf" = {
        force = true;
        text = ''
          [Service]
          Environment=GTK_THEME=adw-gtk3-dark
        '';
      };
    };

    dataFile."applications/helium.desktop" = {
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

    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = "helium.desktop";
        "text/xml" = "helium.desktop";
        "application/xhtml+xml" = "helium.desktop";
        "x-scheme-handler/http" = "helium.desktop";
        "x-scheme-handler/https" = "helium.desktop";
        "x-scheme-handler/about" = "helium.desktop";
        "x-scheme-handler/unknown" = "helium.desktop";
        "x-scheme-handler/discord" = "vesktop.desktop";
      };
    };
  };

  # KIO's SMB worker delegates credential prompts to kpasswdserver, which is
  # hosted by kiod. Plasma starts it automatically; standalone Hyprland does
  # not, so start it with the graphical session.
  systemd.user.services.kde-kiod = {
    Unit = {
      Description = "KDE I/O daemon";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session-pre.target"];
    };
    Install.WantedBy = ["graphical-session.target"];
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.kdePackages.kio}/libexec/kf6/kiod6";
      Restart = "on-failure";
    };
  };
}
