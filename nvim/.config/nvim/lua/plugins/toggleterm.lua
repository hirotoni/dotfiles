-- toggleterm
vim.pack.add({
  { version = "9a88eae", src = "https://github.com/akinsho/toggleterm.nvim" },
})

require("toggleterm").setup({
  direction = "float",
})

local shell_term = require("utils.float_term").new({})

vim.keymap.set({ "n", "t" }, "<C-`>", function()
  shell_term:toggle()
end)
