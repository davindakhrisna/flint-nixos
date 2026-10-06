-- Run with: nix shell nixpkgs#glib -c nvim --headless -u NONE -l scripts/test-explorer.lua
-- Uses the real Trash, but removes only this test's own items.
assert(vim.fn.executable("gio") == 1, "gio is required")
local root = vim.fn.tempname()
vim.fn.mkdir(root, "p")
local original_stdpath = vim.fn.stdpath
vim.fn.stdpath = function()
  return root .. "/data"
end
local paths = {}
local picker = {
  cwd = function()
    return root
  end,
  selected = function()
    return vim.tbl_map(function(path)
      return { file = path }
    end, paths)
  end,
  list = { set_selected = function() end },
}
_G.Snacks = {
  picker = {
    util = {
      path = function(item)
        return item.file
      end,
      confirm = function(_, callback)
        callback()
      end,
    },
  },
  notify = { info = function() end, error = function() end },
  bufdelete = function() end,
}
package.loaded["snacks.explorer.tree"] = { refresh = function() end }
package.loaded["snacks.explorer.actions"] = { update = function() end }
local function actions()
  return dofile("modules/home/dev/config/nvim/lua/plugins/explorer.lua")[1].opts.picker.sources.explorer.actions
end
local function gio(args)
  local result = vim.system(vim.list_extend({ "gio" }, args), { text = true }):wait()
  assert(result.code == 0, result.stderr)
  return result.stdout
end
local function history()
  local entries = {}
  for _, manifest in ipairs(vim.fn.glob(root .. "/data/explorer-trash-history/*/manifest.json", false, true)) do
    vim.list_extend(entries, vim.json.decode(table.concat(vim.fn.readfile(manifest), "\n")))
  end
  return entries
end
local ok, err = pcall(function()
  local a = actions()
  vim.fn.mkdir(root .. "/folder", "p")
  vim.fn.writefile({ "directory content" }, root .. "/folder/child")
  vim.fn.writefile({ "original" }, root .. "/file")
  assert(vim.uv.fs_symlink(root .. "/file", root .. "/link"))
  local unusual = root .. "/unicode-雪 space\tand\nnewline"
  vim.fn.writefile({ "unusual filename" }, unusual)
  paths = { root .. "/file", root .. "/folder", root .. "/link", unusual }
  a.explorer_del(picker)
  assert(not vim.uv.fs_lstat(root .. "/file"))
  assert(not vim.uv.fs_lstat(root .. "/folder"))
  assert(#history() == 4, "Every trashed item must have an undo reference")
  for _, entry in ipairs(history()) do
    assert(entry.uri:match("^trash:///"))
    assert(not entry.backup, "History must not contain private backup copies")
  end
  vim.fn.writefile({ "replacement" }, root .. "/file")
  a = actions() -- Recovery history survives loading the config again.
  a.explorer_undo_delete(picker)
  assert(vim.fn.readfile(root .. "/file")[1] == "replacement")
  assert(vim.fn.readfile(root .. "/folder/child")[1] == "directory content")
  assert(vim.uv.fs_lstat(root .. "/link").type == "link")
  assert(vim.fn.readfile(unusual)[1] == "unusual filename")
  vim.fn.delete(root .. "/file")
  a.explorer_undo_delete(picker)
  assert(vim.fn.readfile(root .. "/file")[1] == "original")
  paths = { root .. "/file" }
  a.explorer_del(picker)
  a.explorer_undo_delete(picker)
  a.explorer_undo_delete(picker) -- Empty history is harmless.
  assert(vim.fn.readfile(root .. "/file")[1] == "original")

  a.explorer_del(picker)
  local emptied = history()[1]
  gio({ "remove", "--", emptied.uri }) -- Simulate emptying this test item from Trash.
  assert(not vim.uv.fs_lstat(root .. "/file"))
  a.explorer_undo_delete(picker)
  assert(not vim.uv.fs_lstat(root .. "/file"), "Emptied items must stay deleted")

  -- Trash can reuse a URI after emptying; stale history must not restore the new item.
  vim.fn.writefile({ "old" }, root .. "/file")
  a.explorer_del(picker)
  local stale = history()[1]
  gio({ "remove", "--", stale.uri })
  vim.fn.writefile({ "new" }, root .. "/file")
  gio({ "trash", "--", root .. "/file" })
  a.explorer_undo_delete(picker)
  assert(not vim.uv.fs_lstat(root .. "/file"), "Undo must not restore an unrelated newer item")
  gio({ "trash", "--restore", "--", stale.uri })
  assert(vim.fn.readfile(root .. "/file")[1] == "new")
end)
for _, entry in ipairs(history()) do
  pcall(gio, { "trash", "--restore", "--", entry.uri })
end
vim.fn.stdpath = original_stdpath
vim.fn.delete(root, "rf")
assert(ok, err)
print("Explorer delete/undo checks passed")
