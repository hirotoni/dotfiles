vim.pack.add({
  { version = "44e0712", src = "https://github.com/3rd/image.nvim" },
  { version = "89d8110", src = "https://github.com/3rd/diagram.nvim" },
})

require("image").setup({
  backend = "kitty",
  processor = "magick_cli",
  integrations = {
    markdown = {
      enabled = true,
      clear_in_insert_mode = false,
      download_remote_images = true,
      only_render_image_at_cursor = false,
      filetypes = { "markdown" },
    },
  },
  max_width = nil,
  max_height = nil,
  max_width_window_percentage = nil,
  max_height_window_percentage = 50,
  window_overlap_clear_enabled = true,
  window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "neo-tree" },
})

require("diagram").setup({
  integrations = {
    require("diagram.integrations.markdown"),
  },
  renderer_options = {
    plantuml = { charset = "utf-8" },
    mermaid = { theme = "dark", background = "transparent", scale = 1.5 },
    d2 = { theme_id = 1, dark_theme_id = 200, scale = 1 },
  },
})

local function bundled_puppeteer()
  local mmdc = vim.fn.exepath("mmdc")
  if mmdc == "" then
    return nil
  end
  local cli = vim.fn.resolve(mmdc)
  local puppeteer = vim.fs.joinpath(vim.fs.dirname(vim.fs.dirname(cli)), "node_modules", ".bin", "puppeteer")
  if vim.fn.executable(puppeteer) == 1 then
    return puppeteer
  end
end

local function chrome_recovery_hint()
  local lines = {
    "",
    "mmdc only accepts the chrome-headless-shell build pinned by the puppeteer bundled with mermaid-cli.",
    "The npx command above installs a different build and does not fix this. Run instead:",
  }
  local puppeteer = bundled_puppeteer()
  if puppeteer then
    table.insert(lines, "  " .. vim.fn.shellescape(puppeteer) .. " browsers install chrome-headless-shell")
  else
    -- install.sh の stow で stdpath("config") は <dotfiles>/nvim/.config/nvim へのリンクになる。
    local dotfiles = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(vim.fn.resolve(vim.fn.stdpath("config")))))
    table.insert(lines, "  " .. vim.fn.shellescape(vim.fs.joinpath(dotfiles, "install.sh")) .. " nvim")
  end
  return lines
end

-- diagram.nvim の markdown integration は require("diagram/renderers") 経由で
-- "diagram/renderers/mermaid" をスラッシュ区切りで読む。ドット区切りの require は
-- package.loaded の別キーになり別のテーブルを返すので、同じ経路から差し替える。
-- mermaid renderer は mmdc の stderr を on_stderr でそのまま通知し、差し込み口を
-- 持たないため、render の間だけ jobstart を包んで on_stderr に案内を足す。
local mermaid = require("diagram/renderers").mermaid
local render_mermaid = mermaid.render
mermaid.render = function(source, options)
  local jobstart = vim.fn.jobstart
  vim.fn.jobstart = function(cmd, opts)
    local on_stderr = opts and opts.on_stderr
    if on_stderr then
      opts.on_stderr = function(job_id, data, event)
        if table.concat(data, "\n"):find("Could not find chrome-headless-shell", 1, true) then
          data = vim.list_slice(data)
          while data[#data] == "" do
            table.remove(data)
          end
          vim.list_extend(data, chrome_recovery_hint())
        end
        return on_stderr(job_id, data, event)
      end
    end
    return jobstart(cmd, opts)
  end
  local ok, result = pcall(render_mermaid, source, options)
  vim.fn.jobstart = jobstart
  if not ok then
    error(result, 0)
  end
  return result
end
