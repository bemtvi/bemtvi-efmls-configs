-- Metadata
-- languages: go
-- url: https://github.com/mvdan/gofumpt

local fs = require('efmls-configs.fs')
return btv.async(function()
  local formatter = btv.await(fs.executable('gofumpt'))

  return {
    formatCommand = formatter,
    formatStdin = true,
  }
end)
