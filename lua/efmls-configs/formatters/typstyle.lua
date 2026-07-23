-- Metadata
-- languages: typst
-- url: https://github.com/Enter-tainer/typstyle

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = nx.await(fs.executable('typstyle'))
  local command = nx.await(fs.executable(formatter))
  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
