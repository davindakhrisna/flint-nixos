_: {
  flake.nixosModules.containers = {
    config,
    lib,
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

    programs.virt-manager.enable = config.var.features.libvirt && config.var.features.desktop;

    systemd.services = lib.mkIf config.var.features.docker (
      {
        docker = {
          # Slow boot I/O can exceed dockerd's managed-containerd startup timeout.
          unitConfig.StartLimitIntervalSec = 0;
          serviceConfig.RestartSec = "30s";
        };
      }
      // lib.optionalAttrs (config.virtualisation.oci-containers.backend == "docker") (
        lib.mapAttrs' (name: _:
          lib.nameValuePair "docker-${name}" {
            requires = ["docker.service"];
            wantedBy = ["docker.service"];
            partOf = ["docker.service"];
          }) (lib.filterAttrs (_: container: container.autoStart) config.virtualisation.oci-containers.containers)
      )
    );
  };
}
