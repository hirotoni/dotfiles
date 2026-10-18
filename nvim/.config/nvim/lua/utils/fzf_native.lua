local M = {}

M.name = "telescope-fzf-native.nvim"

local failed = {}

function M.built(dir)
  return vim.uv.fs_stat(dir .. "/build/libfzf.so") ~= nil
end

-- force: make only compares mtimes of src/ against build/, so a rebuild after
-- a version change is forced rather than left to that check.
function M.build(dir, force)
  local cmd = force and { "make", "-B" } or { "make" }
  local ok, res = pcall(function()
    return vim.system(cmd, { cwd = dir, text = true }):wait()
  end)
  if not ok or res.code ~= 0 then
    local msg = ok and (res.stderr ~= "" and res.stderr or res.stdout) or res
    vim.notify(("%s: `%s` failed in %s\n%s"):format(M.name, table.concat(cmd, " "), dir, msg), vim.log.levels.ERROR)
    failed[dir] = true
    return false
  end
  return M.built(dir)
end

function M.ensure(dir)
  if M.built(dir) then
    return true
  end
  return not failed[dir] and M.build(dir, false)
end

return M
