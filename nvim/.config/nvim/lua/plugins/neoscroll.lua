-- smooth scroll
vim.pack.add({
  { version = "c8d2997", src = "https://github.com/karb94/neoscroll.nvim" },
})

local neoscroll = require("neoscroll")

neoscroll.setup({
  mappings = {
    "<C-u>",
    "<C-d>",
    "<C-b>",
    "<C-f>",
    "<C-y>",
    "<C-e>",
    "zt",
    "zz",
    "zb",
  },
  hide_cursor = true,
  stop_eof = true,
  respect_scrolloff = false,
  cursor_scrolls_alone = true,
  duration_multiplier = 0.6,
  easing = "linear",
  pre_hook = nil,
  post_hook = nil,
  performance_mode = false,
  ignored_events = { "WinScrolled", "CursorMoved" },
})

local keymap = {
  ["<ScrollWheelUp>"] = function()
    neoscroll.scroll(-1, { move_cursor = false, duration = 60, easing = "sine" })
  end,
  ["<ScrollWheelDown>"] = function()
    neoscroll.scroll(1, { move_cursor = false, duration = 60, easing = "sine" })
  end,
}
for key, func in pairs(keymap) do
  vim.keymap.set({ "n", "v", "x" }, key, func)
end
