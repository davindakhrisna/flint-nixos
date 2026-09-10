_: {
  flake.nixosModules.audio = {
    config,
    lib,
    ...
  }: {
    config = lib.mkIf config.var.features.audio {
      security.rtkit.enable = true;
      services = {
        pulseaudio.enable = false;
        pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          jack.enable = true;
        };
      };
    };
  };
}
