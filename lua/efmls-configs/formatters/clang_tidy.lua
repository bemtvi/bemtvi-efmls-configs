-- Metadata
-- languages: c,c++
-- url: http://clang.llvm.org/extra/clang-tidy/

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'clang-tidy'
  local command = string.format("%s -fix '${INPUT}'", nx.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = false,
  }
end)
