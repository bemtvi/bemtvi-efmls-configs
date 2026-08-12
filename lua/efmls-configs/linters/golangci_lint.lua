-- Metadata
-- languages: go
-- url: https://github.com/golangci/golangci-lint

local sourceText = require('efmls-configs.utils').sourceText
local fs = require('efmls-configs.fs')

return btv.async(function()
  local linter = 'golangci-lint'
  local bin = btv.await(fs.executable(linter))

  -- Pick the tab-output flag by golangci-lint major version (v2 renamed it). Runs
  -- `golangci-lint version` for real over btv.run; if the binary is missing the run
  -- rejects and we fall back to the v1 flag.
  local outputFormat = '--out-format tab'
  local ok, result = pcall(function()
    return btv.await(btv.run({ cmd = bin, args = { 'version' } }))
  end)
  if ok and result and (result.stdout .. result.stderr):match('version%s+v?2%.') then
    outputFormat = '--output.tab.path=stdout'
  end

  local command = string.format('%s run --color never %s "${INPUT}"', bin, outputFormat)

  return {
    prefix = linter,
    lintSource = sourceText(linter),
    lintCommand = command,
    lintStdin = false,
    lintFormats = { '%.%#:%l:%c %m' },
    rootMarkers = {},
  }
end)
