local sources = { "filesystem", "buffers", "git_status", "document_symbols" }

require("neo-tree").setup({
  close_if_last_window = true,
  sources = sources,
  event_handlers = {
    -- document_symbols: always render fully expanded
    -- nodes are loaded synchronously, so expand_all_nodes works after each render.
    -- redraw() does not re-fire after_render, so this does not loop.
    {
      event = "after_render",
      handler = function(state)
        if state.name == "document_symbols" then
          require("neo-tree.sources.common.commands").expand_all_nodes(state)
        end
      end,
    },
  },
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
vim.keymap.set("n", "<C-n>", ":Neotree toggle last<CR>", opt)
vim.keymap.set("n", "<C-S-n>", ":Neotree focus<CR>", opt)
