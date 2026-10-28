_: {
  flake.nixosModules.services = _: {
    services = {
      # AI GUI
      dsh-web = {
        enable = true;
        publicUrl = "https://homelab.auxois-searobin.ts.net:8449";
      };

      # Books, Podcasts, and Audiobooks
      audiobookshelf = {
        enable = true;
        host = "127.0.0.1";
        port = 8000;
        dataDir = "audiobookshelf";
        openFirewall = false;
      };

      # Photos and Videos
      immich = {
        enable = true;
        host = "127.0.0.1";
        port = 2283;
        mediaLocation = "/var/lib/immich";
        openFirewall = false;
      };

      # Movies and TV
      jellyfin = {
        enable = true;
        openFirewall = false;
      };

      # Vaultwarden
      vaultwarden = {
        enable = true;
        dbBackend = "sqlite";
        config = {
          ROCKET_ADDRESS = "127.0.0.1";
          ROCKET_PORT = 8222;
          SIGNUPS_ALLOWED = false;
        };
      };

      # Database & Sync (Obsidian)
      couchdb.enable = true;

      # Glance Dashboard
      glance.enable = true;

      # Torrents & Indexers
      jackett.enable = true;
      qbittorrent.enable = true;

      # Shared Storage (NAS)
      samba.enable = true;
      samba-wsdd.enable = true;

      # Remote Browser
      browser.enable = true;
    };
  };
}
