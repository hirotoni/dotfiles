vim.pack.add({
  { version = "03eb1f0", src = "https://github.com/nvim-mini/mini.pairs" },
})

-- The "fallback" of blink.cmp's <CR> (plugins/blink.lua) runs the global
-- insert-mode <CR> map that setup() creates here. setup() skips creating it if
-- another <CR> map already exists, which would stop <CR> from splitting pairs.
require("mini.pairs").setup()
