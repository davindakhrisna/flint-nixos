{
  config,
  lib,
  pkgs,
  ...
}: let
  hermes = config.services.hermes-agent;
in {
  systemd.services =
    {
      hermes-desktop = {
        description = "Private local desktop for Hermes computer control";
        path = [pkgs.xauth pkgs.xorg-server pkgs.xdpyinfo pkgs.openbox pkgs.openssl pkgs.systemd];
        environment = {
          DISPLAY = ":99";
          XAUTHORITY = "/run/hermes-desktop/Xauthority";
          HOME = hermes.stateDir;
          XDG_DATA_DIRS = "${pkgs.at-spi2-core}/share:/run/current-system/sw/share";
        };
        serviceConfig = {
          Type = "notify";
          NotifyAccess = "all";
          User = hermes.user;
          Group = hermes.group;
          RuntimeDirectory = "hermes-desktop";
          RuntimeDirectoryMode = "0700";
          Restart = "on-failure";
        };
        after = ["linger-users.service"];
        wants = ["linger-users.service"];
        script = builtins.readFile ./desktop.sh;
      };
    }
    // lib.genAttrs ["hermes-agent" "hermes-backend"] (_: {
      after = ["9router.service" "searx.service" "hermes-desktop.service"];
      wants = ["9router.service" "searx.service" "hermes-desktop.service"];
      environment.XDG_DATA_DIRS = "${pkgs.at-spi2-core}/share:/run/current-system/sw/share";
      serviceConfig = {
        # Share the authenticated X socket and permit only the sudo wrappers above.
        PrivateTmp = lib.mkForce false;
        NoNewPrivileges = lib.mkForce false;
        ReadWritePaths = ["/home/kryisnn/.codex"];
      };
    });
}
