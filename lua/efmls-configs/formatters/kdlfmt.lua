-- Metadata
-- languages: kdl
-- url: https://github.com/hougesen/kdlfmt

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'kdlfmt'
  local args = 'format -'
  local command = string.format('%s %s', btv.await(fs.executable(formatter)), args)

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
