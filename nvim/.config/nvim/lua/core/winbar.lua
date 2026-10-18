local M = {}

local MAX_PROGRESS_WIDTH = 50

local progress = {}
local seq = 0

local function escape(s)
  return (s:gsub("%%", "%%%%"))
end

local function truncate(s, width)
  if vim.fn.strdisplaywidth(s) <= width then
    return s
  end
  return vim.fn.strcharpart(s, 0, width - 1) .. "…"
end

local function lsp_progress(buf)
  local parts = {}
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
    local latest
    for _, item in pairs(progress[client.id] or {}) do
      if not latest or item.seq > latest.seq then
        latest = item
      end
    end
    if latest then
      local text = client.name .. ": " .. latest.title
      if latest.message then
        text = text .. " " .. latest.message
      end
      if latest.percentage then
        text = text .. (" %d%%"):format(latest.percentage)
      end
      table.insert(parts, "%#DiagnosticInfo#" .. escape(truncate(text, MAX_PROGRESS_WIDTH)) .. "%*")
    end
  end
  return table.concat(parts, " ")
end

local function diagnostics(buf)
  local count = vim.diagnostic.count(buf)
  local parts = {}
  local errors = count[vim.diagnostic.severity.ERROR] or 0
  local warns = count[vim.diagnostic.severity.WARN] or 0
  if errors > 0 then
    table.insert(parts, "%#DiagnosticError#E" .. errors .. "%*")
  end
  if warns > 0 then
    table.insert(parts, "%#DiagnosticWarn#W" .. warns .. "%*")
  end
  return table.concat(parts, " ")
end

local function branch(buf)
  local head = vim.b[buf].gitsigns_head
  if not head or head == "" then
    return ""
  end
  return " " .. escape(head)
end

-- Used through %! rather than %{%...%}, so the window being drawn comes from
-- g:statusline_winid and not from the current window.
function M.render()
  local buf = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
  local right = {}
  for _, part in ipairs({ lsp_progress(buf), diagnostics(buf), branch(buf) }) do
    if part ~= "" then
      table.insert(right, part)
    end
  end
  return "%<%f %m%=" .. table.concat(right, "  ")
end

local group = vim.api.nvim_create_augroup("core.winbar", { clear = true })

local function redraw()
  vim.cmd("redrawstatus!")
end

vim.api.nvim_create_autocmd("LspProgress", {
  group = group,
  callback = function(ev)
    local params = ev.data.params
    local value = params.value
    if type(value) ~= "table" or not value.kind then
      return
    end
    local id = ev.data.client_id
    progress[id] = progress[id] or {}
    if value.kind == "end" then
      progress[id][params.token] = nil
    else
      local prev = progress[id][params.token] or {}
      seq = seq + 1
      progress[id][params.token] = {
        seq = seq,
        title = value.title or prev.title or "",
        message = value.message or prev.message,
        percentage = value.percentage or prev.percentage,
      }
    end
    redraw()
  end,
})

vim.api.nvim_create_autocmd("LspDetach", {
  group = group,
  callback = function(ev)
    progress[ev.data.client_id] = nil
    redraw()
  end,
})

vim.api.nvim_create_autocmd("DiagnosticChanged", { group = group, callback = redraw })
vim.api.nvim_create_autocmd("User", { group = group, pattern = "GitSignsUpdate", callback = redraw })

vim.opt.winbar = "%!v:lua.require'core.winbar'.render()"

return M
