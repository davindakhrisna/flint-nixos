return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
  {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = {
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
      on_highlights = function(hl, _)
        -- Let Kitty provide the background (including opacity and blur)
        hl.Normal = { bg = "NONE" }
        hl.NormalNC = { bg = "NONE" }
        hl.NormalFloat = { bg = "NONE" }
        hl.FloatBorder = { bg = "NONE" }
        hl.SignColumn = { bg = "NONE" }
        hl.FoldColumn = { bg = "NONE" }
        hl.EndOfBuffer = { bg = "NONE" }
        hl.LineNr = { bg = "NONE" }
        hl.CursorLineNr = { bg = "NONE" }
        hl.WinSeparator = { bg = "NONE" }
      end,
    },
  },
}
