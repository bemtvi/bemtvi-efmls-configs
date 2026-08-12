-- Metadata
-- languages: gleam
-- url: https://gleam.run/language-server/#code-formatting

local fs = require('efmls-configs.fs')
return btv.async(function()
  local formatter = 'gleam'
  local args = 'format --stdin'
  local command = string.format('%s %s', btv.await(fs.executable(formatter)), args)

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
