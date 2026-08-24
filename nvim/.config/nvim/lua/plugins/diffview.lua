vim.pack.add({
  { version = "4516612", src = "https://github.com/sindrets/diffview.nvim" },
})

require("diffview").setup({

  enhanced_diff_hl = true,
  view = {
    merge_tool = {
      layout = "diff3_mixed",
    },
  },
})

vim.keymap.set("n", "<leader>dv", "<cmd>DiffviewOpen<cr>", { desc = "Diffview: local (incl. untracked)" })
vim.keymap.set("n", "<leader>dc", "<cmd>DiffviewClose<cr>", { desc = "Diffview: close" })
vim.keymap.set("n", "<leader>dh", "<cmd>DiffviewFileHistory %<cr>", { desc = "Diffview: file history" })
vim.keymap.set("n", "<leader>dH", "<cmd>DiffviewFileHistory<cr>", { desc = "Diffview: branch history" })
