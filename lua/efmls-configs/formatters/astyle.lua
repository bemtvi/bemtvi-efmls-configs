-- Metadata
-- languages: c,c++
-- url: http://astyle.sourceforge.net/

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'astyle'
  local command = string.format("%s --stdin='${INPUT}'", nx.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
