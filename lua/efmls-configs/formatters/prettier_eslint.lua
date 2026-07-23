-- Metadata
-- languages: javascript,typescript
-- url: https://github.com/prettier/prettier-eslint

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'prettier-eslint'
  local command =
    string.format("%s --stdin --stdin-filepath '${INPUT}'", nx.await(fs.executable(formatter, fs.Scope.NODE)))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
