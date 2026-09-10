_: {
  flake.nixosModules.networking = {config, ...}: {
    networking = {
      nameservers = [
        "9.9.9.9"
        "149.112.112.112"
      ];
      networkmanager = {
        enable = true;
        dns = "systemd-resolved";
        wifi.backend = "wpa_supplicant";
      };
    };

    services = {
      tailscale.enable = config.var.features.tailscale;
      resolved = {
        enable = true;
        settings.Resolve = {
          DNS = "9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net";
          FallbackDNS = "2620:fe::fe#dns.quad9.net 2620:fe::9#dns.quad9.net";
          DNSOverTLS = true;
          DNSSEC = true;
        };
      };
    };
  };
}
