-- Metadata
-- languages: dart
-- url: https://github.com/dart-lang/sdk/tree/master/utils/dartfmt

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'dart'
  local command = string.format('%s format --output show', nx.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
