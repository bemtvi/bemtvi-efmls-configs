-- Metadata
-- languages: misc
-- url: http://redpen.cc/

local sourceText = require('efmls-configs.utils').sourceText
local fs = require('efmls-configs.fs')

return btv.async(function()
  local linter = 'redpen'
  local command = string.format('%s ${FILENAME}', btv.await(fs.executable(linter)))

  return {
    prefix = linter,
    lintSource = sourceText(linter),
    lintCommand = command,
    lintStdin = false,
    lintFormats = { '%f:%l: %m' },
    rootMarkers = {},
  }
end)
