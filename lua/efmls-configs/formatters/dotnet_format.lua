-- Metadata
-- languages: c#
-- url: https://github.com/dotnet/format

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'dotnet'
  local command = string.format('%s format ${ROOT}', btv.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = false,
  }
end)
