-- Metadata
-- languages: sql
-- url: https://github.com/sql-formatter-org/sql-formatter

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'sql-formatter'
  local command = string.format('%s', nx.await(fs.executable(formatter, fs.Scope.NODE)))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
