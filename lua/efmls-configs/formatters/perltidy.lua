local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'perltidy'
  local command = string.format('%s --quiet', btv.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = true,
    rootMarkers = { '.git' },
  }
end)
