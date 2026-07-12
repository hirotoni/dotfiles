local sources = { "filesystem", "buffers", "document_symbols" }

require("neo-tree").setup({
  close_if_last_window = true,
  sources = sources,
  ---@diagnostic disable-next-line: missing-fields
  source_selector = {
    winbar = true,
    sources = vim.tbl_map(function(s)
      return { source = s }
    end, sources),
  },
  filesystem = {
    filtered_items = {
      visible = true, -- show hidden files
      never_show = { "bin" },
    },
    follow_current_file = {
      enabled = true,
    },
  },
  document_symbols = {
    window = {
      mappings = {
        ["<C-r>"] = "noop",
      },
    },
  },
  window = {
    position = "right",
    width = 60,
  },
})

-- workaround: quitting with unsaved buffers causes window reorder that moves neo-tree to the left
-- close neo-tree first on QuitPre to prevent Neovim from rearranging windows
-- reopen neo-tree via CursorMoved if quit was cancelled
vim.opt.confirm = true

local _neo_tree_closed_by_quitpre = false

vim.api.nvim_create_autocmd("QuitPre", {
  callback = function()
    -- no confirm dialog appears when there are no modified buffers, so skip
    local has_modified = false
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.bo[buf].modified and vim.bo[buf].buflisted then
        has_modified = true
        break
      end
    end
    if not has_modified then
      return
    end

    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "neo-tree" then
        vim.api.nvim_win_close(w, true)
        _neo_tree_closed_by_quitpre = true
        break
      end
    end
  end,
})

-- fires only when quit is cancelled (VimLeave comes first on actual quit, so CursorMoved never fires)
vim.api.nvim_create_autocmd({ "CursorMoved", "BufWinEnter" }, {
  callback = function()
    if _neo_tree_closed_by_quitpre then
      _neo_tree_closed_by_quitpre = false
      vim.schedule(function()
        vim.cmd("Neotree show")
      end)
    end
  end,
})

local opt = { noremap = true, silent = true }
-- `last` targets the currently/last shown source, so toggling closes the open
-- window even when a non-filesystem source is visible (plain `toggle` defaults
-- to filesystem and would switch sources instead of closing).
-- `toggle last` fails when source selector switches sources: _last.source diverges
-- from the visible buffer, window_exists returns false, and close never fires.
-- Instead, detect any open neo-tree window by filetype and close all of them.
vim.keymap.set("n", "<C-n>", function()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "neo-tree" then
      vim.cmd("Neotree close")
      return
    end
  end
  vim.cmd("Neotree last")
end, opt)
-- `Neotree <source> focus` has a bug: when a different source is visible,
-- window_exists=false so set_current_win is skipped and async navigate never
-- refocuses. Work around it by injecting the focus into the navigate callback.
local function open_source(source)
  local manager = require("neo-tree.sources.manager")
  local renderer = require("neo-tree.ui.renderer")
  -- Sync _last.source so <C-n> reopen returns to this source.
  require("neo-tree.command")._last.source = source
  local state = manager.get_state(source)
  local focus = function()
    vim.api.nvim_set_current_win(state.winid)
  end
  if renderer.window_exists(state) then
    focus()
  else
    manager.navigate(state, state.path, nil, focus, false)
  end
end

vim.keymap.set("n", "<C-S-n>", function()
  open_source("filesystem")
end, opt)
vim.keymap.set("n", "<C-S-b>", function()
  open_source("buffers")
end, opt)
vim.keymap.set("n", "<C-S-o>", function()
  open_source("document_symbols")
end, opt)
