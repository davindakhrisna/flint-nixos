local function select_visual(picker)
  if vim.fn.mode():find("^[vV]") then
    picker.list:set_selected()
    picker.list:select()
  end
end

-- Only undo metadata lives here; deleted contents live in the system Trash.
local function recovery_root()
  return vim.fn.stdpath("data") .. "/explorer-trash-history"
end

local function gio(args)
  local result = vim.system(vim.list_extend({ "gio" }, args), { text = true, env = { LC_ALL = "C" } }):wait()
  if result.code ~= 0 then
    error(vim.trim(result.stderr or "GIO failed"))
  end
  return result.stdout or ""
end

local function trash_items()
  local output = gio({ "trash", "--list" })
  local items = {}
  for uri in output:gmatch("(trash://[^\t\n]+)\t") do
    items[uri] = true
  end
  return items, output
end

local function identity(uri)
  return vim.fn.sha256(gio({
    "info",
    "-n",
    "-a",
    "id::file,unix::inode,time::changed,time::changed-usec,trash::deletion-date,trash::orig-path",
    "--",
    uri,
  }))
end

local function refresh(picker)
  require("snacks.explorer.tree"):refresh(picker:cwd())
  picker.list:set_selected()
  require("snacks.explorer.actions").update(picker, { refresh = true })
end

local function delete_selection(picker)
  if vim.fn.executable("gio") == 0 then
    Snacks.notify.error("GIO is required for recoverable deletion; apply the updated Nix configuration")
    return
  end
  select_visual(picker)
  picker._flint_cut = nil
  local paths = vim.tbl_map(Snacks.picker.util.path, picker:selected({ fallback = true }))
  if #paths == 0 then
    return
  end
  Snacks.picker.util.confirm("Move " .. #paths .. " item(s) to Trash?", function()
    local batch = recovery_root() .. "/" .. os.date("!%Y%m%d%H%M%S") .. string.format("-%020.0f", vim.uv.hrtime())
    vim.fn.mkdir(batch, "p", 448)
    local entries = {}
    local manifest = batch .. "/manifest.json"
    local function save()
      vim.fn.writefile({ vim.json.encode(entries) }, manifest)
    end
    local ok, err = pcall(save)
    if not ok then
      Snacks.notify.error("Cannot save undo history: " .. tostring(err))
      return
    end
    for _, path in ipairs(paths) do
      local entry = { original = path }
      local modified = false
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(buf)
        if
          (name == entry.original or name:sub(1, #entry.original + 1) == entry.original .. "/")
          and vim.bo[buf].modified
        then
          modified = true
        end
      end
      if modified then
        Snacks.notify.error("Save unsaved buffers before deleting " .. entry.original)
      else
        local trashed, trash_err = pcall(function()
          local before = trash_items()
          gio({ "trash", "--", path })
          local after, output = trash_items()
          for uri in pairs(after) do
            if not before[uri] and output:find(uri .. "\t" .. path .. "\n", 1, true) then
              entry.uri = uri
              entry.identity = identity(uri)
              entries[#entries + 1] = entry
              save()
              break
            end
          end
          if not entry.uri then
            error("File is in Trash, but undo tracking failed; restore it from your file manager")
          end
          Snacks.bufdelete({ file = path, force = true })
        end)
        if not trashed then
          Snacks.notify.error("Trash operation for " .. path .. ": " .. tostring(trash_err))
        end
      end
    end
    refresh(picker)
  end)
end

local function undo_delete(picker)
  local listed, items = pcall(trash_items)
  if not listed then
    Snacks.notify.error("Cannot access Trash: " .. tostring(items))
    return
  end
  local manifests = vim.fn.glob(recovery_root() .. "/*/manifest.json", false, true)
  table.sort(manifests, function(a, b)
    return a > b
  end)
  for _, manifest in ipairs(manifests) do
    local ok, entries = pcall(function()
      return vim.json.decode(table.concat(vim.fn.readfile(manifest), "\n"))
    end)
    if not ok then
      Snacks.notify.error("Cannot read recovery history: " .. manifest)
      return
    end
    local restored, pending = 0, false
    for _, entry in ipairs(entries) do
      if items[entry.uri] then
        local checked, current = pcall(identity, entry.uri)
        if not checked then
          pending = true
          Snacks.notify.error("Cannot inspect Trash item: " .. tostring(current))
        elseif current == entry.identity then
          local moved, err = pcall(gio, { "trash", "--restore", "--", entry.uri })
          if moved then
            restored = restored + 1
          else
            pending = true
            Snacks.notify.error("Cannot restore " .. entry.original .. ": " .. tostring(err))
          end
        end
        -- Missing/replaced items were emptied or restored outside Neovim.
      end
    end
    if not pending then
      vim.fn.delete(vim.fs.dirname(manifest), "rf")
    end
    if restored > 0 or pending then
      refresh(picker)
      if restored > 0 then
        Snacks.notify.info("Restored " .. restored .. " item(s)")
      end
      return
    end
  end
  Snacks.notify.info("No deleted files to restore")
end

return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            actions = {
              explorer_del = delete_selection,
              explorer_delete_selection = delete_selection,
              explorer_undo_delete = undo_delete,
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
                  ["<C-u>"] = "explorer_undo_delete",
                  ["<C-z>"] = "explorer_undo_delete",
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
