-- Metadata
-- languages: go
-- url: https://github.com/mvdan/gofumpt

local fs = require('efmls-configs.fs')
return nx.async(function()
  local formatter = nx.await(fs.executable('gofumpt'))

  return {
    formatCommand = formatter,
    formatStdin = true,
  }
end)
