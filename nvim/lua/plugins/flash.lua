return {
  "folke/flash.nvim",
  event = "VeryLazy",
  ---@type Flash.Config
  opts = {
    -- Enables Flash to search and jump across all visible windows/splits
    multi_window = true, 
    
    modes = {
      -- Integrate Flash with regular search
      search = {
        enabled = true,
        -- You can force multi_window here again, but setting it at the top-level is enough.
        -- multi_window = true, 
      },
    },
  },
  -- stylua: ignore
  keys = {
    -- Basic Flash jump (for single character/two-character motions)
    { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    
    -- Flash Treesitter (for selecting syntax nodes)
    { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    
    -- Optional: Remote Flash (useful in operator-pending mode, e.g., to yank)
    -- { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
  },
}
