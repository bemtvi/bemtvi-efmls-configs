-- Metadata
-- languages: php
-- url: https://github.com/PHP-CS-Fixer/PHP-CS-Fixer

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'php-cs-fixer'
  local args = "fix --no-ansi --using-cache=no --quiet '${INPUT}'"
  local command = string.format('%s %s', nx.await(fs.executable(formatter, fs.Scope.COMPOSER)), args)

  return {
    formatCommand = command,
    formatStdin = false,
  }
end)
