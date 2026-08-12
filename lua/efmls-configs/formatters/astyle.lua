-- Metadata
-- languages: c,c++
-- url: http://astyle.sourceforge.net/

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'astyle'
  local command = string.format("%s --stdin='${INPUT}'", btv.await(fs.executable(formatter)))

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
