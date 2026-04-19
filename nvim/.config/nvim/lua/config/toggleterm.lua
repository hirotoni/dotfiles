require("toggleterm").setup({
  direction = "float",
})

local Terminal = require("toggleterm.terminal").Terminal
local shell_term = Terminal:new({ direction = "float", hidden = true })

vim.keymap.set({ "n", "t" }, "<C-`>", function() shell_term:toggle() end)
