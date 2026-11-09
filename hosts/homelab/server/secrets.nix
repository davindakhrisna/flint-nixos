_: {
  flake.nixosModules.homelab-secrets = {inputs, ...}: {
    imports = [
      inputs.sops-nix.nixosModules.sops
    ];

    sops = {
      defaultSopsFile = ../secrets.yaml;
      defaultSopsFormat = "yaml";
      age = {
        sshKeyPaths = [
          "/etc/ssh/ssh_host_ed25519_key"
          "/persist/etc/ssh/ssh_host_ed25519_key"
        ];
        keyFile = "/var/lib/sops-nix/key.txt";
      };

      secrets = {
        vaultwarden_env = {
          owner = "vaultwarden";
          mode = "0400";
          restartUnits = ["vaultwarden.service"];
        };

        couchdb_password = {
          owner = "couchdb";
          group = "couchdb";
          mode = "0440";
          restartUnits = [
            "couchdb.service"
            "couchdb-init-databases.service"
          ];
        };

        qbittorrent_webui = {
          owner = "qbittorrent";
          group = "nas";
          mode = "0440";
          restartUnits = ["qbittorrent.service"];
        };

        jackett_api_key = {
          owner = "jackett";
          group = "nas";
          mode = "0440";
          restartUnits = ["jackett.service"];
        };

        user_password = {
          mode = "0400";
        };

        user_password_hash = {
          neededForUsers = true;
        };
      };
    };
  };
}
