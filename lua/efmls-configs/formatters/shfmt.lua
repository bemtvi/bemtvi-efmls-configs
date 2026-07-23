-- Metadata
-- languages: sh,bash
-- url: https://github.com/mvdan/sh

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'shfmt'
  local command = string.format("%s -filename '${INPUT}' -", nx.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
