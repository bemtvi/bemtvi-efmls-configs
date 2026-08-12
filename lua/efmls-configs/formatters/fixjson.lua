-- Metadata
-- languages: json
-- url: https://github.com/rhysd/fixjson

local fs = require('efmls-configs.fs')
return btv.async(function()
  local formatter = btv.await(fs.executable('fixjson'))

  return {
    formatCommand = formatter,
    formatStdin = true,
  }
end)
