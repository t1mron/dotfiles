" auto-install vim-plug
if empty(glob('$HOME/.vim/autoload/plug.vim'))
  silent !curl -fLo $HOME/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
endif


"""""""""""
" PLUGINS "
"""""""""""

call plug#begin('$HOME/.vim/autoload/plugged')
  
  " Intellisense
  "Plug 'neoclide/coc.nvim', {'branch': 'release'}
  
  " Auto pairs for '(' '[' '{'
  Plug 'jiangmiao/auto-pairs' 
  " Start screen
  Plug 'mhinz/vim-startify'
  Plug 'Yggdroot/indentLine'
  " Latex
  Plug 'lervag/vimtex'  
  
  " Themes
  Plug 'sonph/onehalf', { 'rtp': 'vim' }
  " Status Line
  Plug 'itchyny/lightline.vim'
  " Icons for plugins 
  Plug 'ryanoasis/vim-devicons'

call plug#end()


"""""""""
" BASIC "
"""""""""

" Set leader key
let g:mapleader = "\<Space>"

" Colorscheme
colorscheme onehalflight
syntax enable                           " Enables syntax highlighing
set termguicolors                       " True colors
set background=light                    " Tell vim what the background color looks like
set t_Co=256                            " Support 256 colors

" Tab settings 
set tabstop=2                           " Insert 2 spaces for a tab
set shiftwidth=2                        " Change the number of space characters inserted for indentation
set softtabstop=2                       " Insert 2 spaces for a tab
set smarttab                            " Makes tabbing smarter will realize you have 2 vs 4
set expandtab                           " Converts tabs to spaces

" Indent 
set smartindent                         " Makes indenting smart
set autoindent                          " Good auto indent

" Split
set splitbelow                          " Horizontal splits will automatically be below
set splitright                          " Vertical splits will automatically be to the right

" File encoding
set encoding=utf-8                      " The encoding displayed
set fileencoding=utf-8                  " The encoding written to file

" Command line
set noshowcmd                           " I use it for hide spam buttons
set cmdheight=2                         " More space for displaying messages
set noshowmode                          " We don't need to see things like -- INSERT -- anymore

" Status line
set laststatus=2                        " Always display the status line
set showtabline=2                       " Always show tabs

set hidden                              " Required to keep multiple buffers open multiple buffers
set nowrap                              " Display long lines as just one line
set pumheight=10                        " Makes popup menu smaller
set ruler              			            " Show the cursor position all the time
set iskeyword+=-                      	" treat dash separated words as a word text object
set mouse=a                             " Enable your mouse
set updatetime=300                      " Faster completion
set timeoutlen=500                      " By default timeoutlen is 1000 ms
set relativenumber                      " Line numbers
set number                              " Line numbers
set formatoptions-=cro                  " Stop newline continution of comments
set clipboard=unnamedplus               " Copy paste between vim and everything else
"set autochdir                          " Your working directory will always be the same as your working directory

let python_highlight_space_errors = 0   " Stop highlighting trailing whitespace in python files


"""""""""""
" MAPPING "
"""""""""""

" Better nav for omnicomplete
"inoremap <expr> <c-j> ("\<C-n>")
"inoremap <expr> <c-k> ("\<C-p>")

" Use alt + hjkl to resize windows
"nnoremap <M-j>    :resize -2<CR>
"nnoremap <M-k>    :resize +2<CR>
"nnoremap <M-h>    :vertical resize -2<CR>
"nnoremap <M-l>    :vertical resize +2<CR>

" I hate escape more than anything else
inoremap jk <Esc>
inoremap kj <Esc>

" Easy CAPS
"inoremap <c-u> <ESC>viwUi
"nnoremap <c-u> viwU<Esc>

" TAB in general mode will move to text buffer
nnoremap <TAB> :bnext<CR>
" SHIFT-TAB will go back
nnoremap <S-TAB> :bprevious<CR>

" Disable copy-past middle click
nnoremap <MiddleMouse> <Nop>
nnoremap <2-MiddleMouse> <Nop>
nnoremap <3-MiddleMouse> <Nop>
nnoremap <4-MiddleMouse> <Nop>

" Alternate way to save
"nnoremap <C-s> :w<CR>
" Alternate way to quit
"nnoremap <C-Q> :wq!<CR>
" Use control-c instead of escape
"nnoremap <C-c> <Esc>
" <TAB>: completion.
"inoremap <expr><TAB> pumvisible() ? "\<C-n>" : "\<TAB>"

" Better tabbing
"vnoremap < <gv
"vnoremap > >gv

" Better window navigation
"nnoremap <C-h> <C-w>h
"nnoremap <C-j> <C-w>j
"nnoremap <C-k> <C-w>k
"nnoremap <C-l> <C-w>l

"nnoremap <Leader>o o<Esc>^Da
"nnoremap <Leader>O O<Esc>^Da


""""""""""""""""""""""""""""""""""""""""""""""

"""""""""""
" AIRLINE "
"""""""""""

let g:lightline = {
      \ 'colorscheme': 'one',
      \ }


""""""""""""""
" INDENTLINE "
""""""""""""""

let g:indentLine_char = '│'
let g:indentLine_first_char = '│'
let g:indentLine_showFirstIndentLevel = 1
let g:indentLine_fileTypeExclude = ['startify']

""""""""""""
" STARTIFY "
""""""""""""

" Directory
let g:startify_session_dir = '$HOME/.vim/session'

" Automatically restart sessions
let g:startify_session_autoload = 1

" Automatically update Sessions
let g:startify_session_persistence = 1

" Custom header
let g:startify_custom_header = []

" Lists
let g:startify_lists = [
  \ { 'type': 'files',     'header': ['   Files']            },
  \ { 'type': 'dir',       'header': ['   Current Directory '. getcwd()] },
  \ { 'type': 'sessions',  'header': ['   Sessions']       },
  \ { 'type': 'bookmarks', 'header': ['   Bookmarks']      },
  \ ]

" Bookmarks
let g:startify_bookmarks = [
  \ { 'c': '$HOME/.config/i3/config' },
  \ { 'v': '$HOME/.vimrc' },
  \ { 'z': '$HOME/.zshrc' },
  \ '$HOME/Blog',
  \ '$HOME/Code',
  \ '$HOME/Pics',
  \ ]
