-- Metadata
-- languages: cmake
-- url: https://github.com/BlankSpruce/gersemi

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'gersemi'
  local command = string.format('%s -', nx.await(fs.executable(formatter)))

  return {
    prefix = formatter,
    formatCommand = command,
    formatStdin = true,
  }
end)
