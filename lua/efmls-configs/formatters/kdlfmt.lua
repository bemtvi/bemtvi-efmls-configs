-- Metadata
-- languages: kdl
-- url: https://github.com/hougesen/kdlfmt

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'kdlfmt'
  local args = 'format -'
  local command = string.format('%s %s', nx.await(fs.executable(formatter)), args)

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
