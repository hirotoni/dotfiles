local M = {}

function M.complete_names(arg_lead)
  local names = {}
  for _, p in ipairs(vim.pack.get(nil, { info = false })) do
    if p.spec.name:find(arg_lead, 1, true) then
      names[#names + 1] = p.spec.name
    end
  end
  return names
end

return M
