require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = {
    "lua_ls",
    "gopls",
    "marksman",
    "bashls",
    "jsonls",
  },
})

local capabilities = require("blink.cmp").get_lsp_capabilities()

vim.lsp.config("lua_ls", {
  capabilities = capabilities,
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      },
      diagnostics = { globals = { "vim", "hs" } },
    },
  },
})
vim.lsp.enable("lua_ls")

vim.lsp.config("gopls", {
  capabilities = capabilities,
  settings = {
    gopls = {
      analyses = { unusedparams = true },
      staticcheck = true,
      gofumpt = true,
    },
  },
})
vim.lsp.enable("gopls")

vim.lsp.config("marksman", {
  capabilities = capabilities,
})
vim.lsp.enable("marksman")

vim.lsp.config("bashls", {
  capabilities = capabilities,
  filetypes = { "sh", "bash", "zsh" },
})
vim.lsp.enable("bashls")

vim.lsp.config("jsonls", {
  capabilities = capabilities,
})
vim.lsp.enable("jsonls")

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local opts = { buffer = args.buf }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)

    -- highlight references under cursor
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client:supports_method("textDocument/documentHighlight") then
      local group = vim.api.nvim_create_augroup("lsp-highlight-" .. args.buf, { clear = true })
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        buffer = args.buf,
        group = group,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd("CursorMoved", {
        buffer = args.buf,
        group = group,
        callback = vim.lsp.buf.clear_references,
      })
    end
  end,
})
