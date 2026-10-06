{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf (builtins.elem config.dev ["minimal" "maximal"]) {
    home.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      withNodeJs = true;
      withPython3 = true;
      withRuby = false;

      extraPackages = with pkgs; [
        # Core LazyVim tools
        git
        glib # gio: system Trash and safe restore for the file explorer
        gcc
        gnumake
        ripgrep
        fd
        unzip
        curl
        wl-clipboard
        xclip
        tree-sitter

        # Language Servers
        nil # Nix LSP
        lua-language-server
        clang-tools # clangd, clang-format
        bash-language-server
        gopls
        pyright
        rust-analyzer
        taplo
        yaml-language-server
        vscode-langservers-extracted # html, css, json
        typescript-language-server

        # Formatters & Linters
        alejandra # Nix formatter
        stylua # Lua formatter
        prettier
      ];
    };

    xdg.configFile."nvim" = {
      source = ./config/nvim;
      recursive = true;
      force = true;
    };
  };
}
