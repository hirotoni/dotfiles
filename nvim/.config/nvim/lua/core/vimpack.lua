local complete_names = require("utils.pack").complete_names

vim.api.nvim_create_user_command("PackUpdate", function(opts)
  vim.pack.update(#opts.fargs > 0 and opts.fargs or nil)
end, { nargs = "*", complete = complete_names })

vim.api.nvim_create_user_command("PackList", function()
  local plugins = vim.pack.get(nil, { info = false })
  table.sort(plugins, function(a, b)
    return a.spec.name < b.spec.name
  end)
  local width = 0
  for _, p in ipairs(plugins) do
    width = math.max(width, #p.spec.name)
  end
  local lines = { string.format("%-" .. width .. "s  %-7s  %s", "NAME", "REV", "STATUS") }
  for _, p in ipairs(plugins) do
    lines[#lines + 1] =
      string.format("%-" .. width .. "s  %-7s  %s", p.spec.name, (p.rev or ""):sub(1, 7), p.active and "active" or "inactive")
  end
  print(table.concat(lines, "\n"))
end, {})

vim.api.nvim_create_user_command("PackDel", function(opts)
  vim.pack.del(opts.fargs)
end, { nargs = "+", complete = complete_names })
