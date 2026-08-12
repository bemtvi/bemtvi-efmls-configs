-- Metadata
-- languages: misc
-- url: https://github.com/crate-ci/typos

local sourceText = require('efmls-configs.utils').sourceText
local fs = require('efmls-configs.fs')

return btv.async(function()
  local linter = 'typos'

  local command = string.format('%s --format brief --color never -', btv.await(fs.executable(linter)))

  return {
    prefix = linter,
    lintSource = sourceText(linter),
    lintCommand = command,
    lintIgnoreExitCode = true,
    lintStdin = true,
    lintFormats = { '%f:%l:%c: %trror: %m' },
  }
end)
