-- plugins: per-package config, one file per package.
-- Loaded explicitly (not by directory scan) because order is load-bearing:
-- each file declares its own package via vim.pack.add, so a file that requires
-- another plugin's module must run after that plugin's file. Constraints:
--   - blink must run before lspconfig (lspconfig requires blink.cmp).
--   - toggleterm must run before lazygit / claudecode (they build float terminals
--     via utils.float_term, which requires toggleterm.terminal).
local M = {}

function M.setup()
  require("plugins.neotree")
  require("plugins.conform")
  require("plugins.blink")
  require("plugins.lspconfig")
  require("plugins.glance")
  require("plugins.whichkey")
  require("plugins.treesitter")
  require("plugins.markdown")
  require("plugins.toggleterm")
  require("plugins.telescope")
  require("plugins.claudecode")
  require("plugins.lazygit")
  require("plugins.neoscroll")
  require("plugins.diagram")
  require("plugins.visualmulti")
  require("plugins.hover")
  require("plugins.gitsigns")
  require("plugins.githublink")
  require("plugins.flash")
end

return M
