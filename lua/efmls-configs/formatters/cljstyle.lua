-- Metadata
-- languages: clojure
-- url: https://github.com/greglook/cljstyle

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'cljstyle'
  local command = string.format('%s pipe', btv.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
