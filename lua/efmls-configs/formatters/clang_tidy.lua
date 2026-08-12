-- Metadata
-- languages: c,c++
-- url: http://clang.llvm.org/extra/clang-tidy/

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'clang-tidy'
  local command = string.format("%s -fix '${INPUT}'", btv.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = false,
  }
end)
