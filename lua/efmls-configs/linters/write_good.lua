-- Metadata
-- languages: misc
-- url: https://github.com/btford/write-good

local sourceText = require('efmls-configs.utils').sourceText
local fs = require('efmls-configs.fs')

return btv.async(function()
  local linter = 'write-good'
  local command = string.format('%s ${INPUT}', btv.await(fs.executable(linter, fs.Scope.NODE)))

  return {
    prefix = linter,
    lintSource = sourceText(linter),
    lintCommand = command,
    lintStdin = false,
    lintFormats = { '%m on line %l at column %c' },
    rootMarkers = {},
  }
end)
