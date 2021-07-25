-- set leader key
vim.g.mapleader = ' ' 

-- colorscheme
vim.cmd('syntax enable')                      -- Enables syntax highlighing
vim.o.termguicolors = true                    -- True colors
vim.o.background = 'light'                    -- tell vim what the background color looks like
vim.cmd('colorscheme onehalflight')

vim.o.cursorline = true                       -- Enable highlighting of the current line
--let python_highlight_space_errors = 0       -- Stop highlighting trailing whitespace in python files

-- Tab setting
vim.o.shiftwidth = 2                          -- Change the number of space characters inserted for indentation
vim.o.tabstop = 2                             -- Insert 2 spaces for a tab
vim.o.softtabstop = 2                         -- Insert 2 spaces for a tab
vim.o.smarttab = true                         -- Makes tabbing smarter will realize you have 2 vs 4
vim.o.expandtab = true                        -- Converts tabs to spaces

-- Indent
vim.o.smartindent = true                      -- Makes indenting smart
vim.o.autoindent = true                       -- Good auto indent

-- Split
vim.o.splitbelow = true                       -- Horizontal splits will automatically be below
vim.o.splitright = true                       -- Vertical splits will automatically be to the right

-- File coding
vim.o.encoding = 'utf-8'                      -- The encoding displayed
vim.o.fileencoding = 'utf-8'                  -- The encoding written to file
vim.o.swapfile = false                        -- Don't like swaps files
vim.o.updatetime = 300                        -- Faster completion
vim.o.timeoutlen = 500                        -- By default timeoutlen is 1000 ms

-- command line
vim.o.showcmd = false                         -- I use it for hide spam buttons 
vim.o.cmdheight = 1                           -- More space for displaying messages

vim.o.hidden = true                           -- Required to keep multiple buffers open multiple buffers
vim.o.wrap = false                            -- Display long lines as just one line
vim.o.pumheight = 10                          -- Makes popup menu smaller
vim.o.ruler = true             			          -- Show the cursor position all the time
vim.o.mouse = 'a'                             -- Enable your mouse
vim.o.number = true                           -- Line current numbers
vim.o.relativenumber = true                   -- Line relative numbers
vim.o.clipboard = 'unnamedplus'               -- Copy paste between vim and everything else
