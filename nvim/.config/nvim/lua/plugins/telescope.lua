-- telescope
vim.pack.add({
  { version = "5063384", src = "https://github.com/nvim-telescope/telescope.nvim" },
  { version = "74b06c6", src = "https://github.com/nvim-lua/plenary.nvim" },
  { version = "6fea601", src = "https://github.com/nvim-telescope/telescope-fzf-native.nvim" },
})

require("telescope").setup({
  defaults = {
    file_ignore_patterns = { ".git/" },
  },
  pickers = {
    find_files = {
      hidden = true,
      no_ignore = true,
      find_command = { "fd", "--type", "f", "--hidden", "--no-ignore", "--exclude", ".git" },
    },
    live_grep = {
      additional_args = function()
        return { "--hidden", "--no-ignore", "--glob", "!.git/*" }
      end,
    },
  },
})

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
vim.keymap.set("n", "<leader>fo", builtin.lsp_document_symbols, { desc = "Telescope lsp document symbols" })
vim.keymap.set("n", "<leader>fe", builtin.diagnostics, { desc = "Telescope diagnostics list" })
