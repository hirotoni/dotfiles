vim.pack.add({
  { version = "81570b9", src = "https://github.com/bullets-vim/bullets.vim" },
})

-- bullets.vim: list continuation (Enter / o, numbered lists, checkboxes)
vim.g.bullets_enabled_file_types = { "markdown" }

-- `gx` is a default mapping (a Lua callback), not a built-in Normal-mode command:
-- `normal! gx` finds no command and silently does nothing, and dropping the `!` re-enters
-- the buffer-local `gx` below until 'maxmapdepth'. nvim_get_keymap returns global mappings
-- only, so resolving the callback through it cannot reach that buffer-local mapping.
local function default_gx()
  for _, map in ipairs(vim.api.nvim_get_keymap("n")) do
    if map.lhs == "gx" and map.callback then
      map.callback()
      return
    end
  end
end

vim.g.bullets_outline_levels = { "std-" }

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.bo.shiftwidth = 2
    vim.bo.softtabstop = 2
    vim.bo.tabstop = 2
    vim.bo.expandtab = true

    vim.keymap.set("n", "]]", function()
      vim.fn.search("^#\\+ ", "W")
    end, { buffer = true, desc = "Next heading" })
    vim.keymap.set("n", "[[", function()
      vim.fn.search("^#\\+ ", "bW")
    end, { buffer = true, desc = "Previous heading" })

    vim.keymap.set("n", "gx", function()
      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- 1-indexed

      local pos = 1
      while true do
        local ms, me, url = line:find("%[.-%]%((.-)%)", pos)
        if not ms then
          break
        end

        if col >= ms and col <= me then
          local path = url:match("^([^#]+)") or url

          if path:match("^https?://") or path:match("^ftps?://") then
            vim.ui.open(url)
            return
          end

          local anchor = url:match("#(.+)$")
          local buf_dir = vim.fn.expand("%:p:h")
          local resolved = vim.fn.resolve(buf_dir .. "/" .. path)
          if vim.fn.filereadable(resolved) == 1 then
            vim.cmd("rightbelow vsplit " .. vim.fn.fnameescape(resolved))
            if anchor then
              -- anchor (e.g. my-section) → search for heading (lines starting with #)
              local pattern = "^#\\+\\s\\+.*" .. anchor:gsub("%-", "[- ]")
              vim.fn.search(pattern, "c")
            end
          else
            vim.notify("File not found: " .. resolved, vim.log.levels.WARN)
          end
          return
        end
        pos = me + 1
      end

      local pos2 = 1
      while true do
        local ms, me, url = line:find("(https?://[^%s%)%]\"']+)", pos2)
        if not ms then
          break
        end
        if col >= ms and col <= me then
          vim.ui.open(url)
          return
        end
        pos2 = me + 1
      end

      default_gx()
    end, { buffer = true, desc = "Open markdown link" })

    -- Wrap the visual selection in a link whose target is the clipboard:
    -- `[selection](clipboard)`. Edits through the buffer API rather than a yank/put
    -- round-trip on purpose: the TextYankPost autocmd in init.lua mirrors every yank
    -- and delete into `+`, so a register detour would overwrite the URL being pasted.
    vim.keymap.set("x", "<leader>ml", function()
      local url = vim.trim(vim.fn.getreg("+"))
      if url == "" then
        vim.notify("Clipboard is empty", vim.log.levels.WARN)
        return
      end
      if url:find("\n") then
        vim.notify("Clipboard holds multiple lines; not a link target", vim.log.levels.WARN)
        return
      end

      local mode = vim.fn.mode()
      if mode ~= "v" and mode ~= "V" then
        vim.notify("Blockwise selection is not supported", vim.log.levels.WARN)
        return
      end

      -- '< and '> are only written when visual mode is left
      vim.cmd("normal! \27")

      local srow, scol = vim.fn.line("'<") - 1, vim.fn.col("'<") - 1
      local erow, ecol = vim.fn.line("'>") - 1, vim.fn.col("'>") - 1

      local last = vim.api.nvim_buf_get_lines(0, erow, erow + 1, true)[1]
      if mode == "V" then
        scol, ecol = 0, #last
      elseif ecol >= #last then
        -- selection ran past the end of the line (e.g. `v$`)
        ecol = #last
      else
        -- '> sits on the first byte of the last character; take the whole character
        ecol = ecol + vim.str_utf_end(last, ecol + 1) + 1
      end

      local text = table.concat(vim.api.nvim_buf_get_text(0, srow, scol, erow, ecol, {}), "\n")
      local link = vim.split("[" .. text .. "](" .. url .. ")", "\n")
      vim.api.nvim_buf_set_text(0, srow, scol, erow, ecol, link)
      vim.api.nvim_win_set_cursor(0, { srow + 1, scol })
    end, { buffer = true, desc = "Wrap selection in a link to the clipboard URL" })

    vim.keymap.set("n", "<leader>mp", function()
      local path = vim.fn.expand("%:p")
      if path == "" then
        vim.notify("No file associated with this buffer", vim.log.levels.WARN)
        return
      end
      if vim.fn.executable("cmux") == 0 then
        vim.notify("cmux command not found", vim.log.levels.ERROR)
        return
      end
      vim.fn.jobstart({ "cmux", "markdown", "open", path, "--direction", "right", "--focus", "false" }, { detach = true })
      vim.notify("cmux markdown: " .. vim.fn.fnamemodify(path, ":t"))
    end, { buffer = true, desc = "Open in cmux markdown viewer" })
  end,
})
