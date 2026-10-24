-- ~/.config/nvim/init.lua - Clean Neovim configuration

-- General settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.mouse = 'a'
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true
vim.opt.scrolloff = 8
vim.opt.signcolumn = 'yes'

-- Leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Keybindings
local keymap = vim.keymap.set
keymap('n', '<leader>w', '<cmd>w<cr>', { desc = 'Save file' })
keymap('n', '<leader>q', '<cmd>q<cr>', { desc = 'Quit' })
keymap('n', '<leader>h', '<cmd>nohlsearch<cr>', { desc = 'Clear highlight' })

-- Window navigation
keymap('n', '<C-h>', '<C-w>h', { desc = 'Go to left window' })
keymap('n', '<C-j>', '<C-w>j', { desc = 'Go to lower window' })
keymap('n', '<C-k>', '<C-w>k', { desc = 'Go to upper window' })
keymap('n', '<C-l>', '<C-w>l', { desc = 'Go to right window' })
