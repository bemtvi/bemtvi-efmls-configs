-- Metadata
-- languages: python
-- url: https://pycqa.github.io/isort/

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'isort'
  local command = string.format('%s --quiet -', nx.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = true,
    rootMarkers = {
      '.isort.cfg',
      'pyproject.toml',
      'setup.cfg',
      'setup.py',
    },
  }
end)
