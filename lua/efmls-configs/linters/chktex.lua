-- Metadata
-- languages: tex
-- url: https://www.nongnu.org/chktex/

local sourceText = require('efmls-configs.utils').sourceText
local fs = require('efmls-configs.fs')

return btv.async(function()
  local linter = 'chktex'
  local command = string.format('%s -q -v0', btv.await(fs.executable(linter)))

  return {
    prefix = linter,
    lintSource = sourceText(linter),
    lintStdin = true,
    lintCommand = command,
    lintIgnoreExitCode = true,
    lintFormats = { '%f:%l:%c:%n:%m' },
    lintSeverity = 2,
  }
end)
