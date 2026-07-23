-- Metadata
-- languages: nix
-- url: https://github.com/kamadorueda/alejandra

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = nx.await(fs.executable('alejandra'))
  local command = string.format('%s -', nx.await(fs.executable(formatter)))
  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
