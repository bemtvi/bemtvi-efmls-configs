-- Metadata
-- languages: misc
-- url: https://github.com/ValeLint/vale

local sourceText = require('efmls-configs.utils').sourceText
local fs = require('efmls-configs.fs')

return btv.async(function()
  local linter = 'vale'
  local command = string.format('%s --output=line ${INPUT}', btv.await(fs.executable(linter)))

  return {
    prefix = linter,
    lintSource = sourceText(linter),
    lintCommand = command,
    lintStdin = false,
    lintFormats = { '%f:%l:%c:%m' },
    rootMarkers = { '.vale.ini' },
  }
end)
