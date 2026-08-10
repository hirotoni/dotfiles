-- easymotion-style jump / search
vim.pack.add({
  { version = "b634694", src = "https://github.com/folke/flash.nvim" },
})

local flash = require("flash")

flash.setup({
  labels = "asdfghjklqwertyuiopzxcvbnm",
  modes = {
    search = {
      enabled = true,
    },
    char = {
      enabled = true,
    },
  },
})

-- Plain `s` is left untouched for its default substitute behavior.
vim.keymap.set({ "n", "x", "o" }, "<leader>s", function()
  flash.jump()
end, { desc = "Flash jump" })
