vim.pack.add({
  { version = "f6230a5", src = "https://github.com/mfussenegger/nvim-lint" },
})

local lint = require("lint")

-- a linter added here must also be declared in the dotfiles Brewfile (repo root),
-- like the formatters in plugins/conform.lua
lint.linters_by_ft = {
  dockerfile = { "hadolint" },
}

-- nvim has no filetype of its own for GitHub Actions workflows (they are plain
-- yaml), so actionlint is picked by path instead of through linters_by_ft
local function linters_for(bufnr)
  local names = vim.list_extend({}, lint.linters_by_ft[vim.bo[bufnr].filetype] or {})
  if vim.bo[bufnr].filetype == "yaml" and vim.api.nvim_buf_get_name(bufnr):match("/%.github/workflows/[^/]+%.ya?ml$") then
    table.insert(names, "actionlint")
  end
  return names
end

vim.api.nvim_create_autocmd({ "FileType", "BufWritePost" }, {
  group = vim.api.nvim_create_augroup("lint", { clear = true }),
  callback = function(args)
    local names = linters_for(args.buf)
    if #names > 0 then
      vim.api.nvim_buf_call(args.buf, function()
        lint.try_lint(names)
      end)
    end
  end,
})
