-- Metadata
-- languages: ruby
-- url: https://github.com/troessner/reek

local sourceText = require('efmls-configs.utils').sourceText
local fs = require('efmls-configs.fs')

-- reek's `--single-line` text report prints one smell per line, indented under a
-- `<file> -- N warnings:` heading, with no column:
--
--   app/foo.rb -- 1 warning:
--     app/foo.rb:3: DuplicateMethodCall: Foo#bar calls 'x.baz' 2 times
--
-- `--no-documentation` drops the trailing `[https://…]` docs link from each message.
-- Exit codes: 0 = no smells, 2 = smells found, 1 = reek itself failed. efm parses
-- output only on a non-zero exit, which is exactly reek's contract, so
-- `lintIgnoreExitCode` stays off.
return btv.async(function()
  local linter = 'reek'
  local args =
    '--format text --single-line --no-documentation --no-color --no-progress --force-exclusion --stdin-filename "${INPUT}"'
  local command = string.format('%s %s', btv.await(fs.executable(linter, fs.Scope.BUNDLE)), args)

  return {
    prefix = linter,
    lintSource = sourceText(linter),
    lintCommand = command,
    lintStdin = true,
    lintFormats = { '%*[ ]%f:%l: %m' },
    -- Every reek report is a code smell; it has no severity levels, so report warnings.
    lintSeverity = 2,
    rootMarkers = {},
  }
end)
