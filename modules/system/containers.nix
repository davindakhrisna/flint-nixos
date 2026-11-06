_: {
  flake.nixosModules.containers = {
    config,
    lib,
    pkgs,
    ...
  }: {
    virtualisation = {
      docker.enable = config.var.features.docker;
      waydroid = {
        enable = config.var.features.waydroid;
        package = pkgs.waydroid-nftables;
      };
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

    systemd.services = lib.mkMerge [
      (lib.mkIf config.var.features.docker {
        docker = {
          # Slow boot I/O can exceed dockerd's managed-containerd startup timeout.
          unitConfig.StartLimitIntervalSec = 0;
          serviceConfig.RestartSec = "30s";
        };
      })
      (lib.mkIf (config.var.features.docker && config.virtualisation.oci-containers.backend == "docker") (
        lib.mapAttrs' (name: _:
          lib.nameValuePair "docker-${name}" {
            requires = ["docker.service"];
            wantedBy = ["docker.service"];
            partOf = ["docker.service"];
          }) (lib.filterAttrs (_: container: container.autoStart) config.virtualisation.oci-containers.containers)
      ))
      (lib.mkIf config.var.features.waydroid {
        waydroid-container = {
          path = with pkgs; [
            gnused
            gnugrep
            coreutils
            waydroid-nftables
          ];
          preStart = ''
            cfg="/var/lib/waydroid/waydroid.cfg"
            if [ -f "$cfg" ]; then
              igpu_render=""
              for dev in /dev/dri/by-path/*00:02.0*-render; do
                if [ -L "$dev" ]; then
                  igpu_render=$(readlink -f "$dev")
                  break
                fi
              done
              if [ -z "$igpu_render" ]; then
                for uevent in /sys/class/drm/renderD*/device/uevent; do
                  if grep -q -E "DRIVER=(i915|xe|amdgpu)" "$uevent" 2>/dev/null; then
                    igpu_render="/dev/dri/$(basename "$(dirname "$(dirname "$uevent")")")"
                    break
                  fi
                done
              fi

              if [ -n "$igpu_render" ] && [ -e "$igpu_render" ]; then
                if grep -q "^drm_device =" "$cfg"; then
                  sed -i "s|^drm_device =.*|drm_device = $igpu_render|" "$cfg"
                else
                  sed -i "/^\[waydroid\]/a drm_device = $igpu_render" "$cfg"
                fi
                current_prop=$(grep "^gralloc.gbm.device=" /var/lib/waydroid/waydroid_base.prop 2>/dev/null | cut -d= -f2)
                if [ "$current_prop" != "$igpu_render" ]; then
                  waydroid upgrade -o || true
                fi
              fi
            fi
          '';
        };
      })
    ];
  };
}
