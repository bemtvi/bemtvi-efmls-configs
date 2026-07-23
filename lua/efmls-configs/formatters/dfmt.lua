-- Metadata
-- languages: d
-- url: https://github.com/dlang-community/dfmt

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'dfmt'
  local command = string.format('%s -', nx.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
