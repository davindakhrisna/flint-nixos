_: {
  flake.nixosModules.nas = _: let
    directInterface = "enp1s0f0";
    serverAddress = "192.168.50.1/24";
    sharesPath = "/srv/nas";
  in {
    networking.networkmanager.unmanaged = ["interface-name:${directInterface}"];

    systemd.network = {
      enable = true;
      wait-online.enable = false;
      networks."20-direct-link" = {
        matchConfig.Name = directInterface;
        address = [serverAddress];
        networkConfig = {
          DHCPServer = true;
          LinkLocalAddressing = "no";
          IPv6AcceptRA = false;
          IPv4Forwarding = false;
          IPv6Forwarding = false;
          ConfigureWithoutCarrier = true;
          IgnoreCarrierLoss = true;
        };
        linkConfig.RequiredForOnline = "no";
        dhcpServerConfig = {
          PoolOffset = 100;
          PoolSize = 100;
          EmitRouter = false;
          EmitDNS = false;
          EmitNTP = false;
          EmitSIP = false;
          EmitPOP3 = false;
          EmitSMTP = false;
          EmitLPR = false;
        };
      };
    };

    users.groups.nas.members = ["kryisnn"];

    services = {
      samba = {
        enable = true;
        nmbd.enable = false;
        openFirewall = false;
        settings = {
          global = {
            "workgroup" = "WORKGROUP";
            "server string" = "Homelab NAS";
            "netbios name" = "HOMELAB";
            "security" = "user";
            "interfaces" = "lo ${directInterface}";
            "bind interfaces only" = "yes";
            "hosts allow" = "192.168.50.0/24 127.0.0.1";
            "hosts deny" = "0.0.0.0/0 ::/0";
            "map to guest" = "never";
            "server min protocol" = "SMB2_10";
          };
          nas = {
            "path" = sharesPath;
            "browseable" = "yes";
            "read only" = "no";
            "guest ok" = "no";
            "valid users" = "kryisnn";
            "force group" = "nas";
            "create mask" = "0660";
            "force create mode" = "0660";
            "directory mask" = "2770";
            "force directory mode" = "2770";
            "comment" = "Homelab Shared Storage";
          };
        };
      };

      samba-wsdd = {
        enable = true;
        openFirewall = false;
        interface = directInterface;
      };

      avahi = {
        enable = true;
        allowInterfaces = [directInterface];
        nssmdns4 = true;
        openFirewall = false;
        publish = {
          enable = true;
          userServices = true;
        };
      };
    };

    networking.firewall.interfaces.${directInterface} = {
      allowedTCPPorts = [
        139
        445
        5357
      ];
      allowedUDPPorts = [
        67
        137
        138
        3702
        5353
      ];
    };
  };
}
