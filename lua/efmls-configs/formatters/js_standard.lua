-- Metadata
-- languages: javascript
-- url: http://standardjs.com/

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'standard'
  local command = string.format('%s --fix --stdin', nx.await(fs.executable(formatter, fs.Scope.NODE)))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
