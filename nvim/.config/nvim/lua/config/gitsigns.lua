require("gitsigns").setup({})

vim.keymap.set("n", "<leader>gd", "<cmd>Gitsigns diffthis<CR>", { desc = "Gitsigns: diff current file" })
