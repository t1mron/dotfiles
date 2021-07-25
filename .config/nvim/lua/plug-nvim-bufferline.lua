require("bufferline").setup {
  options = {
    tab_size = 20,
    show_buffer_close_icons = false,
    show_close_icon = false,
    always_show_bufferline = true,
    enforce_regular_tabs = true,
    separator_style = "thin",
    offsets = {{filetype = "NvimTree", text = "File Explorer", highlight = "Directory", text_align = "left"}}
  }
}

