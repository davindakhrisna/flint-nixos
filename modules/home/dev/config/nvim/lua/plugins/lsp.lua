return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = true },
      servers = {
        nil_ls = {},
        lua_ls = {},
        clangd = {},
        bashls = {},
        rust_analyzer = {},
        gopls = {},
        pyright = {},
        ts_ls = {},
        html = {},
        cssls = {},
        yamlls = {},
        jsonls = {},
        taplo = {},
      },
    },
  },
}
