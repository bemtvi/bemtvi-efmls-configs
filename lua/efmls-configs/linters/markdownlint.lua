-- Metadata
-- languages: markdown
-- url: https://github.com/DavidAnson/markdownlint

local sourceText = require('efmls-configs.utils').sourceText
local fs = require('efmls-configs.fs')

return btv.async(function()
  local linter = 'markdownlint'
  local command = string.format('%s --stdin', btv.await(fs.executable(linter)))

  return {
    prefix = linter,
    lintSource = sourceText(linter),
    lintCommand = command,
    lintIgnoreExitCode = true,
    lintStdin = true,
    lintFormats = { '%f:%l:%c %m', '%f:%l %m', '%f: %l: %m' },
  }
end)
