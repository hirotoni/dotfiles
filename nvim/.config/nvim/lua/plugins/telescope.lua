vim.pack.add({
  { version = "5063384", src = "https://github.com/nvim-telescope/telescope.nvim" },
  -- plenary is a shared dependency declared in plugins/neotree.lua (loads first);
  -- vim.pack has already added it to the runtimepath by the time this file runs.
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
      find_command = { "fd", "--type", "f", "--hidden", "--no-ignore", "--exclude", ".git", "--exclude", "bin" },
    },
    live_grep = {
      additional_args = function()
        return { "--hidden", "--no-ignore", "--glob", "!.git/*", "--glob", "!**/bin/**" }
      end,
    },
  },
})

-- The PackChanged hook in plugins/init.lua only fires on install/update, so a
-- copy installed before it existed is built here on first use.
local fzf_native = require("utils.fzf_native")
local fzf_pack = vim.pack.get({ fzf_native.name }, { info = false })[1]
if fzf_pack and fzf_native.ensure(fzf_pack.path) then
  require("telescope").load_extension("fzf")
end

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
vim.keymap.set("n", "<leader>fo", builtin.lsp_document_symbols, { desc = "Telescope lsp document symbols" })
vim.keymap.set("n", "<leader>fe", builtin.diagnostics, { desc = "Telescope diagnostics list" })
