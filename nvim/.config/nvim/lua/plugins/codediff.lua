vim.pack.add({
  { version = "09d9ebe", src = "https://github.com/esmuellert/codediff.nvim" },
})

require("codediff").setup({
  diff = {
    layout = "inline",
  },
  explorer = {
    view_mode = "tree",
  },
  keymaps = {
    view = {
      quit = { "q", "<leader>dc" },
    },
  },
})

vim.keymap.set("n", "<leader>dl", "<cmd>CodeDiff<cr>", { desc = "CodeDiff: local (incl. untracked)" })
vim.keymap.set("n", "<leader>dv", "<cmd>CodeDiff origin/main...HEAD<cr>", { desc = "CodeDiff: PR diff(vs origin/main)" })
vim.keymap.set("n", "<leader>dV", "<cmd>CodeDiff main...HEAD<cr>", { desc = "CodeDiff: branch diff(vs local main)" })
vim.keymap.set("n", "<leader>dh", "<cmd>CodeDiff history %<cr>", { desc = "CodeDiff: file history" })
vim.keymap.set("n", "<leader>dH", "<cmd>CodeDiff history<cr>", { desc = "CodeDiff: branch history" })
