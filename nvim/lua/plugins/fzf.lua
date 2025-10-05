return {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" }, -- for those pretty file icons
    opts = {
      -- You can add config options here, or leave empty for defaults
      winopts = {
        height = 0.85,
        width = 0.80,
        row = 0.35,
        col = 0.50,
        border = "rounded",
      },
      keybinds = {
        -- Customize fzf-lua default keybindings inside the window
        fzf = {
          ["ctrl-z"] = "abort",
          ["ctrl-u"] = "unix-line-discard",
        },
      },
      -- Example: enable ripgrep for grep searches
      rg_opts = "--hidden --files --follow --no-ignore-vcs",
    },
  }
