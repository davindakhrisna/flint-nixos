{
  flake.nixosModules.system = {self, ...}: {
    imports = with self.nixosModules; [
      options
      base
      boot
      security
      networking
      audio
      containers
      compute
      gaming
      hardware
      desktop
      utils
    ];
  };
}
