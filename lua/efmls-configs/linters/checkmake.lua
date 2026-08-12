-- Metadata
-- languages: make
-- url: https://github.com/mrtazz/checkmake

local sourceText = require('efmls-configs.utils').sourceText
local fs = require('efmls-configs.fs')

return btv.async(function()
  local linter = 'checkmake'
  local command = string.format(
    '%s --format=\'{{.LineNumber}}:{{.Violation}} ({{.Rule}})\n\' "${INPUT}"',
    btv.await(fs.executable(linter))
  )

  return {
    prefix = linter,
    lintSource = sourceText(linter),
    lintCommand = command,
    lintStdin = false,
    lintFormats = { '%l:%m' },
    rootMarkers = {},
  }
end)
