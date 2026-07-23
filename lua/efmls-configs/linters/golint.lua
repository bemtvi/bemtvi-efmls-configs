-- Metadata
-- languages: go
-- url: https://godoc.org/github.com/golang/lint

local sourceText = require('efmls-configs.utils').sourceText
local fs = require('efmls-configs.fs')

return nx.async(function()
  local linter = 'golint'
  local command = string.format('%s -', nx.await(fs.executable(linter)))

  return {
    prefix = linter,
    lintSource = sourceText(linter),
    lintCommand = command,
    lintStdin = true,
    lintFormats = { '%.%#:%l:%c: %m' },
    rootMarkers = {},
  }
end)
