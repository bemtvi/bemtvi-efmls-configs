-- Metadata
-- languages: scala
-- url: https://scalameta.org/scalafmt/

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'scalafmt'
  local args = '--stdin'
  local command = string.format('%s %s', btv.await(fs.executable(formatter)), args)

  return {
    formatCanRange = true,
    formatCommand = command,
    formatStdin = true,
  }
end)
