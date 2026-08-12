-- Metadata
-- languages: typescript, javascript, json
-- url: https://github.com/rome/tools

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'rome'
  local args = "format --stdin-file-path '${INPUT}'"
  local command = string.format('%s %s', btv.await(fs.executable(formatter, fs.Scope.NODE)), args)

  return {
    formatCommand = command,
    formatStdin = true,
    rootMarkers = { 'rome.json' },
  }
end)
