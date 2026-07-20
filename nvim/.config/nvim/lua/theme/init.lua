-- theme: colorscheme and palette overrides.

-- UI / Colorscheme
vim.pack.add({
  { version = "cdc07ac", src = "https://github.com/folke/tokyonight.nvim" },
})

require("tokyonight").setup({
  transparent = true,
  on_colors = function(colors)
    colors.comment = "#8b92c0"
  end,
})
vim.cmd("colorscheme tokyonight-night")
