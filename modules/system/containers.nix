_: {
  flake.nixosModules.containers = {config, ...}: {
    virtualisation = {
      docker.enable = config.var.features.docker;
      waydroid.enable = config.var.features.waydroid;
    };
  };
}
