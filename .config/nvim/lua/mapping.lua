-- Change type mod
vim.api.nvim_set_keymap("i", "jk", "<Esc>", {noremap = true})
vim.api.nvim_set_keymap("i", "kj", "<Esc>", {noremap = true})

---------------
-- nvim-tree --
---------------

vim.api.nvim_set_keymap("n", "<leader>e", ":NvimTreeToggle<CR>", {noremap = true})


---------------------
-- nvim-bufferline --
---------------------

-- TAB in general mode will move to text buffer
vim.api.nvim_set_keymap("n", "<TAB>", ":bnext<CR>", {noremap = true})
-- SHIFT-TAB will go back
vim.api.nvim_set_keymap("n", "<S-TAB>", ":bprevious<CR>", {noremap = true})
