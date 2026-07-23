-- Metadata
-- languages: bash
-- url: https://github.com/openstack/bashate

local sourceText = require('efmls-configs.utils').sourceText
local fs = require('efmls-configs.fs')

return nx.async(function()
  local linter = 'bashate'
  local command = string.format('%s -', nx.await(fs.executable(linter)))

  return {
    prefix = linter,
    lintSource = sourceText(linter),
    lintCommand = command,
    lintStdin = true,
    lintFormats = { '-:%l:%c: %t%m' },
    rootMarkers = {},
  }
end)
