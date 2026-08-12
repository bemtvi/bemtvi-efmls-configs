-- Metadata
-- languages: nix
-- url: https://github.com/kamadorueda/alejandra

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = btv.await(fs.executable('alejandra'))
  local command = string.format('%s -', btv.await(fs.executable(formatter)))
  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
