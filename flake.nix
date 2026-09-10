{
  description = "Flint - Multi-host NixOS Configuration (Dendritic)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    import-tree = {
      url = "github:denful/import-tree";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    areofyl-fetch = {
      url = "github:areofyl/fetch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gazelle = {
      url = "github:Zeus-Deus/gazelle-tui";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hacker-news-tui = {
      url = "github:danfry1/hacker-news-tui";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pomo = {
      url = "github:Bahaaio/pomo";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helium = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    flake-parts,
    import-tree,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} ({lib, ...}: {
      imports = [
        (import-tree ./modules)
        (import-tree ./hosts)
      ];

      options.flake.homeModules = lib.mkOption {
        type = lib.types.lazyAttrsOf lib.types.unspecified;
        default = {};
        description = "Home Manager modules";
      };

      config = {
        systems = ["x86_64-linux"];

        perSystem = {pkgs, ...}: {
          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              alejandra
              nixfmt
              deadnix
              statix
              shellcheck
              lua
              jq
              nix-prefetch-github
            ];
          };
        };
      };
    });
}
