-- lsp
vim.pack.add({
  { version = "31026a1", src = "https://github.com/neovim/nvim-lspconfig" },
  { version = "cb8445f", src = "https://github.com/williamboman/mason.nvim" },
  { version = "0c2823e", src = "https://github.com/williamboman/mason-lspconfig.nvim" },
})

require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = {
    "lua_ls",
    "gopls",
    "marksman",
    "bashls",
    "jsonls",
    "terraformls",
    "vue_ls",
    "vtsls",
  },
})

vim.lsp.config("*", {
  capabilities = require("blink.cmp").get_lsp_capabilities(),
})

-- runtime.version / diagnostics.globals / workspace.checkThirdParty below are also
-- declared in .luarc.json (strict JSON, so it can't carry this note). The two have
-- different scopes -- .luarc.json applies to the editing lua_ls (e.g. this repo's own
-- config), this block applies to lua_ls started by nvim -- so keep both in sync.
vim.lsp.config("lua_ls", {
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

vim.lsp.config("gopls", {
  cmd_env = { GOGC = "200", GOMEMLIMIT = "12GiB" },
  settings = {
    gopls = {
      analyses = { unusedparams = true },
      staticcheck = true,
      gofumpt = true,
      diagnosticsDelay = "500ms",
      directoryFilters = { "-**/node_modules", "-**/testdata" },
    },
  },
})

vim.lsp.config("bashls", {
  filetypes = { "sh", "bash", "zsh" },
})

vim.lsp.config("terraformls", {
  filetypes = { "terraform", "terraform-vars", "tf" },
})

vim.lsp.enable({
  "lua_ls",
  "gopls",
  "marksman",
  "bashls",
  "jsonls",
  "terraformls",
  "vtsls",
  "vue_ls",
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local opts = { buffer = args.buf }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gr", "<cmd>Glance references<cr>", opts)
    vim.keymap.set("n", "gi", "<cmd>Glance implementations<cr>", opts)

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
