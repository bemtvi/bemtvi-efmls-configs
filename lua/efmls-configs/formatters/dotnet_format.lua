-- Metadata
-- languages: c#
-- url: https://github.com/dotnet/format

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'dotnet'
  local command = string.format('%s format ${ROOT}', nx.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = false,
  }
end)
