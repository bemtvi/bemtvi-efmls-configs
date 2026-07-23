-- Metadata
-- languages: typescript, javascript, json, jsonc
-- url: https://biomejs.dev/

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'biome'
  local args = "check --write --stdin-file-path '${INPUT}'"
  local command = string.format('%s %s', nx.await(fs.executable(formatter, fs.Scope.NODE)), args)

  return {
    formatCommand = command,
    formatStdin = true,
    rootMarkers = { 'rome.json', 'biome.json', 'package.json', 'Biomefile' },
  }
end)
