-- Metadata
-- languages: blade
-- url: https://github.com/shufo/blade-formatter

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'blade-formatter'
  local command = string.format('%s --stdin', nx.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
