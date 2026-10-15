-- Metadata
-- languages: javascript,typescript,css,html
-- url: http://fecs.baidu.com/

local fs = require('efmls-configs.fs')

-- `fecs format --stream` writes the formatted text, then one extra newline, then
-- its own `console.timeEnd` line to stdout (fecs 1.6.4, cli/format.js):
--
--   var a = 1;\n
--   \n
--   fecs@1.6.4: 21.621ms\n
--
-- Fed to efm as-is, that trailer would be written into the buffer on every format.
-- The awk filter drops the timing line and the blank line fecs added before it. When
-- the timing line is missing, fecs never reached the end of its stream (it crashed or
-- could not start), so the filter exits non-zero and efm leaves the buffer alone
-- instead of replacing it with partial output.
local STRIP_TRAILER = [[awk '{ l[NR] = $0 } END { n = NR; ]]
  .. [[if (n == 0 || l[n] !~ /^fecs@[^ ]+: [0-9.:]+(ms|s|min|h)$/) exit 1; n--; ]]
  .. [[if (n > 0 && l[n] == "") n--; for (i = 1; i <= n; i++) print l[i] }']]

return btv.async(function()
  local formatter = 'fecs'
  local args = "format --silent --ignore --stream '${INPUT}'"
  local bin = btv.await(fs.executable(formatter, fs.Scope.NODE))

  return {
    formatCommand = bin .. ' ' .. args .. ' | ' .. STRIP_TRAILER,
    formatStdin = true,
  }
end)
