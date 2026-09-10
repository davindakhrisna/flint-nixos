{self, ...}: {
  imports = [
    ./minimal.nix
    ./full.nix
  ];

  flake.homeModules = {
    dev = {lib, ...}: {
      options.dev = lib.mkOption {
        type = lib.types.enum ["minimal" "full"];
        default = "minimal";
        description = "Development workstation profile: minimal or full";
      };

      imports = with self.homeModules; [
        dev-minimal
        dev-full
      ];
    };
  };
}
