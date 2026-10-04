{
  inputs,
  lib,
  pkgs,
}: let
  upstream = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
  pythonSource = pkgs.applyPatches {
    name = "hermes-python-nix-node";
    src = upstream.hermesNpmLib.pythonSrc;
    patches = [./nix-node.patch];
  };
in
  upstream.override {
    callPackage = path: args:
      pkgs.callPackage path (args
        // lib.optionalAttrs (builtins.baseNameOf path == "python.nix") {
          pythonSrc = pythonSource;
        });
  }
