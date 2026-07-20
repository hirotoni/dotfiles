-- claude code
vim.pack.add({
  { version = "102d835", src = "https://github.com/coder/claudecode.nvim" },
})

require("claudecode").setup({
  -- delegate terminal open/close to toggleterm
  provider = "none",
  diff_opts = {
    keep_terminal_focus = true,
  },
})

-- defer Terminal creation until the server port is resolved on first toggle
local _claude_term = nil
local function claude_term()
  if _claude_term then
    return _claude_term
  end
  local env = { ENABLE_IDE_INTEGRATION = "true", FORCE_CODE_TERMINAL = "true" }
  local ok, server = pcall(require, "claudecode.server.init")
  if ok and server.state and server.state.port then
    env.CLAUDE_CODE_SSE_PORT = tostring(server.state.port)
  end
  _claude_term = require("utils.float_term").new({ cmd = "claude", env = env })
  return _claude_term
end

-- redirect terminal functions called internally by ClaudeCodeSend to claude_term
local ct = require("claudecode.terminal")
ct.open = function()
  claude_term():open()
end
ct.focus = function()
  claude_term():open()
end
ct.ensure_visible = function()
  if not claude_term():is_open() then
    claude_term():open()
  end
end

vim.keymap.set({ "n", "t" }, "<C-=>", function()
  claude_term():toggle()
end, { desc = "Toggle Claude" })
vim.keymap.set("v", "<leader>as", "<cmd>ClaudeCodeSend<cr>", { desc = "Send selection to Claude" })
vim.keymap.set("n", "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", { desc = "Accept diff" })
vim.keymap.set("n", "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", { desc = "Deny diff" })
