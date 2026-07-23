-- Metadata
-- languages: javascript,typescript,javascriptreact,typescriptreact
-- url: https://oxc.rs

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'oxfmt'
  local args = "--stdin-filepath '${INPUT}'"
  local command = string.format('%s %s', nx.await(fs.executable(formatter, fs.Scope.NODE)), args)

  return {
    formatCommand = command,
    formatStdin = true,
    rootMarkers = {
      '.oxfmtrc.json',
      '.oxfmtrc.jsonc',
      'oxfmt.config.js',
      'oxfmt.config.cjs',
      'oxfmt.config.mjs',
      'oxfmt.config.ts',
      'oxfmt.config.mts',
      'oxfmt.config.cts',
      'package.json',
    },
  }
end)
