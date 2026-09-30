{self, ...}: {
  imports = [
    ./minimal.nix
    ./maximal.nix
  ];

  flake.homeModules = {
    dev = {lib, ...}: {
      options.dev = lib.mkOption {
        type = lib.types.enum ["minimal" "maximal"];
        default = "minimal";
        description = "Development workstation profile: minimal or maximal";
      };

      imports = with self.homeModules; [
        dev-minimal
        dev-maximal
      ];
    };
  };
}
