-- Metadata
-- languages: cmake
-- url: https://github.com/BlankSpruce/gersemi

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'gersemi'
  local command = string.format('%s -', btv.await(fs.executable(formatter)))

  return {
    prefix = formatter,
    formatCommand = command,
    formatStdin = true,
  }
end)
