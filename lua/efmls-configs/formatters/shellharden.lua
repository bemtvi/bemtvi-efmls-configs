-- Metadata
-- languages: sh
-- url: https://github.com/anordal/shellharden

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'shellharden'
  local args = "--transform ''" -- '' = stdin usage
  local command = string.format('%s %s', btv.await(fs.executable(formatter)), args)

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
