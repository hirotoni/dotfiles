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
    mermaid = { theme = "default", background = "transparent", scale = 1 },
    d2 = { theme_id = 1, dark_theme_id = 200, scale = 1 },
  },
})
