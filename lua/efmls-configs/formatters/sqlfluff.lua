-- Metadata
-- languages: sql
-- url: https://github.com/sql-formatter-org/sql-formatter

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'sqlfluff'
  local command = string.format(
    '%s format --dialect ansi --nocolor --ignore ${INPUT}',
    btv.await(fs.executable(formatter, fs.Scope.NODE))
  )

  return {
    formatCommand = command,
    formatStdin = false,
  }
end)
