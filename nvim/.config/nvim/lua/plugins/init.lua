-- plugins: per-package config, one file per package.
-- Loaded explicitly (not by directory scan) because order is load-bearing:
-- each file declares its own package via vim.pack.add, so a file that requires
-- another plugin's module must run after that plugin's file. Constraints:
--   - blink must run before lspconfig (lspconfig requires blink.cmp).
--   - toggleterm must run before lazygit / claudecode (they build float terminals
--     via utils.float_term, which requires toggleterm.terminal).
-- Deferred modules run vim.pack.add after init.lua has been sourced, where its
-- default is load=true: the package's plugin/ files are sourced right then
-- instead of in the startup plugin pass.
require("plugins.neotree")
require("plugins.conform")
require("plugins.blink")
require("plugins.lspconfig")
require("plugins.glance")
require("plugins.whichkey")
require("plugins.treesitter")
require("plugins.markdown")
require("plugins.toggleterm")
require("plugins.lazygit")
require("plugins.neoscroll")
require("plugins.visualmulti")
require("plugins.hover")
require("plugins.gitsigns")
require("plugins.githublink")
require("plugins.flash")

-- Stubs stand in for the keymaps and commands that the module defines itself,
-- so each lhs and command name here must also be defined by that module. The
-- first stub to fire removes all of them, runs the module, and replays the call
-- on what the module defined in their place.
local function on_demand(module, spec)
  local keys, cmds = spec.keys or {}, spec.cmds or {}
  local loaded = false
  local function load()
    if loaded then
      return
    end
    loaded = true
    for _, key in ipairs(keys) do
      vim.keymap.del("n", key[1])
    end
    for _, name in ipairs(cmds) do
      vim.api.nvim_del_user_command(name)
    end
    require(module)
  end

  for _, key in ipairs(keys) do
    local lhs = key[1]
    vim.keymap.set("n", lhs, function()
      load()
      local map = vim.fn.maparg(lhs, "n", false, true)
      if map.callback then
        map.callback()
      elseif map.rhs then
        vim.api.nvim_feedkeys(vim.keycode(map.rhs), (map.noremap == 1 and "n" or "m") .. "i", false)
      else
        vim.notify(("%s did not define %s"):format(module, lhs), vim.log.levels.ERROR)
      end
    end, { desc = key.desc })
  end

  for _, name in ipairs(cmds) do
    vim.api.nvim_create_user_command(name, function(opts)
      load()
      local range = ""
      if opts.range == 2 then
        range = ("%d,%d"):format(opts.line1, opts.line2)
      elseif opts.range == 1 then
        range = tostring(opts.line1)
      end
      vim.cmd(("%s %s%s%s %s"):format(opts.mods, range, name, opts.bang and "!" or "", opts.args))
    end, {
      nargs = "*",
      bang = true,
      range = true,
      complete = function(_, cmdline)
        load()
        return vim.fn.getcompletion(cmdline, "cmdline")
      end,
    })
  end

  if spec.read then
    vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
      callback = function(args)
        if not loaded and spec.read(args.match) then
          load()
        end
        return loaded
      end,
    })
  end

  if spec.ft then
    vim.api.nvim_create_autocmd("FileType", {
      pattern = spec.ft,
      once = true,
      callback = function(args)
        vim.schedule(function()
          local win = vim.fn.bufwinid(args.buf)
          if win ~= -1 then
            vim.api.nvim_win_call(win, load)
          else
            load()
          end
        end)
      end,
    })
  end
end

on_demand("plugins.telescope", {
  keys = {
    { "<leader>ff", desc = "Telescope find files" },
    { "<leader>fg", desc = "Telescope live grep" },
    { "<leader>fb", desc = "Telescope buffers" },
    { "<leader>fh", desc = "Telescope help tags" },
    { "<leader>fo", desc = "Telescope lsp document symbols" },
    { "<leader>fe", desc = "Telescope diagnostics list" },
  },
  cmds = { "Telescope" },
})

on_demand("plugins.diffview", {
  keys = {
    { "<leader>dl", desc = "Diffview: local (incl. untracked)" },
    { "<leader>dv", desc = "Diffview: PR diff(vs origin/main)" },
    { "<leader>dc", desc = "Diffview: close" },
    { "<leader>dh", desc = "Diffview: file history" },
    { "<leader>dH", desc = "Diffview: branch history" },
  },
  cmds = {
    "DiffviewOpen",
    "DiffviewClose",
    "DiffviewFileHistory",
    "DiffviewFocusFiles",
    "DiffviewToggleFiles",
    "DiffviewRefresh",
    "DiffviewLog",
  },
})

-- Loading before the buffer is read keeps the startup order: diagram.nvim's
-- FileType hook and image.nvim's BufWinEnter hook (it shows image files itself;
-- the extensions are its default hijack_file_patterns) exist before those
-- events fire. Loading later instead makes diagram.nvim's setup() render the
-- current markdown buffer at once and again on the BufWinEnter that follows,
-- so the FileType fallback (markdown without a matching file name) waits until
-- the event is over and runs in a window showing that buffer.
local image_exts = { png = true, jpg = true, jpeg = true, gif = true, webp = true, avif = true }
on_demand("plugins.diagram", {
  read = function(file)
    return vim.filetype.match({ filename = file }) == "markdown" or image_exts[(file:match("%.(%w+)$") or ""):lower()] == true
  end,
  ft = "markdown",
})

-- claudecode's setup() starts the WebSocket server that an external `claude`
-- finds through its lock file (/ide), so it must not wait for a keypress; it
-- only moves past the end of startup.
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.schedule(function()
      require("plugins.claudecode")
    end)
  end,
})
