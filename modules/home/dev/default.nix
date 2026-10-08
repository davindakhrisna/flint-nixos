{self, ...}: {
  imports = [
    ./light.nix
    ./medium.nix
    ./heavy.nix
  ];

  flake.homeModules = {
    dev = {lib, ...}: {
      options.dev = lib.mkOption {
        type = lib.types.enum ["light" "medium" "heavy"];
        default = "light";
        description = "Development profile: light CLI tools, medium coding tools, or heavy GUI apps";
      };

      imports = with self.homeModules; [
        dev-light
        dev-medium
        dev-heavy
      ];
    };
  };
}
