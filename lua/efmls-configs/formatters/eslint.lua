-- Metadata
-- languages: javascript,typescript
-- url: https://eslint.org

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'eslint'
  local args = "--fix '${INPUT}'"
  local command = string.format('%s %s', btv.await(fs.executable(formatter, fs.Scope.NODE)), args)

  return {
    formatCommand = command,
    formatStdin = false,
  }
end)
