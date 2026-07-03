local M = {}

function M.setup()
  vim.pack.add({
    -- UI / Colorscheme
    { rev = "cdc07ac", src = "https://github.com/folke/tokyonight.nvim" },
    -- formatting management
    { rev = "dca1a19", src = "https://github.com/stevearc/conform.nvim" },
    -- Neo-tree
    { rev = "e96fd85", src = "https://github.com/nvim-neo-tree/neo-tree.nvim" },
    { rev = "857c5ac", src = "https://github.com/nvim-lua/plenary.nvim" },
    { rev = "10284fb", src = "https://github.com/nvim-tree/nvim-web-devicons" },
    { rev = "857c5ac", src = "https://github.com/MunifTanjim/nui.nvim" },
    -- multi cursor
    { rev = "a6975e7", src = "https://github.com/mg979/vim-visual-multi" },
    -- lsp
    { rev = "31026a1", src = "https://github.com/neovim/nvim-lspconfig" },
    { rev = "e27096b", src = "https://github.com/williamboman/mason.nvim" },
    { rev = "f75e877", src = "https://github.com/williamboman/mason-lspconfig.nvim" },
    -- trouble
    { rev = "bd67efe", src = "https://github.com/folke/trouble.nvim" },
    -- which key
    { rev = "3aab214", src = "https://github.com/folke/which-key.nvim" },
    -- treesitter
    { rev = "4916d65", src = "https://github.com/nvim-treesitter/nvim-treesitter" },
    -- vim-markdown
    { rev = "1bc9d0c", src = "https://github.com/preservim/vim-markdown" },
    { rev = "12437cd", src = "https://github.com/godlygeek/tabular" },
    -- toggleterm
    { rev = "9a88eae", src = "https://github.com/akinsho/toggleterm.nvim" },
    -- telescope
    { rev = "5063384", src = "https://github.com/nvim-telescope/telescope.nvim" },
    { rev = "74b06c6", src = "https://github.com/nvim-lua/plenary.nvim" },
    { rev = "6fea601", src = "https://github.com/nvim-telescope/telescope-fzf-native.nvim" },
    -- completion
    { rev = "78336bc", src = "https://github.com/Saghen/blink.cmp" },
    { rev = "f29d8ba", src = "https://github.com/Saghen/blink.lib" },
    -- claude code
    { rev = "102d835", src = "https://github.com/coder/claudecode.nvim" },
    -- smooth scroll
    { rev = "c8d2997", src = "https://github.com/karb94/neoscroll.nvim" },
    -- inline image / diagram rendering
    { rev = "44e0712", src = "https://github.com/3rd/image.nvim" },
    { rev = "89d8110", src = "https://github.com/3rd/diagram.nvim" },
    -- pluggable hover (LSP / diagnostics / etc.)
    { rev = "e73c00d", src = "https://github.com/lewis6991/hover.nvim" },
    -- git change  markers / hunk navigation
    { rev = "25050e4", src = "https://github.com/lewis6991/gitsigns.nvim" },
  })

  require("config.neotree")
  require("config.conform")
  require("config.lspconfig")
  require("config.trouble")
  require("config.treesitter")
  require("config.vimmarkdown")
  require("config.toggleterm")
  require("config.telescope")
  require("config.blink")
  require("config.claudecode")
  require("config.lazygit")
  require("config.neoscroll")
  require("config.diagram")
  require("config.visualmulti")
  require("config.hover")
  require("config.gitsigns")
  require("config.githublink")
end

return M
