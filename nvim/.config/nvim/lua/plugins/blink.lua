-- completion
vim.pack.add({
  { version = "d3874d2", src = "https://github.com/Saghen/blink.cmp" },
  { version = "f29d8ba", src = "https://github.com/Saghen/blink.lib" },
})

require("blink.cmp").setup({
  keymap = {
    preset = "default",
    ["<A-Esc>"] = { "show", "fallback" },
    ["<CR>"] = { "accept", "fallback" },
    ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
    ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
  },
  completion = {
    documentation = { auto_show = true, auto_show_delay_ms = 200 },
    list = { selection = { preselect = false, auto_insert = true } },
    ghost_text = { enabled = true },
  },
  signature = { enabled = true },
  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
  },
  fuzzy = { implementation = "lua" },
})
