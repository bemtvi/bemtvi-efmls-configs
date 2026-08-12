-- Metadata
-- languages: python
-- url: https://github.com/hhatto/autopep8

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'autopep8'
  local command = string.format('%s -', btv.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
