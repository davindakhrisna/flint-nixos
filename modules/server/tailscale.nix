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
