_: {
  flake.nixosModules.containers = {
    config,
    pkgs,
    ...
  }: {
    virtualisation = {
      docker.enable = config.var.features.docker;
      waydroid.enable = config.var.features.waydroid;
      libvirtd = {
        enable = config.var.features.libvirt;
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = true;
          swtpm.enable = true;
        };
      };
    };

    programs.virt-manager.enable = config.var.features.libvirt;
  };
}
