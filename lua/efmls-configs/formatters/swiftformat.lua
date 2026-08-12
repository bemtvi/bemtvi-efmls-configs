-- Metadata
-- languages: swift
-- url: https://github.com/nicklockwood/SwiftFormat

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'swiftformat'
  local command =
    string.format('%s stdin --output stdout --quiet --stdinpath "${INPUT}"', btv.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
