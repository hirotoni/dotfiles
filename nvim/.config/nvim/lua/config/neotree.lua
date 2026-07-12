local sources = { "filesystem", "buffers", "document_symbols" }

-- Delete a buffer from the buffers source without letting Neovim quit.
-- Any window (on any tabpage) showing the buffer is first swapped to another
-- listed buffer (or a fresh empty buffer), so deleting the last buffer never
-- tears down the window and exits Neovim. The delete keeps force=false, so it
-- refuses on modified/busy buffers (E89, E947, ...); on any such failure we
-- restore the swapped windows (including each window's alternate/# buffer) and
-- drop the throwaway buffer, then warn. The whole thing runs synchronously in
-- one keymap callback, so the swap/restore causes no visible flicker.
local function safe_buffer_delete(state)
  local node = state.tree:get_node()
  -- Skip nodes without a real buffer: message nodes, and directory nodes that
  -- appear when buffers nest under paths (they carry no extra.bufnr).
  if not node or node.type == "message" or not node.extra or not node.extra.bufnr then
    return
  end
  local bufnr = node.extra.bufnr
  -- The tree can outlive the buffer (already wiped elsewhere); skip stale nodes.
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  -- Swap every window showing this buffer to a replacement. Only resolve a
  -- replacement when a window actually needs it, to avoid creating an orphan
  -- empty buffer otherwise.
  local wins = vim.fn.win_findbuf(bufnr)
  local created = nil
  local alts = {}
  if #wins > 0 then
    -- Reuse another listed buffer, or create a single empty buffer shared
    -- across every affected window.
    local replacement = nil
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if b ~= bufnr and vim.api.nvim_buf_is_valid(b) and vim.bo[b].buflisted then
        replacement = b
        break
      end
    end
    if not replacement then
      replacement = vim.api.nvim_create_buf(true, false)
      created = replacement
    end
    -- Capture each window's alternate (#) buffer before swapping, so the
    -- failure path can restore it (the swap would otherwise clobber it with
    -- `replacement`, possibly the soon-to-be-deleted throwaway buffer).
    for _, win in ipairs(wins) do
      if vim.api.nvim_win_is_valid(win) then
        alts[win] = vim.api.nvim_win_call(win, function()
          return vim.fn.bufnr("#")
        end)
      end
    end
    for _, win in ipairs(wins) do
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_set_buf(win, replacement)
      end
    end
  end

  local ok, err = pcall(vim.api.nvim_buf_delete, bufnr, { force = false, unload = false })
  if not ok then
    -- Delete refused: restore the windows to the still-valid buffer (and their
    -- original alternate buffer) and drop the throwaway empty buffer so it
    -- doesn't leak, then surface the reason.
    for _, win in ipairs(wins) do
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_set_buf(win, bufnr)
        local a = alts[win]
        if a and a > 0 and a ~= bufnr and vim.api.nvim_buf_is_valid(a) then
          -- Restore the alternate without changing the current buffer or firing
          -- autocmds: switch to `a` (current=a, alt=bufnr), then back to `bufnr`
          -- (current=bufnr, alt=a).
          vim.api.nvim_win_call(win, function()
            vim.cmd("noautocmd keepjumps buffer " .. a)
            vim.cmd("noautocmd keepjumps buffer " .. bufnr)
          end)
        end
      end
    end
    if created and vim.api.nvim_buf_is_valid(created) then
      vim.api.nvim_buf_delete(created, { force = true })
    end
    vim.notify(err, vim.log.levels.WARN)
  end
  require("neo-tree.sources.manager").refresh("buffers")
end

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
  buffers = {
    window = {
      mappings = {
        ["d"] = safe_buffer_delete,
        ["bd"] = safe_buffer_delete,
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
