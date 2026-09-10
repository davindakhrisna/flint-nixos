_: {
  flake.nixosModules.security = {
    config,
    pkgs,
    ...
  }: {
    boot.kernel.sysctl = {
      "kernel.kptr_restrict" = 2;
      "kernel.dmesg_restrict" = 1;
      "kernel.perf_event_paranoid" =
        if config.var.features.developerKernelAccess
        then 1
        else 3;
      "kernel.yama.ptrace_scope" =
        if config.var.features.developerKernelAccess
        then 1
        else 2;
      "net.ipv4.tcp_syncookies" = 1;
      "net.ipv4.conf.all.rp_filter" = 2;
      "net.ipv4.conf.default.rp_filter" = 2;
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "fs.protected_hardlinks" = 1;
      "fs.protected_symlinks" = 1;
      "fs.suid_dumpable" = 0;
    };

    systemd = {
      services.vulnix = {
        description = "Vulnix CVE scan";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.vulnix}/bin/vulnix --system";
          Nice = 20;
          IOSchedulingClass = "idle";
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectHome = true;
          ProtectSystem = "strict";
        };
      };
      timers.vulnix = {
        description = "Weekly Vulnix CVE scan";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "weekly";
          Persistent = true;
          RandomizedDelaySec = "2h";
        };
      };
    };
  };
}
