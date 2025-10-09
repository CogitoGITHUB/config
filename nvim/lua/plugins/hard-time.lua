return {
    "m4xshen/hardtime.nvim",
    lazy = false, -- Must load early to capture all keystrokes
    
    opts = {
        -- Configuration table for Hardtime.nvim
        disable_mouse = false, -- Setting to true forces you to use keyboard motions
        max_duration = 5000,   -- Time (ms) between key presses before the count resets
        
        -- Define "bad habits" to check for
        excluded_modes = { "v", "V", "R", "c", "i", "t" }, -- Modes where habits are ignored
        
        -- List of bad habits (keys/sequences) that Hardtime will punish
        disable_keys = {
            -- Disables the arrow keys for motion (forcing hjkl)
            ["<up>"] = true,
            ["<down>"] = true,
            ["<left>"] = true,
            ["<right>"] = true,
            
            -- Disables repeated single-line movements (forces you to use counts like '5j')
            ["j"] = { max_count = 2, max_duration = 500 },
            ["k"] = { max_count = 2, max_duration = 500 },
            
            -- Can be expanded to discourage other inefficient motions like 'l'
        },
    },
    
    config = function(_, opts)
        require("hardtime").setup(opts)
    end,
}

