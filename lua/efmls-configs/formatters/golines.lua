-- Metadata
-- languages: go
-- url: https://github.com/segmentio/golines

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'golines'
  local command = string.format('%s', nx.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
