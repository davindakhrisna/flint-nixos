_: {
  flake.nixosModules.services = _: {
    services = {
      # PDF, Book, and more
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

      # Hermes Agent
      hermes-agent = {
        enable = true;
        settings.model.default = "anthropic/claude-sonnet-4";
        backend.mode = "dashboard";
        backend.port = 9120;
        addToSystemPackages = true;
      };
    };
  };
}
