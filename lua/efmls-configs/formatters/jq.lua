-- Metadata
-- languages: json
-- url: https://jqlang.github.io/jq/

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'jq'
  local command = string.format('%s', nx.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
