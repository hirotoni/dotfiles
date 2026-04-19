require("trouble").setup({
  focus = true,
  keys = {
    ["<cr>"] = "jump_close",
  },
  modes = {
    lsp_implementations = {
      win = { position = "bottom", size = 0.3 },
    },
    lsp_references = {
      win = { position = "bottom", size = 0.3 },
    },
  },
})
