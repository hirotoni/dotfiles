local lazygit_term = require("utils.float_term").new({ cmd = "lazygit" })

vim.keymap.set({ "n", "t" }, "<C-g>", function()
  lazygit_term:toggle()
end, { desc = "Toggle lazygit" })
