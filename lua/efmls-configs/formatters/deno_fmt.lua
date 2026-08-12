-- Metadata
-- languages: javascript,typescript,javascriptreact,typescriptreact
-- url: https://docs.deno.com/runtime/manual/tools/formatter

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'deno'
  local args = 'fmt - --ext ${FILEEXT}'

  local command = string.format('%s %s', btv.await(fs.executable(formatter)), args)

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
