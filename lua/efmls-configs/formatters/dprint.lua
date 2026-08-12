-- Metadata
-- languages: javascript,typescript,json,markdown,toml,rust,roslyn
-- url: https://dprint.dev/

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'dprint'
  local command = string.format("%s fmt --stdin '${INPUT}'", btv.await(fs.executable(formatter, fs.Scope.NODE)))

  return {
    formatCommand = command,
    formatStdin = true,
    rootMarkers = {
      'dprint.json',
      'dprint.jsonc',
      '.dprint.json',
      '.dprint.jsonc',
    },
  }
end)
