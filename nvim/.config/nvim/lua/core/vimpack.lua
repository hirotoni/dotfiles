local function pack_names(arg_lead)
  local names = {}
  for _, p in ipairs(vim.pack.get()) do
    if p.spec.name:find(arg_lead, 1, true) then
      names[#names + 1] = p.spec.name
    end
  end
  return names
end

-- custom commands for package management
-- PackUpdate updates installed packages
vim.api.nvim_create_user_command("PackUpdate", function(opts)
  vim.pack.update(#opts.fargs > 0 and opts.fargs or nil)
end, { nargs = "*", complete = pack_names })

-- PackList lists installed packages and shows active/inactive.
vim.api.nvim_create_user_command("PackList", function()
  local plugins = vim.pack.get()
  table.sort(plugins, function(a, b)
    return a.spec.name < b.spec.name
  end)
  local width = 0
  for _, p in ipairs(plugins) do
    width = math.max(width, #p.spec.name)
  end
  local lines = { string.format("%-" .. width .. "s  %-7s  %s", "NAME", "REV", "STATUS") }
  for _, p in ipairs(plugins) do
    lines[#lines + 1] = string.format(
      "%-" .. width .. "s  %-7s  %s",
      p.spec.name,
      (p.rev or ""):sub(1, 7),
      p.active and "active" or "inactive"
    )
  end
  print(table.concat(lines, "\n"))
end, {})

-- PackDel Deletes installed packages
vim.api.nvim_create_user_command("PackDel", function(opts)
  vim.pack.del(opts.fargs)
end, { nargs = "+", complete = pack_names })
