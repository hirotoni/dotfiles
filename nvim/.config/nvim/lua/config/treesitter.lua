-- install parsers (on first launch or update)
local ts = require("nvim-treesitter")
ts.install({
  "lua",
  "go",
  "gomod",
  "gosum",
  "javascript",
  "typescript",
  "html",
  "css",
  "json",
  "yaml",
  "dockerfile",
  "bash",
  "markdown",
}, { summary = false }):wait(30000)

-- enable highlighting when a file is opened
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("treesitter-setup", { clear = true }),
  pattern = "*",
  callback = function(ev)
    local lang = ev.match
    -- enable highlighting
    pcall(vim.treesitter.start, ev.buf, lang)
    -- enable the following as needed
    vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    vim.wo[0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
  end,
})

-- auto-update parsers on PackChanged
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    if ev.data.spec.name == "nvim-treesitter" then
      vim.cmd("TSUpdate")
    end
  end,
})
