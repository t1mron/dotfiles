" auto-install vim-plug
if empty(glob('$HOME/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo $HOME/.config/nvim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
endif


"""""""""""
" PLUGINS "
"""""""""""

call plug#begin('$HOME/.config/nvim/autoload/plugged')
  " Intellisense
  Plug 'neovim/nvim-lspconfig'

  Plug 'hrsh7th/nvim-compe'
  
  " Start screen
  Plug 'mhinz/vim-startify'

  
  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

  " File explorer
  Plug 'kyazdani42/nvim-tree.lua'
  Plug 'kyazdani42/nvim-web-devicons'

  " Insert or delete brackets, parens, quotes in pair
  Plug 'windwp/nvim-autopairs'

  " Indent line
  Plug 'lukas-reineke/indent-blankline.nvim'

  Plug 'akinsho/nvim-bufferline.lua'

  " Status Line
  Plug 'hoob3rt/lualine.nvim'
  
  " Color highlighter
  Plug 'norcalli/nvim-colorizer.lua'

  " Colorscheme
  Plug 'sonph/onehalf', { 'rtp': 'vim' }
call plug#end()


""""""""""""""
" LUA-CONFIG "
""""""""""""""

lua << EOF

require('basic')
require('mapping')
require('plug-startify')
require('plug-lualine')
require('plug-nvim-tree')
require('plug-nvim-colorizer')
require('plug-nvim-autopairs')
require('plug-nvim-treesitter')
require('plug-indent-blankline')
require('plug-nvim-bufferline')
EOF
