-- bullets.vim: list continuation (Enter / o, numbered lists, checkboxes)
vim.g.bullets_enabled_file_types = { "markdown" }

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.bo.shiftwidth = 2
    vim.bo.softtabstop = 2
    vim.bo.tabstop = 2
    vim.bo.expandtab = true

    -- jump between headings
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

          -- resolve relative path from the buffer's directory
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

      -- open plain URL (https://... etc.) under cursor
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

      vim.cmd("normal! gx")
    end, { buffer = true, desc = "Open markdown link" })

    -- open current markdown in a separate pane via cmux markdown open
    vim.keymap.set("n", "<leader>mp", function()
      local path = vim.fn.expand("%:p")
      if path == "" then
        vim.notify("No file associated with this buffer", vim.log.level.WARN)
        return
      end
      if vim.fn.executable("cmux") == 0 then
        vim.notify("cmux command not found", vim.log.levels.ERROR)
        return
      end
      vim.fn.jobstart(
        { "cmux", "markdown", "open", path, "--direction", "right", "--focus", "false" },
        { detach = true }
      )
      vim.notify("cmux markdown: " .. vim.fn.fnamemodify(path, ":t"))
    end, { buffer = true, desc = "Open in cmux markdown viewer" })
  end,
})
