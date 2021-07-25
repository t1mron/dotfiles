vim.g.startify_custom_header = {}

vim.g.startify_lists = {
  { type = 'sessions', header = { '   Sessions' } },
  { type = 'bookmarks', header = { '   Bookmarks' } },
  { type = 'files', header = { '   Files' } },
  { type = 'dir', header = { "   Current Directory "..vim.fn.getcwd()..":" } }
}

vim.g.startify_bookmarks = {
  { b = '$HOME/.config/bspwm/bspwmrc'},
  { i = '$HOME/.config/nvim/init.vim'},
  { s = '$HOME/.config/sxhkd/sxhkdrc'},
  { l = '$HOME/.config/lemonbar/panel.sh'},
  { z = '$HOME/.zshrc' },
}
