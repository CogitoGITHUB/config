return {
  { -- Compiler plugin with lazy loading on commands
    "Zeioth/compiler.nvim",
    cmd = { "CompilerOpen", "CompilerToggleResults", "CompilerRedo" },
    dependencies = { "stevearc/overseer.nvim", "nvim-telescope/telescope.nvim" },
    opts = {},
  },
  { -- Overseer task runner, pinned to a commit
    "stevearc/overseer.nvim",
    commit = "6271cab7ccc4ca840faa93f54440ffae3a3918bd",
    cmd = { "CompilerOpen", "CompilerToggleResults", "CompilerRedo" },
    opts = {
      task_list = {
        direction = "bottom",
        min_height = 25,
        max_height = 25,
        default_detail = 1,
      },
    },
  },

  -- You can add keymaps here or in your general keymap file:
  -- Open compiler panel with F6
  -- Redo last selected compile option with Shift-F6
  -- Toggle compiler results with Shift-F7

  -- Set keymaps after plugin loads, so you might want a dedicated lua file or use a setup function
  -- Here is the Lua way to set them:
  {
    "folke/which-key.nvim", -- optional, for keymap hints
    config = function()
      vim.api.nvim_set_keymap('n', '<F6>', "<cmd>CompilerOpen<cr>", { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', '<S-F6>', "<cmd>CompilerStop<cr><cmd>CompilerRedo<cr>", { noremap = true, silent = true })
      vim.api.nvim_set_keymap('n', '<S-F7>', "<cmd>CompilerToggleResults<cr>", { noremap = true, silent = true })
    end,
  },
}

