-- Metadata
-- languages: json
-- url: https://github.com/rhysd/fixjson

local fs = require('efmls-configs.fs')
return nx.async(function()
  local formatter = nx.await(fs.executable('fixjson'))

  return {
    formatCommand = formatter,
    formatStdin = true,
  }
end)
