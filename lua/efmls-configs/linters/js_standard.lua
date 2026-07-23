-- Metadata
-- languages: javascript
-- url: http://standardjs.com/

local sourceText = require('efmls-configs.utils').sourceText
local fs = require('efmls-configs.fs')

return nx.async(function()
  local linter = 'standard'
  local command = string.format('%s --stdin', nx.await(fs.executable(linter, fs.Scope.NODE)))

  return {
    prefix = linter,
    lintSource = sourceText(linter),
    lintCommand = command,
    lintStdin = true,
    lintFormats = { '%.%#:%l:%c: %m' },
    rootMarkers = { 'package.json' },
  }
end)
