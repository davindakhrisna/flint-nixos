_: {
  flake.nixosModules.server-tmpfiles = _: {
    systemd = {
      tmpfiles.rules = [
        # NAS
        "d /srv/nas 2770 root nas -"
        "d /srv/nas/torrents 2770 qbittorrent nas -"
        "d /srv/nas/torrents/.incomplete 2770 qbittorrent nas -"
        "d /srv/nas/downloads 2770 kryisnn nas -"
        "d /var/lib/headless-browser 0700 kryisnn users -"
        "d /var/lib/qBittorrent/qBittorrent/data/nova3/engines 0755 qbittorrent nas -"
        "d /var/lib/jackett/.config/Jackett 0700 jackett jackett -"
        "d /var/lib/jackett/.config/Jackett/Indexers 0700 jackett jackett -"

        # Glance and Tailscale service URLs
        "d /run/homelab 0755 root root - -"
        "f /run/homelab/glance.env 0644 root root - HOMELAB_HOST=homelab.auxois-searobin.ts.net"

        # Service secrets
        "d /var/lib/secrets 0711 root root - -"
        "f /var/lib/secrets/vaultwarden.env 0600 root root - -"
        "f /var/lib/secrets/obsidian-sync-admin-password 0640 root couchdb - -"
        "f /var/lib/secrets/jackett-api-key 0640 root jackett - -"
        "f /var/lib/secrets/qbittorrent-webui 0640 qbittorrent nas - -"
      ];

      services = {
        systemd-tmpfiles-clean = {
          unitConfig = {
            StartLimitIntervalSec = 300;
            StartLimitBurst = 3;
          };
          serviceConfig = {
            Restart = "on-failure";
            RestartSec = "30s";
          };
        };
        vaultwarden.serviceConfig.EnvironmentFile = [
          "-/run/homelab/vaultwarden.env"
          "-/var/lib/secrets/vaultwarden.env"
        ];
      };
    };

    services.glance.environmentFile = "/run/homelab/glance.env";
  };
}
