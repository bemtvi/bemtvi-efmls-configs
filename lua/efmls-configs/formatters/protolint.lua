-- Metadata
-- languages: proto
-- url: https://github.com/yoheimuta/protolint

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'protolint'
  local command = string.format("%s lint -fix '${INPUT}'", nx.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = false,
    rootMarkers = {
      '.protolint.yaml',
      '.protolint.yml',
    },
  }
end)
