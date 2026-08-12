-- Metadata
-- languages: typst
-- url: https://github.com/antonWetzel/prettypst

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = btv.await(fs.executable('prettypst'))
  local command = string.format('%s --use-std-in --use-std-out', btv.await(fs.executable(formatter)))
  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
