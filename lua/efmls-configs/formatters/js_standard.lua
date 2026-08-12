-- Metadata
-- languages: javascript
-- url: http://standardjs.com/

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'standard'
  local command = string.format('%s --fix --stdin', btv.await(fs.executable(formatter, fs.Scope.NODE)))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
