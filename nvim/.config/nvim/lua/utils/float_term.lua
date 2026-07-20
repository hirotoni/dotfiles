local M = {}

-- Terminal:new with float/hidden defaults; caller opts override.
function M.new(opts)
  opts = vim.tbl_extend("force", { direction = "float", hidden = true }, opts or {})
  return require("toggleterm.terminal").Terminal:new(opts)
end

return M
