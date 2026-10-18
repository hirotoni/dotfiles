vim.pack.add({
  { version = "31026a1", src = "https://github.com/neovim/nvim-lspconfig" },
  { version = "cb8445f", src = "https://github.com/williamboman/mason.nvim" },
  { version = "0c2823e", src = "https://github.com/williamboman/mason-lspconfig.nvim" },
})

local servers = {
  "lua_ls",
  "gopls",
  "marksman",
  "bashls",
  "jsonls",
  "terraformls",
  "vue_ls",
  "vtsls",
  "yamlls",
  "jsonnet_ls",
  "eslint",
}

require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = servers,
  -- mason-lspconfig v2 defaults automatic_enable to true, which vim.lsp.enable()s every
  -- mason-installed server. Passing `servers` limits that to the declared ones but
  -- keeps its re-enable on install success, which is what attaches buffers opened
  -- before a first-run install finishes.
  automatic_enable = servers,
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
      hints = { parameterNames = true, assignVariableTypes = true },
    },
  },
})

local ts_inlay_hints = { parameterNames = { enabled = "all" } }

-- vue_ls v3 forwards TypeScript requests to vtsls, and only vtsls running
-- @vue/typescript-plugin on .vue buffers answers them (types, parameter-name
-- hints). The plugin ships inside mason's vue-language-server package.
vim.lsp.config("vtsls", {
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
  settings = {
    typescript = { inlayHints = ts_inlay_hints },
    javascript = { inlayHints = ts_inlay_hints },
    vtsls = {
      tsserver = {
        globalPlugins = {
          {
            name = "@vue/typescript-plugin",
            location = vim.fn.stdpath("data") .. "/mason/packages/vue-language-server/node_modules/@vue/language-server",
            languages = { "vue" },
            configNamespace = "typescript",
          },
        },
      },
    },
  },
})

vim.lsp.config("bashls", {
  filetypes = { "sh", "bash", "zsh" },
})

vim.lsp.config("terraformls", {
  filetypes = { "terraform", "terraform-vars", "tf" },
})

vim.lsp.enable(servers)

-- Enabled globally rather than per buffer on LspAttach: a .vue buffer gets
-- vtsls and vue_ls attached one after the other, and a per-attach enable would
-- undo a toggle-off made in between.
vim.lsp.inlay_hint.enable(true)

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local opts = { buffer = args.buf }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "grr", "<cmd>Glance references<cr>", opts)
    vim.keymap.set("n", "gi", "<cmd>Glance implementations<cr>", opts)
    vim.keymap.set("n", "gri", "<cmd>Glance implementations<cr>", opts)
    vim.keymap.set("n", "<leader>uh", function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
    end, { buffer = args.buf, desc = "LSP: toggle inlay hints (buffer)" })

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
