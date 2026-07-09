-- Native LSP for Swift via sourcekit-lsp (ships with Xcode, no plugin needed).
-- Neovim 0.11+ provides default LSP keymaps out of the box:
--   K hover, grn rename, gra code action, grr references, gri implementation.
-- (gd is already bound to Snacks.picker.lsp_definitions in plugins/ui.lua.)
vim.lsp.config('sourcekit', {
  cmd = { 'xcrun', 'sourcekit-lsp' },
  filetypes = { 'swift', 'objc', 'objcpp' },
  -- buildServer.json comes from xcode-build-server for .xcodeproj/.xcworkspace;
  -- Package.swift covers plain SPM packages.
  root_markers = { 'buildServer.json', 'Package.swift', '.git' },
})
vim.lsp.enable('sourcekit')

-- Lua, tuned for editing this Neovim config: teach it about the `vim` global and
-- the runtime files so it stops flagging them as undefined.
vim.lsp.config('lua_ls', {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { '.luarc.json', '.luarc.jsonc', '.git' },
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim' } },
      workspace = {
        library = vim.api.nvim_get_runtime_file('', true),
        checkThirdParty = false,
      },
      telemetry = { enable = false },
    },
  },
})
vim.lsp.enable('lua_ls')

-- Nix, for this flake and the home-manager config.
vim.lsp.config('nixd', {
  cmd = { 'nixd' },
  filetypes = { 'nix' },
  root_markers = { 'flake.nix', '.git' },
})
vim.lsp.enable('nixd')

-- Built-in autocompletion, driven by the LSP - no completion plugin required.
-- menuone keeps the menu open for a single match; noselect leaves the choice to
-- you; fuzzy allows non-prefix matches. Without these the menu barely shows up.
vim.o.completeopt = 'menu,menuone,noselect,popup,fuzzy'

-- Cap the completion menu width. Swift's LSP returns very long signatures (e.g.
-- accessibilityActivationPoint(activationPoint: UnitPoint, isEnabled: Bool)),
-- and without a limit the menu grows to fill the screen, squashing the `popup`
-- documentation window into an unreadable sliver. Long items get truncated with
-- the 'truncate' fillchar, leaving room for the doc window alongside.
vim.o.pummaxwidth = 45

-- Frame the completion menu and its documentation popup with a border. Together with
-- the solid NormalFloat background (see plugins/theme.lua) this gives the doc window a
-- bit of breathing room so it reads as a distinct panel instead of loose text over the
-- code. |hl-PmenuBorder| draws the border, inherited from the gruvbox theme.
vim.o.pumborder = 'rounded'

-- Guard snippet expansion. Some servers (sourcekit-lsp in particular) return
-- completion snippets whose syntax Neovim's strict parser rejects, raising
-- "snippet parsing failed" the moment a result is selected - which aborts the
-- insertion entirely. On a parse failure, fall back to inserting the snippet's
-- literal text (placeholders kept, tabstops dropped) so selecting always works.
-- vim.snippet.expand runs after the completed word has been cleared, with the
-- cursor where the snippet should go, so we insert plain text at the cursor.
local expand_snippet = vim.snippet.expand
vim.snippet.expand = function(input)
  if pcall(expand_snippet, input) then
    return
  end
  local text = input
    :gsub('%${%d+:(.-)}', '%1')          -- ${1:placeholder} -> placeholder
    :gsub('%${%d+|([^,|]*).-|}', '%1')   -- ${1|a,b,c|} -> a (first choice)
    :gsub('%${%d+}', '')                 -- ${1}, ${0} -> ""
    :gsub('%$%d+', '')                   -- $1, $0 -> ""
    :gsub('\\(.)', '%1')                 -- unescape \$ \} \\
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local lines = vim.split(text, '\n', { plain = true })
  vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, lines)
  local last = lines[#lines]
  vim.api.nvim_win_set_cursor(0, {
    row + #lines - 1,
    #lines == 1 and col + #last or #last,
  })
end

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
    end
  end,
})

-- autotrigger only fires on the server's trigger characters (e.g. `.`), so bind a
-- key to summon completion while typing a plain identifier.
vim.keymap.set('i', '<C-Space>', vim.lsp.completion.get, { desc = 'Trigger completion' })
