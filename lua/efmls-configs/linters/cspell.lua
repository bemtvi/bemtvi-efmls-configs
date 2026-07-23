-- Metadata
-- languages: misc
-- url: https://github.com/streetsidesoftware/cspell

local sourceText = require('efmls-configs.utils').sourceText
local fs = require('efmls-configs.fs')

return nx.async(function()
  local linter = 'cspell'

  local command = string.format('%s --no-color --no-progress --no-summary "${INPUT}"', nx.await(fs.executable(linter)))

  return {
    prefix = linter,
    lintSource = sourceText(linter),
    lintCommand = command,
    lintIgnoreExitCode = true,
    lintStdin = false,
    lintFormats = { '%f:%l:%c - %m', '%f:%l:%c %m' },
    -- cspell does not use any severity levels, use INFO level by default
    lintSeverity = 3,
  }
end)
