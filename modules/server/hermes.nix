{inputs, ...}: {
  flake.nixosModules.hermes = {pkgs, ...}: {
    imports = [
      inputs.hermes-agent.nixosModules.default
      (import ./config/hermes/_tools.nix {inherit inputs;})
      ./config/hermes/_desktop.nix
    ];

    services.hermes-agent = {
      enable = true;
      environmentFiles = [
        "/var/lib/secrets/hermes-provider.env"
        "/var/lib/secrets/hermes-dashboard.env"
        "/run/homelab/hermes.env"
      ];
      backend.mode = "dashboard";
      backend.port = 9120;
      addToSystemPackages = true;
    };

    systemd.services = {
      "9router" = {
        description = "9Router local model gateway";
        wantedBy = ["multi-user.target"];
        after = ["network-online.target" "home-manager-kryisnn.service"];
        wants = ["network-online.target"];
        unitConfig.ConditionPathExists = "/var/lib/secrets/9router.env";
        path = [pkgs.nodejs];
        environment.HOME = "/home/kryisnn";
        serviceConfig = {
          User = "kryisnn";
          WorkingDirectory = "/home/kryisnn";
          EnvironmentFile = "/var/lib/secrets/9router.env";
          ExecStart = "/home/kryisnn/.local/bin/9router --host 127.0.0.1 --port 20128 --no-browser --skip-update";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };
    };
  };
}
