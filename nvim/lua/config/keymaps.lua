-- lua/config/keymaps.lua

local map = vim.keymap.set

vim.keymap.set("n", "<leader>l", "<cmd>Lazy<CR>", { desc = "Open Lazy Plugin Manager" })
-- Lua code to set the key map:
vim.keymap.set('n', '<leader>q', '<cmd>quit<CR>', { desc = 'Quit Neovim' })
-- Keymap to open Oil in the current directory
map("n", "<leader>e", "<CMD>Oil<CR>", { desc = "Open Oil (file explorer)" })

local todo = require("todo-comments")

-- Jump to next todo comment
vim.keymap.set("n", "]t", function()
  todo.jump_next()
end, { desc = "Next TODO comment" })

-- Jump to previous todo comment
vim.keymap.set("n", "[t", function()
  todo.jump_prev()
end, { desc = "Previous TODO comment" })

-- Jump to next only ERROR/WARNING keyword
vim.keymap.set("n", "]T", function()
  todo.jump_next({ keywords = { "ERROR", "WARNING" } })
end, { desc = "Next ERROR/WARNING todo" })

-- Jump to previous only ERROR/WARNING keyword
vim.keymap.set("n", "[T", function()
  todo.jump_prev({ keywords = { "ERROR", "WARNING" } })
end, { desc = "Previous ERROR/WARNING todo" })


-- recommended mappings
-- resizing splits
-- these keymaps will also accept a range,
-- for example `10<A-h>` will `resize_left` by `(10 * config.default_amount)`
vim.keymap.set('n', '<A-h>', require('smart-splits').resize_left)
vim.keymap.set('n', '<A-j>', require('smart-splits').resize_down)
vim.keymap.set('n', '<A-k>', require('smart-splits').resize_up)
vim.keymap.set('n', '<A-l>', require('smart-splits').resize_right)
-- moving between splits
vim.keymap.set('n', '<C-h>', require('smart-splits').move_cursor_left)
vim.keymap.set('n', '<C-j>', require('smart-splits').move_cursor_down)
vim.keymap.set('n', '<C-k>', require('smart-splits').move_cursor_up)
vim.keymap.set('n', '<C-l>', require('smart-splits').move_cursor_right)
vim.keymap.set('n', '<C-\\>', require('smart-splits').move_cursor_previous)
-- swapping buffers between windows
vim.keymap.set('n', '<leader><leader>h', require('smart-splits').swap_buf_left)
vim.keymap.set('n', '<leader><leader>j', require('smart-splits').swap_buf_down)
vim.keymap.set('n', '<leader><leader>k', require('smart-splits').swap_buf_up)
vim.keymap.set('n', '<leader><leader>l', require('smart-splits').swap_buf_right)
