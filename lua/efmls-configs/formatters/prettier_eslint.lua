-- Metadata
-- languages: javascript,typescript
-- url: https://github.com/prettier/prettier-eslint

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'prettier-eslint'
  local command =
    string.format("%s --stdin --stdin-filepath '${INPUT}'", btv.await(fs.executable(formatter, fs.Scope.NODE)))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
