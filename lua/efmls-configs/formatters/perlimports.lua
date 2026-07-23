local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'perlimports'
  local args = "--read-stdin --filename '${INPUT}'"
  local command = string.format('%s %s', nx.await(fs.executable(formatter)), args)

  return {
    formatCommand = command,
    formatStdin = true,
    rootMarkers = { '.git' },
  }
end)
