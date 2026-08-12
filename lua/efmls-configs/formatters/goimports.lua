-- Metadata
-- languages: go
-- url: https://godoc.org/golang.org/x/tools/cmd/goimports

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'goimports'
  local command = string.format('%s', btv.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
