-- Metadata
-- languages: php
-- url: https://github.com/squizlabs/PHP_CodeSniffer

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'phpcbf'
  local command = string.format('%s -', nx.await(fs.executable(formatter, fs.Scope.COMPOSER)))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
