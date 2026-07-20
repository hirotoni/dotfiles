require("toggleterm").setup({
  direction = "float",
})

local shell_term = require("utils.float_term").new({})

vim.keymap.set({ "n", "t" }, "<C-`>", function()
  shell_term:toggle()
end)
