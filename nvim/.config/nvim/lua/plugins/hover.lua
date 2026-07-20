-- pluggable hover (LSP / diagnostics / etc.)
vim.pack.add({
  { version = "e73c00d", src = "https://github.com/lewis6991/hover.nvim" },
})

require("hover").setup({
  init = function()
    require("hover.providers.diagnostic")
    require("hover.providers.dap")
    require("hover.providers.lsp")
  end,
  preview_opts = { border = "single" },
  preview_window = false,
  title = true,
})

vim.keymap.set("n", "K", function()
  require("hover").hover()
end, { desc = "hover.nvim (open)" })

vim.keymap.set("n", "gK", function()
  require("hover").enter()
end, { desc = "hover.nvim (enter)" })
