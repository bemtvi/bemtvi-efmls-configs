-- Metadata
-- languages: sml
-- url: https://github.com/shwestrick/smlfmt

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'smlfmt'
  local command = nx.await(fs.executable(formatter))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
