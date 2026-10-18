-- No setup() call: nvim-surround sets its default keymaps (ys / ds / cs, S in
-- visual mode) from its plugin/ file, and setup() is only needed to change them.
vim.pack.add({
  { version = "8b47db6", src = "https://github.com/kylechui/nvim-surround" },
})
