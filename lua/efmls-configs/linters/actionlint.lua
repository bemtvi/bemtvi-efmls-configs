-- Metadata
-- languages: yaml
-- url: https://github.com/rhysd/actionlint

local sourceText = require('efmls-configs.utils').sourceText
local fs = require('efmls-configs.fs')

return btv.async(function()
  local linter = 'actionlint'
  local command = string.format('%s -no-color -oneline -stdin-filename "${INPUT}" -', btv.await(fs.executable(linter)))

  return {
    prefix = linter,
    lintSource = sourceText(linter),
    lintCommand = command,
    lintStdin = true,
    lintFormats = {
      '%f:%l:%c: %.%#: SC%n:%trror:%m',
      '%f:%l:%c: %.%#: SC%n:%tarning:%m',
      '%f:%l:%c: %.%#: SC%n:%tnfo:%m',
      '%f:%l:%c: %m',
    },
    requireMarker = true,
    rootMarkers = { '.github/' },
  }
end)
