-- ~/.config/nvim/lua/plugins/notify.lua
return {
  {
    "rcarriga/nvim-notify",
    opts = {
      timeout = 3000,
      stages = "fade_in_slide_out",
      background_colour = "#1e1e2e",
    },
    config = function(_, opts)
      local notify = require("notify")
      notify.setup(opts)
      vim.notify = notify
    end,
  },
}

