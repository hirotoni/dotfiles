local Terminal = require("toggleterm.terminal").Terminal
local lazygit_term = Terminal:new({ cmd = "lazygit", direction = "float", hidden = true })

vim.keymap.set({ "n", "t" }, "<C-g>", function()
  lazygit_term:toggle()
end, { desc = "Toggle lazygit" })
