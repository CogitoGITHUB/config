-- LuaSnip Configuration
-- This file defines how snippets are loaded and how they are expanded/navigated.

return {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    build = "make install_jsregexp",
    
    -- Recommended dependencies for better functionality
    dependencies = {
        "rafamadriz/friendly-snippets", -- Provides a large library of pre-made snippets
    },
    
    config = function()
        local luasnip = require("luasnip")
        
        -- Load friendly-snippets (optional but recommended)
        require("luasnip.loaders.from_vscode").lazy_load()

        -- Define keymaps for expanding and navigating snippets
        vim.keymap.set({ "i", "s" }, "<C-k>", function() luasnip.expand_or_jump() end, { silent = true, desc = "LuaSnip: Jump Next" })
        vim.keymap.set({ "i", "s" }, "<C-j>", function() luasnip.jump(-1) end, { silent = true, desc = "LuaSnip: Jump Prev" })

        -- For visual selection:
        vim.keymap.set("s", "<C-k>", function() luasnip.jump_visual() end, { silent = true, desc = "LuaSnip: Jump Visual" })
        
        -- Optional: Setup border/menu behavior
        luasnip.setup({
            history = true, -- Remember last snippet used
            delete_check_events = "TextChanged", -- Fixes issues where placeholders sometimes get deleted unexpectedly
        })
    end,
}

