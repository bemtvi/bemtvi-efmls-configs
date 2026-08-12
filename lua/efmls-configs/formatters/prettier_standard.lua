-- Metadata
-- languages: javascript,typescript
-- url: https://github.com/sheerun/prettier-standard

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'prettier-standard'
  local command = string.format('%s --stdin', btv.await(fs.executable(formatter, fs.Scope.NODE)))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
