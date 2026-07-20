-- core: foundational modules (not per-plugin config), set up in explicit order.
local M = {}

function M.setup()
  require("core.vimpack").setup()
  require("core.im-select").setup()
  require("core.autoreload").setup()
end

return M
