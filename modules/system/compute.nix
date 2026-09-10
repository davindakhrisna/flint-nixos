_: {
  flake.nixosModules.compute = {
    config,
    pkgs,
    ...
  }: {
    services.ollama = {
      enable = config.var.features.ollama;
      package =
        if config.var.gpu == "nvidia"
        then pkgs.ollama-cuda
        else if config.var.gpu == "amd"
        then pkgs.ollama-rocm
        else pkgs.ollama;
    };
  };
}
