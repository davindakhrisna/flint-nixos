{
  flake.nixosModules.base = {
    config,
    inputs,
    ...
  }: {
    services.power-profiles-daemon.enable = true;

    programs = {
      nh = {
        enable = true;
        flake = config.var.flakePath;
      };
      zsh.enable = true;
      git.enable = true;
      nix-ld.enable = true;
    };

    environment.sessionVariables = {
      ZDOTDIR = "$HOME/.config/zsh";
      FLINT_DIR = config.var.flakePath;
      NH_FLAKE = config.var.flakePath;
    };

    nixpkgs.config = {
      allowUnfree = true;
      allowBroken = false;
      permittedInsecurePackages = ["electron-40.10.5"];
    };

    nix = {
      nixPath = ["nixpkgs=${inputs.nixpkgs}"];
      channel.enable = false;
      settings = {
        warn-dirty = true;
        download-buffer-size = 262144000;
        auto-optimise-store = true;
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        substituters = [
          "https://nix-community.cachix.org"
          "https://deepseek-harness-nix.cachix.org"
        ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "deepseek-harness-nix.cachix.org-1:5NrkwLN9veNMhiINtU5ZeV4isXFhFsOwn6Ms7J1M+TA="
        ];
      };
      gc = {
        automatic = true;
        persistent = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };
    };

    nixpkgs.overlays = [
      inputs.deepseek-harness.overlays.default
      (final: prev: {
        headroom = final.callPackage ./packages/_headroom.nix {};
        dsh-agy-safe = final.callPackage ./packages/_dsh-agy-safe.nix {};
        dsh = let
          scoped = prev.dsh.overrideScope (_: dshPrev: {
            fetchPnpmDeps = args:
              dshPrev.fetchPnpmDeps (
                args
                // final.lib.optionalAttrs ((args.pname or "") == "dsh-tui") {
                  hash = "sha256-YYocXQVnx6ybKlrBpDvIfdNcCFdRhaPRaV/rBz7IANs=";
                }
              );
          });
          bundles = scoped.bundles.overrideScope (_: bundlesPrev: {
            tui = bundlesPrev.tui.overrideAttrs (_: {
              npmBuildScript = "compile";
            });
            security-audit = bundlesPrev.security-audit.overrideAttrs (oldAttrs: {
              postInstall =
                ''
                  cp -f package.json "$out/lib/node_modules/@deepseek-ai/dsh-security-audit/package.json"
                ''
                + (oldAttrs.postInstall or "");
            });
          });
        in
          scoped
          // {
            inherit bundles;
            dsh = final.lib.makeOverridable (
              args:
                (scoped.dsh.override ({inherit bundles;} // args)).overrideAttrs (oldAttrs: {
                  dshBundleCheckWebProfiles = "nix-web";
                  dshBundleCheckTtyProfiles = "nix-tui";
                  postInstall =
                    (oldAttrs.postInstall or "")
                    + ''
                      if [ -f "$out/lib/deepseek-harness/lib/bin.js" ]; then
                        chmod +w "$out/lib/deepseek-harness/lib/bin.js"
                        sed -i "1i import { HostConnectionService } from '@deepseek-ai/dsh-client-connection'; import { OPENCODE_MODELS } from '@earendil-works/pi-ai/providers/opencode.models'; import { OPENCODE_GO_MODELS } from '@earendil-works/pi-ai/providers/opencode-go.models'; HostConnectionService.prototype.authorizeIndex = () => true; HostConnectionService.prototype.admit = function(r) { if (!this.isTrusted(r)) return { rejection: 403 }; return { peer: this.browserPeer }; }; if (OPENCODE_MODELS && OPENCODE_MODELS['deepseek-v4.1-flash']) { const m = { ...OPENCODE_MODELS['deepseek-v4.1-flash'], id: 'deepseek-v4.1-flash-free', name: 'DeepSeek V4.1 Flash Free', cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 } }; OPENCODE_MODELS['deepseek-v4.1-flash-free'] = m; if (OPENCODE_GO_MODELS) OPENCODE_GO_MODELS['deepseek-v4.1-flash-free'] = m; }" "$out/lib/deepseek-harness/lib/bin.js"
                      fi
                      if grep -q 'dsh-seed-profile' "$out/bin/dsh" 2>/dev/null; then
                        sed -i '/^exec /i export PATH="${oldAttrs.passthru.seedProfiles}/bin:$PATH"\nif [[ "''${1:-}" == "--help" || "''${1:-}" == "-h" || "''${1:-}" == "--version" || "''${1:-}" == "-V" ]]; then dsh-sync-profiles 2>/dev/null || true; exec "$DSH_REAL" "$@"; fi\nif [[ "''${1:-}" == "web" || "''${1:-}" == "tui" ]]; then set -- "nix-$1" "''${@:2}"; fi' "$out/bin/dsh"
                      fi
                    '';
                })
            ) {};
          };
        areofyl-fetch = inputs.areofyl-fetch.packages.${final.stdenv.hostPlatform.system}.default;
        gazelle-tui = inputs.gazelle.packages.${final.stdenv.hostPlatform.system}.default.overrideAttrs (oldAttrs: {
          patches = (oldAttrs.patches or []) ++ [./patches/gazelle-theme.patch];
        });
        hacker-news-tui = inputs.hacker-news-tui.packages.${final.stdenv.hostPlatform.system}.default;
        pomo = inputs.pomo.packages.${final.stdenv.hostPlatform.system}.default;
      })
    ];
  };
}
