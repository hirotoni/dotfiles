-- im-select is an optional external tool (Brewfile); without it jobstart()
-- raises E475 on every InsertEnter/InsertLeave, so bail out before wiring
-- the autocmds rather than letting each one fail.
if vim.fn.executable("im-select") == 0 then
  return
end

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
