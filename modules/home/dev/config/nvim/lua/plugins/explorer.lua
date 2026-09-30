local function select_visual(picker)
  if vim.fn.mode():find("^[vV]") then
    picker.list:set_selected()
    picker.list:select()
  end
end

return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            actions = {
              explorer_delete_selection = function(picker)
                select_visual(picker)
                picker._flint_cut = nil
                require("snacks.explorer.actions").actions.explorer_del(picker)
              end,
              explorer_cut = function(picker)
                select_visual(picker)
                picker._flint_cut = picker:selected({ fallback = true })
                picker.list:set_selected(picker._flint_cut)
                Snacks.notify.info("Cut " .. #picker._flint_cut .. " files; navigate to the destination and press p")
              end,
              explorer_paste_selection = function(picker)
                local actions = require("snacks.explorer.actions").actions
                if picker._flint_cut and #picker:selected() > 0 then
                  picker.list:set_selected(picker._flint_cut)
                  actions.explorer_move(picker)
                else
                  picker._flint_cut = nil
                  actions.explorer_paste(picker)
                end
              end,
              explorer_yank_selection = function(picker)
                picker._flint_cut = nil
                require("snacks.explorer.actions").actions.explorer_yank(picker)
              end,
            },
            win = {
              list = {
                keys = {
                  ["d"] = { "explorer_delete_selection", mode = { "n", "x" } },
                  ["x"] = { "explorer_cut", mode = { "n", "x" } },
                  ["p"] = "explorer_paste_selection",
                  ["y"] = { "explorer_yank_selection", mode = { "n", "x" } },
                },
              },
            },
          },
        },
      },
    },
  },
}
