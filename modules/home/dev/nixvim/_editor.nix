_: {
  programs.nixvim.plugins = {
    treesitter = {
      enable = true;
      settings = {
        highlight.enable = true;
        indent.enable = true;
      };
    };

    comment.enable = true;

    conform-nvim = {
      enable = true;
      settings = {
        format_on_save = {
          timeout_ms = 500;
          lsp_format = "fallback";
        };
        formatters_by_ft = {
          nix = ["alejandra"];
          lua = ["stylua"];
          javascript = ["prettier"];
          typescript = ["prettier"];
          javascriptreact = ["prettier"];
          typescriptreact = ["prettier"];
          json = ["prettier"];
          yaml = ["prettier"];
          css = ["prettier"];
          html = ["prettier"];
          markdown = ["prettier"];
        };
      };
    };

    cmp = {
      enable = true;
      autoEnableSources = true;
      settings = {
        sources = [
          {name = "nvim_lsp";}
          {name = "buffer";}
          {name = "path";}
        ];
        mapping = {
          "<C-Space>" = "cmp.mapping.complete()";
          "<CR>" = "cmp.mapping.confirm({ select = true })";
          "<Tab>" = "cmp.mapping.select_next_item()";
          "<S-Tab>" = "cmp.mapping.select_prev_item()";
          "<C-j>" = "cmp.mapping.select_next_item()";
          "<C-k>" = "cmp.mapping.select_prev_item()";
        };
      };
    };
    luasnip.enable = true;
    friendly-snippets.enable = true;
    lspkind.enable = true;

    lsp = {
      enable = true;
      inlayHints = true;
      servers = {
        nil_ls.enable = true;
        lua_ls.enable = true;
        bashls.enable = true;
        rust_analyzer = {
          enable = true;
          installCargo = false;
          installRustc = false;
        };
        gopls.enable = true;
        pyright.enable = true;
        ts_ls.enable = true;
        html.enable = true;
        cssls.enable = true;
        yamlls.enable = true;
        jsonls.enable = true;
        taplo.enable = true;
      };
    };
  };
}
