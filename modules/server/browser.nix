_: {
  flake.nixosModules.browser = {
    config,
    pkgs,
    ...
  }: let
    imageName = "lscr.io/linuxserver/firefox";
    firefoxImage = pkgs.dockerTools.pullImage {
      inherit imageName;
      imageDigest = "sha256:f07f3994ada54a77ade524f777a532b7f11c80fdf9af2507dedd02774b40e357";
      sha256 = "sha256-UKOoyTqXc6YTEDQcuYxURaBO5EISm5QXeAeo211PIZ4=";
      finalImageName = imageName;
      finalImageTag = "flint";
    };
    firefoxPolicies = pkgs.writeTextDir "policies.json" (builtins.toJSON {
      policies.DownloadDirectory = "/config/Downloads";
    });
  in {
    virtualisation.oci-containers.containers.firefox = {
      image = "${imageName}:flint";
      imageFile = firefoxImage;
      autoStart = true;
      ports = ["127.0.0.1:3000:3000"];
      environment = {
        PUID = toString config.users.users.kryisnn.uid;
        PGID = "100";
        TZ = "Asia/Jakarta";
        UMASK = "002";
        FILE_MANAGER_PATH = "/config/Downloads";
        SELKIES_ENCODER = "h264enc";
        SELKIES_FRAMERATE = "30,8-30";
      };
      volumes = [
        "/var/lib/headless-browser:/config"
        "/srv/nas/downloads:/config/Downloads"
        "${firefoxPolicies}:/etc/firefox/policies:ro"
      ];
      extraOptions = ["--device=/dev/dri" "--shm-size=1g" "--memory=4g"];
    };
  };
}
