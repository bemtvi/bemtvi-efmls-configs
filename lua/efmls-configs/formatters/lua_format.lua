-- Metadata
-- languages: lua
-- url: https://github.com/Koihik/LuaFormatter

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'lua-format'
  local command = string.format("%s '${INPUT}'", nx.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
