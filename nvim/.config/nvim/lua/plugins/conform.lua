vim.pack.add({
  { version = "dca1a19", src = "https://github.com/stevearc/conform.nvim" },
})

require("conform").setup({
  -- a formatter added here must also be declared in the dotfiles Brewfile (repo root):
  -- conform silently skips a formatter whose binary is missing, so an undeclared one
  -- surfaces as "saving does nothing" rather than as an error
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
    autocorrect = {
      prepend_args = { "--config", vim.fn.stdpath("config") .. "/.autocorrectrc" },
    },
  },
  -- bashls (plugins/lspconfig.lua) also attaches to zsh and formats through shfmt,
  -- so the lsp fallback would run shfmt on zsh files, which has broken zsh-only
  -- syntax such as $+functions in this repo before
  format_on_save = function(bufnr)
    if vim.bo[bufnr].filetype == "zsh" then
      return
    end
    return {
      timeout_ms = 3000,
      lsp_format = "fallback",
    }
  end,
})
