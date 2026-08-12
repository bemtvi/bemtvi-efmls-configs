-- Metadata
-- languages: sql
-- url: https://github.com/quarylabs/sqruff

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'sqruff'
  local args = 'fix -'
  local command = string.format('%s %s', btv.await(fs.executable(formatter)), args)

  return {
    formatCommand = command,
    formatStdin = true,
    rootMarkers = { '.sqruff' },
  }
end)
