-- Metadata
-- languages: sh
-- url: https://github.com/anordal/shellharden

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'shellharden'
  local args = "--transform ''" -- '' = stdin usage
  local command = string.format('%s %s', nx.await(fs.executable(formatter)), args)

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
