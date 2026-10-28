{
  flake.nixosModules.server = {self, ...}: {
    imports = with self.nixosModules; [
      tailscale-server
      nas
      server-tmpfiles
      services
      dsh-web
      couchdb
      glance
      torrents
      browser
    ];
  };
}
