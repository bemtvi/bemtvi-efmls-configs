-- Metadata
-- languages: php
-- url: https://github.com/phan/phan

local sourceText = require('efmls-configs.utils').sourceText
local fs = require('efmls-configs.fs')

return btv.async(function()
  local linter = 'phan'
  local command =
    string.format('%s --output-mode pylint "${INPUT}"', btv.await(fs.executable(linter, fs.Scope.COMPOSER)))

  return {
    prefix = linter,
    lintSource = sourceText(linter),
    lintCommand = command,
    lintStdin = true,
    lintFormats = { '%.%#:%l: [%t%.%#] %m (at column %c)' },
    rootMarkers = { '.phan/config.php', 'composer.json' },
  }
end)
