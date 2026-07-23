-- Metadata
-- languages: swift
-- url: https://github.com/realm/SwiftLint

local sourceText = require('efmls-configs.utils').sourceText
local fs = require('efmls-configs.fs')

return nx.async(function()
  local linter = 'swiftlint'
  local args = 'lint --use-stdin --quiet'
  local command = string.format('%s %s', nx.await(fs.executable(linter, fs.Scope.NODE)), args)

  return {
    prefix = linter,
    lintSource = sourceText(linter),
    lintCommand = command,
    lintStdin = true,
    lintIgnoreExitCode = true,
    lintFormats = {
      '%.%#:%l:%c: %trror: %m',
      '%.%#:%l:%c: %tarning: %m',
    },
    rootMarkers = { '.swiftlint.yml' },
  }
end)
