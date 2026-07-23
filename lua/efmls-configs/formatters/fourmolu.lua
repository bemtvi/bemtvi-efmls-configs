-- Metadata
-- languages: haskell
-- url: https://github.com/fourmolu/fourmolu

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'fourmolu'
  local command = string.format("%s --stdin-input-file '${INPUT}' -", nx.await(fs.executable(formatter)))

  return {
    prefix = formatter,
    formatCommand = command,
    formatStdin = true,
  }
end)
