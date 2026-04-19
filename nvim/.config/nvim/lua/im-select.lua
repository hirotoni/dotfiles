local M = {}

function M.setup()
  local im_normal = "com.apple.keylayout.ABC"
  local im_insert = im_normal

  local function get_im()
    return vim.fn.system("im-select"):gsub("%s+", "")
  end

  local function set_im(im)
    vim.fn.jobstart({ "im-select", im }, { detach = true })
  end

  vim.api.nvim_create_autocmd("InsertEnter", {
    callback = function()
      set_im(im_insert)
    end,
  })

  vim.api.nvim_create_autocmd("InsertLeave", {
    callback = function()
      im_insert = get_im()
      set_im(im_normal)
    end,
  })
end

return M
