-- vim.pack.add() never moves a plugin that is already on disk, so a version
-- bump pulled from git leaves the old revision running. vim.pack.get().rev is
-- read from the lockfile, not from disk, so it cannot reveal this either.

local function read_file(path)
  local fd = io.open(path, "r")
  if not fd then
    return nil
  end
  local data = fd:read("*a")
  fd:close()
  return data
end

-- vim.pack checks out plugins by commit hash, leaving .git/HEAD detached with a
-- bare sha. Reading it avoids spawning one git process per plugin at startup.
local function disk_rev(path)
  local head = read_file(path .. "/.git/HEAD")
  if not head then
    return nil
  end
  head = vim.trim(head)
  if head:match("^%x+$") then
    return head
  end
  local res = vim.system({ "git", "-C", path, "rev-parse", "HEAD" }, { text = true }):wait()
  return res.code == 0 and vim.trim(res.stdout) or nil
end

local function drift()
  local lock = read_file(vim.fn.stdpath("config") .. "/nvim-pack-lock.json")
  if not lock then
    return {}
  end
  local ok, decoded = pcall(vim.json.decode, lock)
  if not ok or type(decoded) ~= "table" or type(decoded.plugins) ~= "table" then
    return {}
  end
  local plug_dir = vim.fn.stdpath("data") .. "/site/pack/core/opt"
  local out = {}
  for name, data in vim.spairs(decoded.plugins) do
    local rev = disk_rev(plug_dir .. "/" .. name)
    if rev and type(data.rev) == "string" and rev ~= data.rev then
      out[#out + 1] = { name = name, disk = rev, lock = data.rev }
    end
  end
  return out
end

local function format(items)
  local lines = {}
  for _, d in ipairs(items) do
    lines[#lines + 1] = string.format("%s  disk=%s  lock=%s", d.name, d.disk:sub(1, 7), d.lock:sub(1, 7))
  end
  return table.concat(lines, "\n")
end

vim.api.nvim_create_user_command("PackDrift", function()
  local items = drift()
  if #items == 0 then
    print("PACK_DRIFT none")
  else
    print("PACK_DRIFT " .. #items .. "\n" .. format(items))
  end
end, {})

vim.api.nvim_create_user_command("PackSync", function(opts)
  vim.pack.update(#opts.fargs > 0 and opts.fargs or nil, { target = "lockfile", force = opts.bang })
end, {
  nargs = "*",
  bang = true,
  complete = require("utils.pack").complete_names,
})

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    local items = drift()
    if #items > 0 then
      vim.notify("Plugins on disk differ from nvim-pack-lock.json (run :PackSync):\n" .. format(items), vim.log.levels.WARN)
    end
  end,
})
