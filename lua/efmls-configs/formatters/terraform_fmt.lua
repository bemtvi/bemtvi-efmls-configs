-- Metadata
-- languages: terraform
-- url: https://github.com/hashicorp/terraform

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'terraform'
  local args = 'fmt -'
  local command = string.format('%s %s', nx.await(fs.executable(formatter)), args)

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
