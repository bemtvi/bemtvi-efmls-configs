-- Metadata
-- languages: yaml
-- url: https://github.com/willthames/ansible-lint

local sourceText = require('efmls-configs.utils').sourceText
local fs = require('efmls-configs.fs')

return nx.async(function()
  local linter = 'ansible-lint'
  local command = string.format('%s --nocolor -', nx.await(fs.executable(linter)))

  return {
    prefix = linter,
    lintSource = sourceText(linter),
    lintCommand = command,
    lintStdin = true,
    lintFormats = { 'stdin:%l:%c [%tRROR]: %m', 'stdin:%l:%c [%tARNING]: %m' },
    rootMarkers = { '.ansible-lint' },
  }
end)
