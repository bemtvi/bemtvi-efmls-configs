-- Metadata
-- languages: fennel
-- url: https://git.sr.ht/~technomancy/fnlfmt

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'fnlfmt'
  local command = string.format('%s -', btv.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
