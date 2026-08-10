require("core")
require("plugins")
require("theme")

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

vim.opt.foldlevelstart = 99

-- the neo-tree QuitPre workaround (plugins/neotree.lua) depends on this being
-- enabled to detect modified buffers
vim.opt.confirm = true

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

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>")

-- <C-l> by default redraws the screen and clears search highlight (:nohlsearch); we
-- reclaim it for window movement, and <Esc> above now handles clearing the highlight
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")

vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  float = {
    border = "rounded",
  },
})
