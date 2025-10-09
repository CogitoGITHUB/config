-- Configuration for the 'auto-save.nvim' plugin by pocco81.
-- This setup enables automatic saving on key events like leaving insert mode.

return {
    "Pocco81/auto-save.nvim",
    -- Set to false so the auto-save functionality is active immediately on startup.
    lazy = false, 
    
    -- All configuration options go inside the 'opts' table.
    opts = {
        enabled = true, -- Start auto-save when the plugin is loaded
        
        execution_message = {
            -- Display the save time in the message area
            message = function() 
                return ("AutoSave: saved at " .. vim.fn.strftime("%H:%M:%S"))
            end,
            dim = 0.18, -- Dim the color of the message
            cleaning_interval = 1250, -- (milliseconds) clear the message after this duration
        },
        
        -- Trigger saving when leaving insert mode or when text changes (TextChanged is very aggressive)
        trigger_events = {"InsertLeave", "TextChanged"}, 
        
        -- Function to determine if the current buffer should be saved.
        condition = function(buf)
            local fn = vim.fn
            -- NOTE: This line requires the plugin to be loaded correctly to access its utilities.
            local utils = require("auto-save.utils.data") 

            if
                fn.getbufvar(buf, "&modifiable") == 1 and -- Check if the buffer can be modified
                utils.not_in(fn.getbufvar(buf, "&filetype"), {}) then -- Check if filetype is NOT in the exclusion list {}
                return true -- met condition(s), can save
            end
            return false -- can't save
        end,
        
        write_all_buffers = false, -- Only save the current buffer
        debounce_delay = 135, -- Saves the file at most every 135 milliseconds
        
        callbacks = { -- Functions to be executed at different intervals (all nil here, using defaults)
            enabling = nil,
            disabling = nil,
            before_asserting_save = nil,
            before_saving = nil,
            after_saving = nil
        }
    }
}

