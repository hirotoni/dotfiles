vim.pack.add({
  { version = "cdc07ac", src = "https://github.com/folke/tokyonight.nvim" },
})

require("tokyonight").setup({
  transparent = true,
  on_colors = function(colors)
    colors.comment = "#8b92c0"
  end,
  on_highlights = function(hl, colors)
    hl.LineNr = { fg = colors.dark5 }
  end,
})
vim.cmd("colorscheme tokyonight-night")
