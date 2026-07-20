require("core").setup() -- foundational modules (pack bootstrap, options-adjacent behavior)
require("plugins").setup() -- per-package config, one file per package
require("theme").setup() -- colorscheme and palette overrides

vim.opt.mouse = "a"
vim.opt.number = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true

vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.smartindent = true

vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.opt.mousescroll = "ver:1,hor:1"

-- start with all folds open (treesitter foldexpr is set per-buffer in config/treesitter)
vim.opt.foldlevelstart = 99

-- confirm dialog on quit with unsaved changes; the neo-tree QuitPre workaround
-- (config/neotree.lua) depends on this being enabled to detect modified buffers
vim.opt.confirm = true

-- show the file name at the top of each window (winbar) instead of the
-- bottom status line; laststatus=0 hides the bottom bar entirely.
vim.opt.laststatus = 0
vim.opt.winbar = "%f %m"

vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"

vim.opt.undofile = true
vim.opt.clipboard = ""
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    local ev = vim.v.event
    if ev.operator == "y" or ev.operator == "d" or ev.operator == "c" then
      vim.fn.setreg("+", vim.fn.getreg('"'))
    end
  end,
})
vim.opt.updatetime = 250

vim.keymap.set("n", "H", "<cmd>bprev<cr>")
vim.keymap.set("n", "L", "<cmd>bnext<cr>")

-- clear search highlight (the job the default <C-l> also did before we reclaimed it)
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>")

-- Window navigation via <C-hjkl> (shorthand for the default <C-w>hjkl)
-- <C-l> by default redraws the screen and clears search highlight (:nohlsearch); we
-- reclaim it for window movement, and <Esc> above now handles clearing the highlight
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")

vim.diagnostic.config({
  virtual_text = true, -- show errors inline at end of line
  signs = true, -- show icons in the sign column
  underline = true,
  float = {
    border = "rounded",
  },
})
