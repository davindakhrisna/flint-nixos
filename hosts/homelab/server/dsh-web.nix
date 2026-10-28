_: {
  flake.nixosModules.dsh-web = {
    config,
    lib,
    pkgs,
    ...
  }: let
    dshPkgs = pkgs.callPackage ../../../modules/system/packages/_dsh.nix {};
    cfg = config.services.dsh-web;
    dshBin = "${dshPkgs.dsh}/bin/dsh";
    preStartScript = pkgs.writeShellScript "dsh-web-prestart" ''
      "${dshBin}" --version
    '';
  in {
    options.services.dsh-web = {
      enable = lib.mkEnableOption "DeepSeek Harness Web GUI service";

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
      environment.systemPackages = [
        dshPkgs.dsh
        dshPkgs.dshTui
        dshPkgs.dst
      ];

      systemd.services.dsh-web = {
        description = "DeepSeek Harness Web GUI";
        after = ["network-online.target" "tailscaled.service"];
        wants = ["network-online.target"];
        wantedBy = ["multi-user.target"];

        environment = {
          HOME = "/home/${cfg.user}";
        };

        path = [
          "/home/${cfg.user}/.local/bin"
          "/etc/profiles/per-user/${cfg.user}/bin"
          pkgs.nodejs
          pkgs.pnpm
          pkgs.coreutils
          pkgs.bash
          pkgs.findutils
          pkgs.gnugrep
          pkgs.gnused
          pkgs.git
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
          TimeoutStartSec = "10min";

          ExecStartPre = preStartScript;
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
