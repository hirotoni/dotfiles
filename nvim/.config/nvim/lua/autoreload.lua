local M = {}

function M.setup()
  vim.o.autoread = true

  local group = vim.api.nvim_create_augroup("AutoReload", { clear = true })

  vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
    group = group,
    pattern = "*",
    callback = function()
      if vim.fn.mode():match("[cr!t]") or vim.fn.getcmdwintype() ~= "" then
        return
      end
      vim.cmd("checktime")
    end,
  })

  vim.api.nvim_create_autocmd("FileChangedShellPost", {
    group = group,
    pattern = "*",
    callback = function()
      vim.notify("File changed externally, reloaded.", vim.log.levels.WARN)
    end,
  })
end

return M
