-- Metadata
-- languages: tex
-- url: https://github.com/cmhughes/latexindent.pl

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'latexindent'
  local command = string.format('%s -', btv.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
