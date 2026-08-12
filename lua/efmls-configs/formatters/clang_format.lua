-- Metadata
-- languages: c,c++
-- url: https://clang.llvm.org/docs/ClangFormat.html

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'clang-format'
  local command = string.format('%s -', btv.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
