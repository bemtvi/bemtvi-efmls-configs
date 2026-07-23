-- Metadata
-- languages: crystal
-- url: https://github.com/veelenga/ameba

local sourceText = require('efmls-configs.utils').sourceText
local fs = require('efmls-configs.fs')

return nx.async(function()
  local linter = 'ameba'
  local command = string.format('%s --no-color --format flycheck "${INPUT}"', nx.await(fs.executable(linter)))

  return {
    prefix = linter,
    lintSource = sourceText(linter),
    lintCommand = command,
    lintStdin = false,
    lintIgnoreExitCode = true,
    lintFormats = { '%.%#:%l:%c: %t: %m' },
    rootMarkers = { '.ameba.yml' },
  }
end)
