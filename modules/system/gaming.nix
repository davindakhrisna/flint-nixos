{
  flake.nixosModules.gaming = {
    config,
    lib,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.var.features.gaming {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = config.var.features.steamRemotePlay;
        dedicatedServer.openFirewall = config.var.features.steamDedicatedServer;
        localNetworkGameTransfers.openFirewall = config.var.features.steamLocalTransfers;

        extraCompatPackages = with pkgs; [
          proton-ge-bin
        ];
      };

      programs.gamemode = {
        enable = true;
        settings = {
          general = {
            renice = 10;
          };
          custom = {
            start = "${pkgs.libnotify}/bin/notify-send 'GameMode' 'GameMode started' -i input-gaming";
            end = "${pkgs.libnotify}/bin/notify-send 'GameMode' 'GameMode ended' -i input-gaming";
          };
        };
      };
    };
  };
}
