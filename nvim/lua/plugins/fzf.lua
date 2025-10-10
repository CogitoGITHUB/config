-- /nvim/lua/plugins/fzf.lua

-- Get the raw string of default options from your shell environment.
local fzf_default_opts = vim.env.FZF_DEFAULT_OPTS

return {
  "ibhagwan/fzf-lua",
  -- Dependency is removed

  config = function()
    require("fzf-lua").setup({
      -- CRITICAL 1: Pass the shell environment options for colors/layout
      fzf_args = fzf_default_opts,

      -- CRITICAL 2: Ensure no icons are rendered
      files = {
        file_icons = false,  -- Explicitly disable file icons
        color_icons = false, -- Explicitly disable color icons
      },

      -- Define the previewer to match the shell's simple 'cat'
      previewers = {
        cat = {
          cmd = "cat",
          args = { "{}" },
        },
      },

      -- Configure the main window for full-screen in Neovim
      winopts = {
        width = 1.0,        -- 100% width of the Neovim window
        height = 1.0,       -- 100% height of the Neovim window
        row = 0,            -- Start at the top edge
        col = 0,            -- Start at the left edge

        -- Configure the preview window within the FZF fullscreen window
        preview = {
          default = 'cat',        -- Use the 'cat' previewer
          layout = 'right',       -- Position on the right
          width = '60%',          -- Occupy 60% of the screen
          border = 'rounded',     -- Use rounded border
        },
      },
    })

    -- Add the keymap
    vim.keymap.set('n', '<Leader>f', function()
      require("fzf-lua").files()
    end, { desc = 'Fzf-Lua Find Files' })

  end
}
