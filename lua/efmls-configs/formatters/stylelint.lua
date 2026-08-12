-- Metadata
-- languages: css,scss,sass,less
-- url: https://github.com/stylelint/stylelint

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'stylelint'
  local args = '--fix --stdin'
  local command = string.format('%s %s', btv.await(fs.executable(formatter, fs.Scope.NODE)), args)

  return {
    formatCommand = command,
    formatStdin = true,
    rootMarkers = { '.stylelintrc', '.stylelintrc.json', '.stylelintrc.yml', '.stylelintrc.yaml' },
  }
end)
