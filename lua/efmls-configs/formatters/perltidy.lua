local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'perltidy'
  local command = string.format('%s --quiet', nx.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = true,
    rootMarkers = { '.git' },
  }
end)
