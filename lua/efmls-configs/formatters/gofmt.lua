-- Metadata
-- languages: go
-- url: https://pkg.go.dev/cmd/gofmt

local fs = require('efmls-configs.fs')
return btv.async(function()
  local formatter = btv.await(fs.executable('gofmt'))

  return {
    formatCommand = formatter,
    formatStdin = true,
  }
end)
