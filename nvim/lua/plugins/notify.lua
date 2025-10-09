return {
  {
    "rcarriga/nvim-notify",
    opts = {
      timeout = 3000,
      -- Simple fade-in/fade-out animation
      stages = "fade",
      background_colour = "#1e1e2e",
      -- Compact notification appearance
      render = "compact",
    },
    config = function(_, opts)
      local notify = require("notify")

      -- Function to set all border, icon, and title highlights to white
      local function setup_white_notify_highlights()
        local set_hl = vim.api.nvim_set_hl
        local cmd = vim.cmd
        local white = "#FFFFFF"

        -- Highlight groups (All White for Borders, Icons, and Titles)
        local levels = { "ERROR", "WARN", "INFO", "DEBUG", "TRACE" }
        for _, level in ipairs(levels) do
          set_hl(0, "Notify" .. level .. "Border", { fg = white })
          set_hl(0, "Notify" .. level .. "Icon",   { fg = white })
          set_hl(0, "Notify" .. level .. "Title",  { fg = white })
          
          -- Link Body to 'Normal' (Body text usually follows your colorscheme)
          cmd("highlight link Notify" .. level .. "Body Normal")
        end
      end

      -- Setup nvim-notify
      notify.setup(opts)
      vim.notify = notify

      -- Apply the all-white custom highlights
      setup_white_notify_highlights()
    end,
  },
}
