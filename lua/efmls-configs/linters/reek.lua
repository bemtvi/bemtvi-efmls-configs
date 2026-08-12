-- Metadata
-- languages: ruby
-- url: https://github.com/troessner/reek

local sourceText = require('efmls-configs.utils').sourceText
local fs = require('efmls-configs.fs')

-- TODO: Not properly implemented yet
return btv.async(function()
  local linter = 'reek'
  local args = 'exec reek --format txt --force-exclusion --stdin-filename "${INPUT}"'
  local command = string.format('%s %s', btv.await(fs.executable('bundle', fs.Scope.BUNDLE)), args)

  return {
    prefix = linter,
    lintSource = sourceText(linter),
    lintCommand = command,
    lintStdin = true,
    lintFormats = { '%f:%l:%c: %t: %m' },
    rootMarkers = {},
  }
end)
