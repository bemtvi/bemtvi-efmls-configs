-- Metadata
-- languages: c,c++,c#,d,java,objective-c,objective-c++,pawn,vala
-- url: https://github.com/uncrustify/uncrustify

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'uncrustify'
  local command = string.format("%s -q '${INPUT}'", nx.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = false,
  }
end)
