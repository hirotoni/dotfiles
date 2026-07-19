require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    go = { "goimports", "gofmt" },
    markdown = { "prettier", "autocorrect" },
    sh = { "shfmt" },
    bash = { "shfmt" },
    json = { "prettier" },
    javascript = { "prettier" },
    typescript = { "prettier" },
    vue = { "prettier" },
    css = { "prettier" },
    scss = { "prettier" },
  },
  formatters = {
    -- insert spaces between CJK and Latin/numbers; rules tuned in .autocorrectrc
    autocorrect = {
      prepend_args = { "--config", vim.fn.stdpath("config") .. "/.autocorrectrc" },
    },
  },
  -- auto-format on save
  format_on_save = {
    timeout_ms = 3000,
    lsp_fallback = true,
  },
})
