vim.pack.add({
  { version = "4916d65", src = "https://github.com/nvim-treesitter/nvim-treesitter" },
})

-- install parsers (on first launch or update)
local ts = require("nvim-treesitter")
ts.install({
  "lua",
  "go",
  "gomod",
  "gosum",
  "javascript",
  "typescript",
  "tsx",
  "vue",
  "html",
  "css",
  "json",
  "yaml",
  "dockerfile",
  "bash",
  "markdown",
  "terraform",
  "hcl",
}, { summary = false }):wait(30000)

-- nvim-treesitter installs queries/<lang>/ alongside parser/<lang>.so, so a query
-- being present also means its parser is. When that pairing breaks (interrupted
-- install, deleted .so) vim.treesitter.query.get raises, hence the pcall.
local function has_query(lang, name)
  local ok, query = pcall(vim.treesitter.query.get, lang, name)
  return ok and query ~= nil
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("treesitter-setup", { clear = true }),
  pattern = "*",
  callback = function(ev)
    pcall(vim.treesitter.start, ev.buf, ev.match)

    -- a filetype is not always its parser name (sh -> bash, typescriptreact -> tsx);
    -- nvim-treesitter registers the mapping in its plugin/filetypes.lua
    local lang = vim.treesitter.language.get_lang(ev.match)
    if not lang then
      return
    end

    -- only take over where treesitter can do the job: without these queries its
    -- expressions yield nothing, while shadowing the filetype's own indent
    if has_query(lang, "indents") then
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
    if has_query(lang, "folds") then
      vim.wo[0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
      vim.wo[0].foldmethod = "expr"
    end
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
