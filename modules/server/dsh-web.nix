_: {
  flake.nixosModules.dsh-web = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.services.dsh-web;
    dshBin =
      if config.home-manager.users ? ${cfg.user}
      then "/etc/profiles/per-user/${cfg.user}/bin/dsh"
      else "${cfg.package}/bin/dsh";
  in {
    options.services.dsh-web = {
      enable = lib.mkEnableOption "DeepSeek Harness Web GUI service";

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.dsh.dsh;
        description = "Fallback package providing the dsh binary.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 3080;
        description = "Port to listen on for the Web GUI.";
      };

      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Bind address for the Web GUI.";
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = "kryisnn";
        description = "User under which the DSH Web service runs.";
      };

      publicUrl = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Advertised public URL behind reverse proxy.";
      };

      trustedHosts = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "homelab.auxois-searobin.ts.net"
          "homelab"
        ];
        description = "Accepted host authorities for the Web GUI.";
      };
    };

    config = lib.mkIf cfg.enable {
      systemd.services.dsh-web = {
        description = "DeepSeek Harness Web GUI";
        after = ["network-online.target" "tailscaled.service"];
        wants = ["network-online.target"];
        wantedBy = ["multi-user.target"];

        environment = {
          HOME = "/home/${cfg.user}";
        };

        path = [
          "/etc/profiles/per-user/${cfg.user}"
          cfg.package
          pkgs.coreutils
          pkgs.bash
          pkgs.headroom
          pkgs.rtk
          pkgs.graphify
        ];

        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          Group = "users";
          WorkingDirectory = "/home/${cfg.user}";
          Restart = "on-failure";
          RestartSec = "10s";

          ExecStartPre = "${dshBin} --version";
          ExecStart = lib.concatStringsSep " " (
            [
              dshBin
              "web"
              "--no-open"
              "--host"
              cfg.host
              "--port"
              (toString cfg.port)
            ]
            ++ lib.optionals (cfg.publicUrl != null) [
              "--public-url"
              cfg.publicUrl
            ]
            ++ lib.concatMap (host: ["--trusted-host" host]) cfg.trustedHosts
          );
        };
      };
    };
  };
}
