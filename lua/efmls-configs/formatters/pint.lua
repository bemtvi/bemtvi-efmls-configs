-- Metadata
-- languages: php
-- url: https://github.com/laravel/pint

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'pint'
  local args = "'${INPUT}'"
  local command = string.format('%s %s', btv.await(fs.executable(formatter, fs.Scope.COMPOSER)), args)

  return {
    formatCommand = command,
    formatStdin = false,
  }
end)
