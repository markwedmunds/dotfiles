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
      local gruvbox = require('gruvbox')
      -- transparent_mode also clears NormalFloat, which is the background of every
      -- floating window - including the completion documentation popup and LSP hover.
      -- Over a transparent editor that text bleeds into the code underneath and is
      -- hard to read, so give floats a solid background while the editor itself
      -- (Normal) stays transparent for the terminal blur.
      opts.overrides = vim.tbl_extend('force', opts.overrides or {}, {
        NormalFloat = { bg = gruvbox.palette.dark1 },
      })
      gruvbox.setup(opts)
      vim.o.background = 'dark'
      vim.cmd('colorscheme gruvbox')
    end,
  },
}
