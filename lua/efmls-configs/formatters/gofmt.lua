-- Metadata
-- languages: go
-- url: https://pkg.go.dev/cmd/gofmt

local fs = require('efmls-configs.fs')
return nx.async(function()
  local formatter = nx.await(fs.executable('gofmt'))

  return {
    formatCommand = formatter,
    formatStdin = true,
  }
end)
