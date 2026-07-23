-- Metadata
-- languages: clojure
-- url: https://github.com/candid82/joker

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'joker'
  local command = string.format("%s --format '${INPUT}'", nx.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
