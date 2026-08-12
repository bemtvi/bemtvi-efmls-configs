-- Metadata
-- languages: markdown
-- url: https://github.com/lukas-reineke/cbfmt

local fs = require('efmls-configs.fs')
return btv.async(function()
  local formatter = btv.await(fs.executable('cbfmt'))
  local command = string.format("%s --stdin-filepath '${INPUT}' --best-effort", formatter)

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
