require("plugins").setup()
require("vimpack").setup()
require("im-select").setup()
require("autoreload").setup()

require("tokyonight").setup({
  transparent = true,
  on_colors = function(colors)
    colors.comment = "#8b92c0"
  end,
})
vim.cmd("colorscheme tokyonight-night")

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

-- Window navigation via <C-hjkl> (shorthand for the default <C-w>hjkl)
-- <C-l> redraws the screen by default, but :nohlsearch covers that, so we override it
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
