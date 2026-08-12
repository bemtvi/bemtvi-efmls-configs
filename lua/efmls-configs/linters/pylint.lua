-- Metadata
-- languages: python
-- url: https://www.pylint.org/

local sourceText = require('efmls-configs.utils').sourceText
local fs = require('efmls-configs.fs')

return btv.async(function()
  local linter = 'pylint'
  local command = string.format('%s --score=no "${INPUT}"', btv.await(fs.executable(linter)))

  return {
    prefix = linter,
    lintSource = sourceText(linter),
    lintCommand = command,
    lintStdin = false,
    lintFormats = { '%.%#:%l:%c: %t%.%#: %m' },
    rootMarkers = {},
  }
end)
