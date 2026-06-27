local M = {}

-- Run a git command in `cwd`. Returns trimmed stdout on success, or nil on failure.
local function git(args, cwd)
  local cmd = { "git" }
  for _, a in ipairs(args) do
    table.insert(cmd, a)
  end
  local ok, result = pcall(function()
    return vim.system(cmd, { cwd = cwd, text = true }):wait()
  end)
  if not ok or type(result) ~= "table" then
    return nil
  end
  if result.code ~= 0 then
    return nil
  end
  local out = result.stdout or ""
  out = out:gsub("%s+$", ""):gsub("^%s+", "")
  if out == "" then
    return nil
  end
  return out
end

-- Normalize a github remote URL into https://github.com/owner/repo (no trailing .git).
-- Returns nil if not a github.com remote.
local function normalize_remote(url)
  -- ssh://git@github.com/owner/repo.git
  -- git@github.com:owner/repo.git
  -- https://github.com/owner/repo.git
  local host, path

  host, path = url:match("^ssh://git@([^/]+)/(.+)$")
  if not host then
    host, path = url:match("^git@([^:]+):(.+)$")
  end
  if not host then
    host, path = url:match("^https?://([^/]+)/(.+)$")
  end

  if not host or not path then
    return nil
  end
  -- Strip optional userinfo ("user@") and trailing port (":22").
  host = host:gsub("^[^@]+@", ""):gsub(":%d+$", "")
  if host ~= "github.com" then
    return nil
  end

  path = path:gsub("%.git$", "")
  return "https://github.com/" .. path
end

-- Percent-encode unsafe characters in a path while keeping '/' and common safe chars.
local function encode_path(path)
  return (path:gsub("[^%w%-%._~/]", function(c)
    return string.format("%%%02X", string.byte(c))
  end))
end

-- Build the permalink URL for the current buffer / line(s).
-- Returns the url string, or nil (after notifying) on failure.
local function build_url()
  local path = vim.api.nvim_buf_get_name(0)
  if path == nil or path == "" then
    vim.notify("githublink: buffer has no file name", vim.log.levels.ERROR)
    return nil
  end

  local dir = vim.fn.fnamemodify(path, ":h")

  local root = git({ "rev-parse", "--show-toplevel" }, dir)
  if not root then
    vim.notify("githublink: not inside a git repository", vim.log.levels.ERROR)
    return nil
  end

  local remote = git({ "remote", "get-url", "origin" }, dir)
  if not remote then
    vim.notify("githublink: could not read 'origin' remote", vim.log.levels.ERROR)
    return nil
  end

  local base = normalize_remote(remote)
  if not base then
    vim.notify("githublink: remote is not a github.com repository", vim.log.levels.ERROR)
    return nil
  end

  local sha = git({ "rev-parse", "HEAD" }, dir)
  if not sha then
    vim.notify("githublink: could not resolve HEAD commit", vim.log.levels.ERROR)
    return nil
  end

  -- Best-effort unpushed check; ignore failures of the check itself.
  -- Empty output (code 0) means no remote branch contains the commit.
  local ok, res = pcall(function()
    return vim.system({ "git", "branch", "-r", "--contains", sha }, { cwd = dir, text = true }):wait()
  end)
  if ok and type(res) == "table" and res.code == 0 then
    local contains = (res.stdout or ""):gsub("%s+", "")
    if contains == "" then
      vim.notify("githublink: commit not pushed to remote", vim.log.levels.WARN)
    end
  end

  -- Repo-relative path. Ask git first (authoritative, handles stow symlinks);
  -- fall back to realpath-and-strip for untracked files.
  local relpath = git({ "-c", "core.quotePath=false", "ls-files", "--full-name", "--", path }, dir)
  if not relpath then
    -- Realpath both the buffer path and the repo root before stripping, so
    -- symlinked (stow-managed) paths resolve to the same real prefix.
    local real_path = (vim.uv or vim.loop).fs_realpath(path) or vim.fn.resolve(path)
    local real_root = (vim.uv or vim.loop).fs_realpath(root) or vim.fn.resolve(root)
    local prefix = real_root:gsub("/+$", "") .. "/"
    if real_path:sub(1, #prefix) == prefix then
      relpath = real_path:sub(#prefix + 1)
    else
      relpath = real_path
    end
  end
  relpath = relpath:gsub("\\", "/")

  -- Guard: if stripping failed we'd emit a broken (absolute / double-slash) URL.
  if relpath == "" or relpath:sub(1, 1) == "/" or relpath == path then
    vim.notify("githublink: could not derive repo-relative path for buffer", vim.log.levels.ERROR)
    return nil
  end

  -- Line range.
  local lines
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    local a = vim.fn.getpos("v")[2]
    local b = vim.fn.getpos(".")[2]
    if a > b then
      a, b = b, a
    end
    if a == b then
      lines = "#L" .. a
    else
      lines = "#L" .. a .. "-L" .. b
    end
  else
    lines = "#L" .. vim.fn.line(".")
  end

  return base .. "/blob/" .. sha .. "/" .. encode_path(relpath) .. lines
end

function M.copy()
  local url = build_url()
  if not url then
    return
  end
  vim.fn.setreg("+", url)
  vim.notify("githublink: copied " .. url)
end

function M.open()
  local url = build_url()
  if not url then
    return
  end
  if vim.ui.open then
    vim.ui.open(url)
  else
    pcall(function()
      vim.system({ "open", url })
    end)
  end
end

vim.keymap.set({ "n", "x" }, "<leader>gy", M.copy, { desc = "GitHub permalink: copy to clipboard" })
vim.keymap.set({ "n", "x" }, "<leader>go", M.open, { desc = "GitHub permalink: open in browser" })

return M
