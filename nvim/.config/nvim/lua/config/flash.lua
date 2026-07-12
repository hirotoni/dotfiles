local flash = require("flash")

flash.setup({
  -- Show jump labels only after typing the search pattern (easymotion-like).
  labels = "asdfghjklqwertyuiopzxcvbnm",
  modes = {
    -- Enhance the regular `/` and `?` search with flash labels.
    search = {
      enabled = true,
    },
    -- Enhance `f`, `F`, `t`, `T` with multi-line jumps and label continuation.
    char = {
      enabled = true,
    },
  },
})

-- <leader>s: jump anywhere on screen by typing a short pattern, then a label.
-- (Plain `s` is left untouched for its default substitute behavior.)
vim.keymap.set({ "n", "x", "o" }, "<leader>s", function()
  flash.jump()
end, { desc = "Flash jump" })
