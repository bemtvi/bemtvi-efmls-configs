-- Metadata
-- languages: typst
-- url: https://github.com/astrale-sharp/typstfmt

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = btv.await(fs.executable('typstfmt'))
  local command = string.format('%s -o -', btv.await(fs.executable(formatter)))
  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
