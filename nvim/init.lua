-- Set global options
vim.opt.relativenumber = true
vim.g.mapleader = ' '

require("config.lazy")
require("config.keymaps")

vim.g.vimtex_view_method = 'zathura'

