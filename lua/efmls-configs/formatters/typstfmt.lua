-- Metadata
-- languages: typst
-- url: https://github.com/astrale-sharp/typstfmt

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = nx.await(fs.executable('typstfmt'))
  local command = string.format('%s -o -', nx.await(fs.executable(formatter)))
  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
