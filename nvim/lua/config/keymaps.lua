-- lua/config/keymaps.lua

local map = vim.keymap.set

vim.keymap.set("n", "<leader>l", "<cmd>Lazy<CR>", { desc = "Open Lazy Plugin Manager" })

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



