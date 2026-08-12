-- Metadata
-- languages: python
-- url: https://github.com/ambv/black

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = 'black'
  local command = string.format(
    "%s --no-color -q $(echo ${--useless:rowStart} ${--useless:rowEnd} | xargs -n4 -r sh -c 'echo --line-ranges=$(($1+1))-$(($3+1))') -",
    btv.await(fs.executable(formatter))
  )

  -- TODO: add range formatting for windows without relying on `xargs`
  local is_windows = fs.is_windows
  if is_windows then
    command = string.format('%s --no-color -q -', btv.await(fs.executable(formatter)))
  end

  return {
    formatCanRange = not is_windows,
    formatCommand = command,
    formatStdin = true,
  }
end)
