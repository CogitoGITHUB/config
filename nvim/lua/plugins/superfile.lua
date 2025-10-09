return {
  "anaypurohit0907/superfile.nvim",
  -- Remove 'main = "superfile"' as it's not needed for simple plugins
  -- Remove 'opts = { key = false }' as you are defining the keymap below
  
  keys = {
    {
      "<leader>f",
      -- Execute the plugin's registered command, typically :SuperFile.
      -- If the plugin uses a different command, substitute it here.
      "<cmd>SuperFile<CR>",
      mode = { "n" },
      desc = "Open Superfile",
      -- Remove 'silent = true' as it can hide useful output if something goes wrong
    },
  },
}
