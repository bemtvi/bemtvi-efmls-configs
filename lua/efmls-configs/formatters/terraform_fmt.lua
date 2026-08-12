-- Metadata
-- languages: terraform
-- url: https://github.com/hashicorp/terraform

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'terraform'
  local args = 'fmt -'
  local command = string.format('%s %s', btv.await(fs.executable(formatter)), args)

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
