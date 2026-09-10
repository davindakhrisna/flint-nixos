{
  flake.nixosModules.utils = {
    config,
    lib,
    pkgs,
    ...
  }: {
    # Desktop packages
    programs.chromium.enable = lib.mkIf config.var.features.desktop true;

    environment.systemPackages = with pkgs; [
      # Development Tools
      htop
      nix-index
      unzip

      # Utilities
      wget
      tmux
      psmisc # provides killall, pstree, fuser
    ];
  };
}
