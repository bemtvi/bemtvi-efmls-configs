-- Metadata
-- languages: swift
-- url: https://github.com/nicklockwood/SwiftFormat

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'swiftformat'
  local command =
    string.format('%s stdin --output stdout --quiet --stdinpath "${INPUT}"', nx.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
