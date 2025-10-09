vim.g.vimtex_view_method = 'zathura'
-- ===========================================================================
-- CORE EDITOR SETTINGS
-- ===========================================================================

-- Essential: Sets Neovim to modern, non-Vim compatibility mode
vim.opt.compatible = false 
vim.opt.encoding = 'utf-8'

-- Leader key
vim.g.mapleader = ' '

-- Line Numbers and Column
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 8        -- Keep 8 lines of context above/below cursor


-- Indentation
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true

-- Search Behavior
vim.opt.ignorecase = true -- Ignore case in searches
vim.opt.smartcase = true  -- Unless a capital letter is used
vim.opt.hlsearch = true   -- Highlight all matches

-- UI and Visuals
vim.opt.cursorline = true    -- Highlight the current line
vim.opt.mouse = 'a'          -- Enable mouse in all modes
vim.opt.title = true
vim.opt.updatetime = 300     -- Faster updates for diagnostics/plugins
vim.opt.cursorline = true    -- Highlight the current line

-- Split Behavior
vim.opt.splitright = true
vim.opt.splitbelow = true

-- ===========================================================================
-- PLUGIN MANAGER (Assuming lazy.nvim setup follows here)
-- ===========================================================================
require("config.lazy")
require("config.keymaps")





