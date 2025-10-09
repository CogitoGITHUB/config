return {
  "nvim-treesitter/nvim-treesitter",
  -- Execute the build command on installation/update to compile parsers
  build = ":TSUpdate",
  -- Load the plugin when Neovim starts
  event = "VeryLazy",
  
  -- Treesitter configuration setup
  config = function()
    require('nvim-treesitter.configs').setup {
      -- List of parsers to ensure are installed
      ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline", "latex" },

      -- Install parsers synchronously (false is recommended)
      sync_install = false,

      -- Automatically install missing parsers when entering buffer
      auto_install = true,

      -- List of parsers to ignore installing
      ignore_install = { "javascript" },

      highlight = {
        enable = true,

        -- Function to disable highlighting for large files (100 KB limit)
        disable = function(lang, buf)
          local max_filesize = 100 * 1024 -- 100 KB
          local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stats and stats.size > max_filesize then
            return true
          end
          return false
        end,

        -- Do not use Neovim's built-in syntax highlighting alongside Treesitter
        additional_vim_regex_highlighting = false,
      },
      
      -- Optional, but highly recommended, to enable text objects for faster motions
      textobjects = { enable = true },
    }
  end,
}
