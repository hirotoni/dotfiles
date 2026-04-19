require("neo-tree").setup({
  close_if_last_window = true,
  filesystem = {
    filtered_items = {
      visible = true, -- show hidden files
    },
    follow_current_file = {
      enabled = true,
    },
  },
  window = {
    position = "right",
    width = 30,
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
vim.keymap.set("n", "<C-n>", ":Neotree toggle<CR>", opt)
vim.keymap.set("n", "<C-S-n>", ":Neotree focus<CR>", opt)
