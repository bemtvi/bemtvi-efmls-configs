-- Metadata
-- languages: clojure
-- url: https://github.com/candid82/joker

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'joker'
  local command = string.format("%s --format '${INPUT}'", btv.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
