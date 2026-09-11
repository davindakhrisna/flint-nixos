{inputs, ...}: {
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    nixpkgs.source = inputs.nixpkgs;

    globals = {
      mapleader = " ";
      maplocalleader = " ";
      autoformat = true;
    };

    opts = {
      number = true;
      relativenumber = true;
      tabstop = 2;
      shiftwidth = 2;
      softtabstop = 2;
      expandtab = true;
      smartindent = true;
      shiftround = true;
      ignorecase = true;
      smartcase = true;
      cursorline = true;
      termguicolors = true;
      signcolumn = "yes";
      wrap = false;
      scrolloff = 8;
      sidescrolloff = 8;
      splitbelow = true;
      splitright = true;
      mouse = "a";
      clipboard = "unnamedplus";
      undofile = true;
      undolevels = 10000;
      timeoutlen = 300;
      updatetime = 200;
      confirm = true;
    };
  };
}
