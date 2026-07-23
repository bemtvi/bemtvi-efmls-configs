-- Metadata
-- languages: python
-- url: https://github.com/astral-sh/ruff

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'ruff'
  local args = "format --no-cache --stdin-filename '${INPUT}'"
  local command = string.format('%s %s', nx.await(fs.executable(formatter)), args)

  return {
    formatCommand = command,
    formatStdin = true,
    rootMarkers = {
      'pyproject.toml',
      'setup.py',
      'requirements.txt',
      'ruff.toml',
    },
  }
end)
