return {
    "folke/zen-mode.nvim",
    cmd = "ZenMode", -- Allows lazy loading with command (though we add a keymap)
    opts = {
        window = {
            backdrop = 0.95, -- shade the backdrop of the Zen window (0.95 darkens slightly)
            width = 120,    -- width of the Zen window (absolute cells)
            height = 1,     -- height of the Zen window (100% of editor height)
            options = {
                -- signcolumn = "no", -- disable signcolumn
            },
        },
        plugins = {
            options = {
                enabled = true,
                ruler = false,    -- disables the ruler text in the cmd line area
                showcmd = false,  -- disables the command in the last line of the screen
                laststatus = 0,   -- turn off the statusline in zen mode
            },
            twilight = { enabled = true }, -- enable to start Twilight when zen mode opens
            gitsigns = { enabled = false }, -- disables git signs
            tmux = { enabled = false },     -- disables the tmux statusline
            todo = { enabled = false },     -- disables todo-comments.nvim highlights
            
            -- Terminal integrations (disabled by default)
            kitty = { enabled = false, font = "+4" },
            alacritty = { enabled = false, font = "14" },
            wezterm = { enabled = false, font = "+4" },
            neovide = {
                enabled = false,
                scale = 1.2,
                disable_animations = {
                    neovide_animation_length = 0,
                    neovide_cursor_animate_command_line = false,
                    neovide_scroll_animation_length = 0,
                    neovide_position_animation_length = 0,
                    neovide_cursor_animation_length = 0,
                    neovide_cursor_vfx_mode = "",
                }
            },
        },
        on_open = function(win)
        end,
        on_close = function()
        end,
    },
    -- ADD THIS 'keys' TABLE TO DEFINE THE MAPPING
    keys = {
        {
            -- Use <leader>z to call the ZenMode command
            "<leader>z",
            function()
                require("zen-mode").toggle()
            end,
            mode = "n", -- Normal mode only
            desc = "Toggle Zen Mode",
        },
    },
}
