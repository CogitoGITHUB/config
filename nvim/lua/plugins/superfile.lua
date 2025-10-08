return {
    "anaypurohit0907/superfile.nvim",
    main = "superfile",
    opts = { key = false },
    keys = {
        {
            "<leader>f",
            function()
                local cmd = "/run/current-system/sw/bin/superfile "
                vim.cmd("botright split | terminal " .. cmd)
                vim.cmd("startinsert")
            end,
            mode = { "n" },
            desc = "Open Superfile",
            silent = true,
        },
    },
}

