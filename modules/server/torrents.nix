_: {
  flake.nixosModules.torrents = {pkgs, ...}: let
    jackettPort = 9117;
    flaresolverrPort = 8191;
    qbittorrentPort = 8090;
    torrentingPort = 51413;
    downloadDir = "/srv/nas/torrents";

    searchPlugins = pkgs.fetchFromGitHub {
      owner = "qbittorrent";
      repo = "search-plugins";
      rev = "0635b77ad09c36d4deca55ea044374ea66a18b94";
      hash = "sha256-FRK6W7FfM3+fci7/XRYnZlOmrviGxtp9FUC2jVRwYVw=";
    };
    prepareJackett = pkgs.writeShellScript "prepare-jackett" (builtins.readFile ./config/prepare-jackett.sh);
    seedJackettIndexers = pkgs.writeShellScript "seed-jackett-indexers" (builtins.readFile ./config/seed-jackett-indexers.sh);
    seedQbittorrentRss = pkgs.writeShellScript "seed-qbittorrent-rss" (builtins.readFile ./config/seed-qbittorrent-rss.sh);
  in {
    virtualisation.oci-containers = {
      backend = "docker";
      containers.flaresolverr = {
        image = "ghcr.io/flaresolverr/flaresolverr@sha256:258523d25e4e07028c3a206f0e03ae807b26a50a201dd320f09a18464ecf86fa";
        autoStart = true;
        ports = ["127.0.0.1:${toString flaresolverrPort}:8191"];
        environment = {
          LOG_LEVEL = "info";
          CAPTCHA_SOLVER = "none";
          DISABLE_MEDIA = "true";
        };
        extraOptions = [
          "--security-opt=no-new-privileges"
          "--cap-drop=ALL"
          "--memory=1024m"
        ];
      };
    };

    services.jackett = {
      enable = true;
      port = jackettPort;
      dataDir = "/var/lib/jackett/.config/Jackett";
      openFirewall = false;
    };

    services.qbittorrent = {
      enable = true;
      group = "nas";
      webuiPort = qbittorrentPort;
      inherit torrentingPort;
      openFirewall = false;
      extraArgs = ["--confirm-legal-notice"];
      serverConfig = {
        LegalNotice.Accepted = true;
        BitTorrent.Session = {
          AnonymousModeEnabled = true;
          DefaultSavePath = "${downloadDir}/";
          TempPath = "${downloadDir}/.incomplete/";
          TempPathEnabled = true;
          Port = torrentingPort;
          DHTEnabled = true;
          PeXEnabled = true;
          LSDEnabled = false;
        };
        Network.PortForwardingEnabled = false;
        Preferences.WebUI = {
          Address = "127.0.0.1";
          Port = qbittorrentPort;
          UseUPnP = false;
          LocalHostAuth = false;
          AuthSubnetWhitelist = "";
          AuthSubnetWhitelistEnabled = false;
          ReverseProxySupportEnabled = true;
          TrustedReverseProxiesList = "127.0.0.1";
          ServerDomains = "*";
          HostHeaderValidation = false;
          CSRFProtection = true;
        };
      };
    };

    systemd.services = {
      jackett = {
        path = with pkgs; [coreutils jq];
        environment = {
          JACKETT_PORT = toString jackettPort;
          FLARESOLVERR_PORT = toString flaresolverrPort;
        };
        after = ["docker-flaresolverr.service"];
        wants = ["docker-flaresolverr.service"];
        serviceConfig = {
          ExecStartPre = ["+${prepareJackett}"];
          ReadWritePaths = ["/var/lib/secrets"];
        };
      };

      jackett-seed-indexers = {
        description = "Provision default Jackett providers";
        wantedBy = ["multi-user.target"];
        after = ["jackett.service"];
        requires = ["jackett.service"];
        path = with pkgs; [coreutils curl];
        environment.JACKETT_PORT = toString jackettPort;
        serviceConfig = {
          Type = "oneshot";
          TimeoutStartSec = "120s";
          ExecStart = seedJackettIndexers;
        };
      };

      qbittorrent = {
        after = ["jackett.service"];
        wants = ["jackett.service"];
        serviceConfig = {
          Restart = "on-success";
          RestartSec = "5s";
          ReadWritePaths = [downloadDir];
          UMask = "0007";
          ExecStartPre = [
            "${pkgs.coreutils}/bin/install -d -m 0755 /var/lib/qBittorrent/qBittorrent/data/nova3/engines"
            "${pkgs.coreutils}/bin/install -m 0444 ${searchPlugins}/nova3/engines/jackett.py /var/lib/qBittorrent/qBittorrent/data/nova3/engines/jackett.py"
            "${pkgs.python3}/bin/python3 ${./config/apply-qbittorrent-credentials.py}"
          ];
        };
      };

      qbittorrent-rss-feeds = {
        description = "Provision Jackett RSS feeds into qBittorrent";
        wantedBy = ["multi-user.target"];
        after = ["qbittorrent.service" "jackett.service"];
        requires = ["qbittorrent.service" "jackett.service"];
        path = with pkgs; [coreutils curl jq];
        environment = {
          JACKETT_PORT = toString jackettPort;
          QBITTORRENT_PORT = toString qbittorrentPort;
        };
        serviceConfig = {
          Type = "oneshot";
          TimeoutStartSec = "60s";
          Restart = "on-failure";
          RestartSec = "20s";
          ExecStart = seedQbittorrentRss;
        };
      };
    };
  };
}
