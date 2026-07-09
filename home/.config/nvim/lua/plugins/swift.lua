return {
  -- Swift syntax highlighting. The `main` branch is the only one that supports
  -- Neovim 0.11+; the legacy `master` branch crashes the conceal_line highlighter
  -- on 0.12 (its query predicates use the old match-table format).
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    lazy = false,
    config = function()
      -- main branch installs parsers imperatively and does not auto-enable
      -- highlighting - we start treesitter per buffer via a FileType autocmd.
      require('nvim-treesitter').install({ 'swift', 'objc' })
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'swift', 'objc', 'objcpp' },
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })
    end,
  },
  -- Build, run and test iOS/macOS apps without leaving Neovim.
  -- Run :XcodebuildSetup once per project, then :XcodebuildPicker for actions.
  {
    'wojciech-kulik/xcodebuild.nvim',
    dependencies = { 'MunifTanjim/nui.nvim' },  -- snacks.nvim (already installed) supplies the picker
    cmd = {
      'XcodebuildSetup',
      'XcodebuildPicker',
      'XcodebuildBuild',
      'XcodebuildBuildRun',
      'XcodebuildTest',
      'XcodebuildSelectDevice',
      'XcodebuildToggleLogs',
      'XcodebuildStop',
    },
    ft = 'swift',
    keys = {
      { '<leader>xl', '<cmd>XcodebuildToggleLogs<cr>',   desc = 'Xcode: Toggle Logs' },
      { '<leader>xb', '<cmd>XcodebuildBuild<cr>',        desc = 'Xcode: Build Project' },
      { '<leader>xr', '<cmd>XcodebuildBuildRun<cr>',     desc = 'Xcode: Build & Run' },
      { '<leader>xt', '<cmd>XcodebuildTest<cr>',         desc = 'Xcode: Run Tests' },
      { '<leader>xd', '<cmd>XcodebuildSelectDevice<cr>', desc = 'Xcode: Select Device' },
      { '<leader>xp', '<cmd>XcodebuildPicker<cr>',       desc = 'Xcode: Show Picker' },
      { '<leader>xX', '<cmd>XcodebuildStop<cr>',         desc = 'Xcode: Stop' },
    },
    config = function()
      require('xcodebuild').setup({})

      -- Xcode 27 renamed the `xcodebuild -showdestinations` header from
      -- "Available destinations for the ... scheme:" to
      -- "Destinations compatible with the ... scheme:" (plus a separate
      -- "Destinations incompatible with ..." section). The bundled parser only
      -- matches the old wording, so the device picker shows up empty.
      -- Override get_destinations to recognise both formats.
      -- TODO: remove once upstream handles the Xcode 27 output.
      local xcode = require('xcodebuild.core.xcode')
      xcode.get_destinations = function(projectFile, scheme, workingDirectory, callback)
        local projectParam = projectFile:match('%.xcworkspace$') and '-workspace' or '-project'
        local command = {
          'xcodebuild',
          projectParam,
          projectFile,
          '-showdestinations',
          '-scheme',
          scheme,
        }

        return vim.fn.jobstart(command, {
          stdout_buffered = true,
          cwd = workingDirectory,
          on_stdout = function(_, output)
            local result = {}
            local foundDestinations = false
            local valuePattern = ':%s*([^@}]-)%s*[@}]'

            for _, line in ipairs(output) do
              local trimmedLine = vim.trim(line)

              if foundDestinations and trimmedLine == '' then
                -- Blank line ends the "compatible" block before the
                -- "incompatible" section, so incompatible devices are skipped.
                break
              elseif foundDestinations and vim.startswith(trimmedLine, '{') then
                local sanitizedLine = string.gsub(trimmedLine, ', ', '@')
                local destination = {
                  platform = string.match(sanitizedLine, 'platform' .. valuePattern),
                  variant = string.match(sanitizedLine, 'variant' .. valuePattern),
                  arch = string.match(sanitizedLine, 'arch' .. valuePattern),
                  id = string.match(sanitizedLine, 'id' .. valuePattern),
                  name = string.match(sanitizedLine, 'name' .. valuePattern),
                  os = string.match(sanitizedLine, 'OS' .. valuePattern),
                  error = string.match(sanitizedLine, 'error' .. valuePattern),
                }

                if destination.platform and destination.id and destination.name then
                  table.insert(result, destination)
                end
              elseif
                string.find(trimmedLine, 'Available destinations')
                or string.find(trimmedLine, 'Destinations compatible')
              then
                foundDestinations = true
              end
            end

            callback(result)
          end,
        })
      end
    end,
  },
}
