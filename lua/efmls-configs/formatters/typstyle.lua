-- Metadata
-- languages: typst
-- url: https://github.com/Enter-tainer/typstyle

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = btv.await(fs.executable('typstyle'))
  local command = btv.await(fs.executable(formatter))
  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
