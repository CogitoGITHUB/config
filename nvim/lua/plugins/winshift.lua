return {
  'sindrets/winshift.nvim',
  config = function()
    require("winshift").setup({
      highlight_moving_win = true,
      focused_hl_group = "Visual",
      moving_win_options = {
        wrap = false,
        cursorline = false,
        cursorcolumn = false,
        colorcolumn = "",
      },
      keymaps = {
        disable_defaults = false,
        win_move_mode = {
          ["h"] = "left",
          ["j"] = "down",
          ["k"] = "up",
          ["l"] = "right",
          ["H"] = "far_left",
          ["J"] = "far_down",
          ["K"] = "far_up",
          ["L"] = "far_right",
          ["<left>"] = "left",
          ["<down>"] = "down",
          ["<up>"] = "up",
          ["<right>"] = "right",
          ["<S-left>"] = "far_left",
          ["<S-down>"] = "far_down",
          ["<S-up>"] = "far_up",
          ["<S-right>"] = "far_right",
        },
      },
      window_picker = function()
        return require("winshift.lib").pick_window({
          picker_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
          filter_rules = {
            cur_win = true,
            floats = true,
            filetype = {},
            buftype = {},
            bufname = {},
          },
          filter_func = nil,
        })
      end,
    })

    -- Keymap to start moving a window
    vim.api.nvim_set_keymap('n', '<leader>wm', '<cmd>WinShift<CR>', { noremap = true, silent = true })
  end,
}
