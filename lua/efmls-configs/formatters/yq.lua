-- Metadata
-- languages: yaml
-- url: https://github.com/mikefarah/yq

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'yq'
  local args = '. "${INPUT}"'
  local command = string.format('%s %s', nx.await(fs.executable(formatter)), args)

  return {
    formatCommand = command,
  }
end)
