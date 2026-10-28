_: {
  flake.nixosModules.tailscale-server = {
    pkgs,
    config,
    ...
  }: {
    services.openssh.enable = false;

    services.tailscale = {
      enable = true;
      useRoutingFeatures = "server";
      extraSetFlags = [
        "--ssh=true"
      ];
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [22];

    systemd.services.tailscale-serve = {
      description = "Tailscale Serve - declarative HTTPS reverse proxy";
      after = ["tailscaled.service" "network-online.target"];
      wants = ["tailscaled.service" "network-online.target"];
      wantedBy = ["multi-user.target"];

      path = [
        config.services.tailscale.package
        pkgs.jq
        pkgs.coreutils
        pkgs.systemd
        pkgs.diffutils
      ];

      environment = {
        ENABLE_GLANCE =
          if config.services.glance.enable
          then "1"
          else "0";
        ENABLE_IMMICH =
          if config.services.immich.enable
          then "1"
          else "0";
        ENABLE_VAULTWARDEN =
          if config.services.vaultwarden.enable
          then "1"
          else "0";
        ENABLE_COUCHDB =
          if config.services.couchdb.enable
          then "1"
          else "0";
        ENABLE_DSH_WEB =
          if config.services.dsh-web.enable
          then "1"
          else "0";
        ENABLE_AUDIOBOOKSHELF =
          if config.services.audiobookshelf.enable
          then "1"
          else "0";
        ENABLE_QBITTORRENT =
          if config.services.qbittorrent.enable
          then "1"
          else "0";
        ENABLE_JACKETT =
          if config.services.jackett.enable
          then "1"
          else "0";
        ENABLE_BROWSER =
          if (config.services.browser.enable or false)
          then "1"
          else "0";
      };

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = "30s";
        TimeoutStartSec = "60s";
        RuntimeDirectory = "homelab";
        RuntimeDirectoryPreserve = "yes";
      };

      script = builtins.readFile ./config/tailscale-serve.sh;
    };
  };
}
