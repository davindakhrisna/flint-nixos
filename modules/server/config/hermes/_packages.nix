{
  inputs,
  hermes,
  lib,
  pkgs,
}: let
  headroom = pkgs.callPackage ../../../system/packages/_headroom.nix {};
  tiktokenCache = pkgs.runCommandLocal "tiktoken-o200k-base-cache" {} ''
    mkdir -p "$out"
    ln -s ${pkgs.fetchurl {
      url = "https://huggingface.co/baseten/o200k-base-tiktoken/resolve/64365eed65a7d76989528cb3f3571b423518ab57/o200k_base.tiktoken";
      hash = "sha256-RGqVOMtsNI41FhINfAiwn1fDZJXirP/+WaW/iwz7Gi0=";
    }} "$out/fb374d419588a4632f3f557e76b4b70aebbca790"
  '';
  cuaDriver = pkgs.callPackage ./_cua-driver.nix {};
  localExtract = pkgs.runCommand "web-local-extract" {} ''
    mkdir -p "$out"
    cp ${../web-local-extract}/* "$out/"
  '';
  codexDelegate = pkgs.writeShellApplication {
    name = "flint-hermes-codex";
    runtimeInputs = [pkgs.coreutils pkgs.nodejs];
    text =
      ''
        export FLINT_HERMES_WORKSPACE=${lib.escapeShellArg hermes.workingDirectory}
      ''
      + builtins.readFile ./delegate-codex.sh;
  };
  serveProject = pkgs.writeShellApplication {
    name = "flint-hermes-serve";
    runtimeInputs = [pkgs.tailscale pkgs.jq pkgs.util-linux];
    text = builtins.readFile ./serve-project.sh;
  };
  bridgeSource = inputs.hermes-agent + "/scripts/whatsapp-bridge";
  pairWhatsApp = pkgs.writeShellApplication {
    name = "flint-hermes-whatsapp-pair";
    runtimeInputs = [hermes.package.hermesVenv hermes.package.hermesNpmLib.nodejs];
    text = ''
      export HERMES_HOME=${lib.escapeShellArg "${hermes.stateDir}/.hermes"}
      export HERMES_NODE=${lib.getExe hermes.package.hermesNpmLib.nodejs}
      exec python3 ${./pair-hermes-whatsapp.py}
    '';
  };
  liveCheck = pkgs.writeShellApplication {
    name = "flint-hermes-check";
    runtimeInputs = [hermes.package.hermesVenv pkgs.systemd];
    text = ''
      export HERMES_HOME=${lib.escapeShellArg "${hermes.stateDir}/.hermes"}
      exec python3 ${./live-check.py} "$@"
    '';
  };
  bridgeFiles = lib.mapAttrs' (name: _: lib.nameValuePair "scripts/whatsapp-bridge/${name}" (builtins.readFile "${bridgeSource}/${name}")) (
    lib.filterAttrs (name: type: type == "regular" && (lib.hasSuffix ".js" name || builtins.elem name ["package.json" "package-lock.json"])) (builtins.readDir bridgeSource)
  );
in {
  inherit headroom tiktokenCache cuaDriver localExtract codexDelegate serveProject pairWhatsApp liveCheck bridgeFiles;
}
