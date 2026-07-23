-- Metadata
-- languages: sql
-- url: https://github.com/quarylabs/sqruff

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'sqruff'
  local args = 'fix -'
  local command = string.format('%s %s', nx.await(fs.executable(formatter)), args)

  return {
    formatCommand = command,
    formatStdin = true,
    rootMarkers = { '.sqruff' },
  }
end)
