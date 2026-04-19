require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    go = { "goimports", "gofmt" },
    markdown = { "prettier" },
    sh = { "shfmt" },
    bash = { "shfmt" },
    json = { "prettier" },
    javascript = { "prettier" },
    typescript = { "prettier" },
    vue = { "prettier" },
    css = { "prettier" },
    scss = { "prettier" },
  },
  -- auto-format on save
  format_on_save = {
    timeout_ms = 3000,
    lsp_fallback = true,
  },
})
