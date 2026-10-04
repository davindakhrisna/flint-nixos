_: {
  flake.nixosModules.couchdb = {
    pkgs,
    lib,
    ...
  }: let
    adminPasswordFile = "/var/lib/secrets/obsidian-sync-admin-password";
    adminUser = "admin";
    syncUser = "kryisnn";
    prepare = pkgs.writeShellScript "prepare-couchdb" (builtins.readFile ./config/couchdb/prepare-couchdb.sh);
    initDatabases = pkgs.writeShellScript "init-couchdb-databases" (builtins.readFile ./config/couchdb/init-couchdb-databases.sh);
  in {
    services.couchdb = {
      enable = true;
      bindAddress = "127.0.0.1";
      port = 5984;
      inherit adminUser;
      extraConfigFiles = ["/run/couchdb-admin/admin.ini"];

      extraConfig = {
        couchdb = {
          single_node = true;
          max_document_size = 50000000;
        };
        chttpd = {
          require_valid_user = true;
          require_valid_user_except_for_up = true;
          max_http_request_size = 4294967296;
          enable_cors = true;
        };
        chttpd_auth = {
          require_valid_user = true;
          authentication_redirect = "/_utils/session.html";
        };
        httpd = {
          WWW-Authenticate = ''Basic realm="couchdb"'';
          enable_cors = true;
        };
        cors = {
          origins = "app://obsidian.md, capacitor://localhost, http://localhost";
          credentials = true;
          headers = "accept, authorization, content-type, origin, referer, x-requested-with";
          methods = "GET,PUT,POST,HEAD,DELETE";
          max_age = 3600;
        };
      };
    };

    systemd.services = {
      couchdb = {
        path = [pkgs.coreutils pkgs.gnused];
        unitConfig.ConditionFileNotEmpty = adminPasswordFile;
        serviceConfig = {
          RuntimeDirectory = "couchdb-admin";
          RuntimeDirectoryMode = "0700";
        };
        preStart = lib.mkAfter ''
          ${prepare} ${lib.escapeShellArgs [adminPasswordFile adminUser syncUser]}
        '';
      };

      couchdb-init-databases = {
        description = "Initialize CouchDB system and Obsidian Sync databases";
        wantedBy = ["multi-user.target"];
        after = ["couchdb.service"];
        requires = ["couchdb.service"];
        unitConfig.ConditionFileNotEmpty = adminPasswordFile;
        path = [pkgs.coreutils pkgs.curl];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          Restart = "on-failure";
          RestartSec = "5s";
        };
        script = ''
          ${initDatabases} ${lib.escapeShellArgs [adminPasswordFile adminUser]}
        '';
      };
    };
  };
}
