-- Metadata
-- languages: solidity
-- url: https://github.com/foundry-rs/foundry/tree/master/forge

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'forge'
  local command = string.format('%s fmt --raw -', btv.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = true,
    rootMarkers = { 'foundry.toml' },
  }
end)
