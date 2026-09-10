{
  flake.nixosModules.base = {
    config,
    inputs,
    ...
  }: {
    # Retain power-aware operation across laptops and desktops.
    services.power-profiles-daemon.enable = true;

    programs = {
      nh = {
        enable = true;
        flake = config.var.flakePath;
      };
      zsh.enable = true;
      git.enable = true;
    };

    environment.sessionVariables = {
      ZDOTDIR = "$HOME/.config/zsh";
      FLINT_DIR = config.var.flakePath;
      NH_FLAKE = config.var.flakePath;
    };

    nixpkgs.config = {
      allowUnfree = true;
      allowBroken = false;
      # Winboat 0.9.0 cannot rebuild its native argon2 dependency for Electron
      # 41 because its locked electron-rebuild/node-abi stack predates ABI 145.
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
        substituters = ["https://nix-community.cachix.org"];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
      gc = {
        automatic = true;
        persistent = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };
    };

    nixpkgs.overlays = [
      inputs.antigravity-nix.overlays.default
      inputs.opencode.overlays.default
      (final: _: {
        areofyl-fetch = inputs.areofyl-fetch.packages.${final.stdenv.hostPlatform.system}.default;
        gazelle-tui = inputs.gazelle.packages.${final.stdenv.hostPlatform.system}.default;
        hacker-news-tui = inputs.hacker-news-tui.packages.${final.stdenv.hostPlatform.system}.default;
        pomo = inputs.pomo.packages.${final.stdenv.hostPlatform.system}.default;
      })
    ];
  };
}
