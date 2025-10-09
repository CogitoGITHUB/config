return {
    'lewis6991/gitsigns.nvim',
    -- Set event to 'VeryLazy' to load it after the UI (Lualine/Incline) is ready
    event = "VeryLazy", 
    
    config = function()
        require('gitsigns').setup({
            -- Show the git status in the sign column (next to line numbers)
            signs = {
                add = { text = '▎' },
                change = { text = '▎' },
                delete = { text = '契' },
                topdelete = { text = '契' },
                changedelete = { text = '▎' },
                untracked = { text = '┆' },
            },
            
            -- Keymaps for common Git actions (using <leader>g prefix)
            on_attach = function(bufnr)
                local gs = require('gitsigns')

                local function map(mode, lhs, rhs, desc)
                    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
                end

                map('n', '<leader>gp', gs.prev_hunk, 'Go to Previous Git Hunk')
                map('n', '<leader>gn', gs.next_hunk, 'Go to Next Git Hunk')
                map('n', '<leader>gh', gs.preview_hunk, 'Preview Git Hunk')
                map('n', '<leader>gb', function() gs.blame_line({ full = true }) end, 'Blame Line')
                map('n', '<leader>gS', gs.stage_hunk, 'Stage Git Hunk')
                map('n', '<leader>gR', gs.reset_hunk, 'Reset Git Hunk')
                map('v', '<leader>gS', function() gs.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end, 'Stage Visual Hunk')
                map('v', '<leader>gR', function() gs.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end, 'Reset Visual Hunk')
                
                -- Toggle Gitsigns on/off
                map('n', '<leader>gt', gs.toggle_signs, 'Toggle Gitsigns')
            end,

            -- Other configuration settings
            watch_gitdir = { interval = 1000, follow_files = true },
            attach_to_untracked = true,
            current_line_blame = false, -- Display blame info next to current line
            word_diff = false, -- Turn off word diff support
        })
    end,
}

