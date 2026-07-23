-- Metadata
-- languages: python,go,php,html
-- url: https://djlint.com/

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'djlint'
  local args = '--reformat -'
  local command = string.format('%s %s', nx.await(fs.executable(formatter)), args)

  return {
    formatCommand = command,
    formatStdin = true,
    rootMarkers = {
      '.djlintrc',
      'pyproject.toml',
    },
  }
end)
