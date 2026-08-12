-- Metadata
-- languages: blade
-- url: https://github.com/shufo/blade-formatter

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'blade-formatter'
  local command = string.format('%s --stdin', btv.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
