-- save by pressing Escape
vim.keymap.set('n', '<Esc>', ':w<CR>', { desc = 'Save' })
-- select all
vim.keymap.set('n', '<C-a>', 'ggVG', { desc = 'Select All' })
-- pasting over a selection no longer clobbers your clipboard
vim.cmd([[ xnoremap <expr> p 'pgv"'.v:register.'y' ]])

-- <leader>rr runs the current Swift file with the `swift` interpreter in a split
-- terminal - a quick playground loop for interactive learning. Buffer-local so it
-- only exists in Swift buffers, where `%` (the current file) is what we want to run.
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'swift',
  callback = function(args)
    vim.keymap.set('n', '<leader>rr', function()
      vim.cmd('write')                       -- save first so we run the latest edits
      vim.cmd('vsplit | terminal swift ' .. vim.fn.shellescape(vim.fn.expand('%')))
      vim.cmd('startinsert')                 -- drop into the terminal to see output/scroll
    end, { buffer = args.buf, desc = 'Swift: Run file' })
  end,
})

-- <leader>rt opens a bare `swift` REPL in a split terminal for line-by-line
-- experimenting. Global (not buffer-local) so you can summon it from any buffer -
-- the REPL needs no file, so requiring a Swift buffer first would be a chicken-and-egg.
vim.keymap.set('n', '<leader>rt', function()
  vim.cmd('vsplit | terminal swift')
  vim.cmd('startinsert')
end, { desc = 'Swift: REPL' })

