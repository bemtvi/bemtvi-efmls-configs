-- Metadata
-- languages: sh, bash, zsh, csh, ksh
-- url: https://github.com/illvart/beautysh-action

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'beautysh'
  local command = string.format('%s -', btv.await(fs.executable(formatter)))

  return {
    prefix = formatter,
    formatCommand = command,
    formatStdin = true,
  }
end)
