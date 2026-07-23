-- Metadata
-- languages: typst
-- url: https://github.com/antonWetzel/prettypst

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = nx.await(fs.executable('prettypst'))
  local command = string.format('%s --use-std-in --use-std-out', nx.await(fs.executable(formatter)))
  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
