vim.pack.add({
  { version = "4916d65", src = "https://github.com/nvim-treesitter/nvim-treesitter" },
})

-- install parsers (on first launch or update)
local ts = require("nvim-treesitter")
local install = ts.install({
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
}, { summary = false })

-- Task:wait raises on timeout, which would abort init.lua before the remaining
-- plugins and the colorscheme load. pwait only stops waiting: the install task
-- keeps running on the event loop and can still be awaited.
local ok, err = install:pwait(30000)
if not ok and err == "timeout" then
  vim.notify(
    "nvim-treesitter: parser install is still running in the background; "
      .. "buffers opened before it finishes need :edit to get highlighting",
    vim.log.levels.WARN
  )
  install:await(function(install_err, all_installed)
    vim.schedule(function()
      if install_err or not all_installed then
        vim.notify("nvim-treesitter: parser install finished with errors; see :TSLog", vim.log.levels.ERROR)
      else
        vim.notify("nvim-treesitter: parser install finished", vim.log.levels.INFO)
      end
    end)
  end)
elseif not ok then
  vim.notify("nvim-treesitter: parser install failed: " .. tostring(err), vim.log.levels.ERROR)
end

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
