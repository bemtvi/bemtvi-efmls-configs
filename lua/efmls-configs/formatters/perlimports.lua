local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'perlimports'
  local args = "--read-stdin --filename '${INPUT}'"
  local command = string.format('%s %s', btv.await(fs.executable(formatter)), args)

  return {
    formatCommand = command,
    formatStdin = true,
    rootMarkers = { '.git' },
  }
end)
