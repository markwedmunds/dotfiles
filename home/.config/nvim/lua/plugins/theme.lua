return {
  {
    'ellisonleao/gruvbox.nvim',
    name = 'gruvbox',        -- match the wezterm color_scheme
    priority = 1000,         -- load before any other plugin draws UI
    lazy = false,
    opts = {
      contrast = 'hard',     -- gruvbox dark, hard - same as wezterm
      transparent_mode = true, -- let the terminal opacity/blur show through
    },
    config = function(_, opts)
      require('gruvbox').setup(opts)
      vim.o.background = 'dark'
      vim.cmd('colorscheme gruvbox')
    end,
  },
}
