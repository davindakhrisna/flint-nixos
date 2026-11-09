_: {
  flake.nixosModules.services = {
    config,
    lib,
    pkgs,
    ...
  }: {
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

    systemd.services = {
      audiobookshelf-bootstrap = lib.mkIf config.services.audiobookshelf.enable {
        description = "Bootstrap Audiobookshelf root user from SOPS";
        after = ["audiobookshelf.service" "sops-nix.service"];
        wants = ["audiobookshelf.service" "sops-nix.service"];
        wantedBy = ["multi-user.target"];
        path = [pkgs.curl pkgs.python3];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          Restart = "no";
        };
        script = ''
          if [ ! -s "${config.sops.secrets.user_password.path}" ]; then
            exit 0
          fi
          password=$(<"${config.sops.secrets.user_password.path}")
          for _ in {1..30}; do
            if curl -fsS http://127.0.0.1:8000/ping >/dev/null 2>&1; then
              break
            fi
            sleep 1
          done
          payload=$(python3 -c "import json, sys; print(json.dumps({'newRoot': {'username': 'kryisnn', 'password': sys.argv[1]}}))" "$password")
          curl -s -X POST "http://127.0.0.1:8000/init" \
            -H "Content-Type: application/json" \
            --data-binary "$payload" >/dev/null 2>&1 || true
        '';
      };

      immich-bootstrap = lib.mkIf config.services.immich.enable {
        description = "Bootstrap Immich admin user from SOPS";
        after = ["immich-server.service" "sops-nix.service"];
        wants = ["immich-server.service" "sops-nix.service"];
        wantedBy = ["multi-user.target"];
        path = [pkgs.curl pkgs.python3];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          Restart = "no";
        };
        script = ''
          if [ ! -s "${config.sops.secrets.user_password.path}" ]; then
            exit 0
          fi
          password=$(<"${config.sops.secrets.user_password.path}")
          for _ in {1..30}; do
            if curl -fsS http://127.0.0.1:2283/api/server/ping >/dev/null 2>&1; then
              break
            fi
            sleep 1
          done
          payload=$(python3 -c "import json, sys; print(json.dumps({'email': 'kryisnn@homelab.local', 'password': sys.argv[1], 'name': 'kryisnn'}))" "$password")
          curl -s -X POST "http://127.0.0.1:2283/api/auth/admin-sign-up" \
            -H "Content-Type: application/json" \
            --data-binary "$payload" >/dev/null 2>&1 || true
        '';
      };
    };
  };
}
