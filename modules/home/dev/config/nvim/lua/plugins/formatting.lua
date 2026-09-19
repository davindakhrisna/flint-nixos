return {
  {
    "stevearc/conform.nvim",
    opts = {
      default_format_opts = {
        timeout_ms = 3000,
        async = false,
        quiet = false,
        lsp_format = "fallback",
      },
      formatters_by_ft = {
        c = { "clang_format" },
        cpp = { "clang_format" },
        nix = { "alejandra" },
        lua = { "stylua" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        markdown = { "prettier" },
      },
    },
  },
}
