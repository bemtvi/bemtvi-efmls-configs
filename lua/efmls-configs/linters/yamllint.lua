-- Metadata
-- languages: yaml
-- url: https://yamllint.readthedocs.io/

local sourceText = require('efmls-configs.utils').sourceText
local fs = require('efmls-configs.fs')

return btv.async(function()
  local linter = 'yamllint'
  local args = '-f parsable -'
  local command = string.format('%s %s', btv.await(fs.executable(linter)), args)

  return {
    prefix = linter,
    lintSource = sourceText(linter),
    lintCommand = command,
    lintStdin = true,
  }
end)
