-- Metadata
-- languages: javascript,typescript
-- url: https://github.com/sindresorhus/xo

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'xo'
  local command = string.format('%s --fix --stdin', nx.await(fs.executable(formatter, fs.Scope.NODE)))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
