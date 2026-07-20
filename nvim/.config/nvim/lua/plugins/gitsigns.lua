-- git change markers / hunk navigation
vim.pack.add({
  { version = "2038c66", src = "https://github.com/lewis6991/gitsigns.nvim" },
})

require("gitsigns").setup({})

vim.keymap.set("n", "<leader>gd", "<cmd>Gitsigns diffthis<CR>", { desc = "Gitsigns: diff current file" })
