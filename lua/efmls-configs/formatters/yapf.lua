-- Metadata
-- languages: python
-- url: https://github.com/google/yapf

local fs = require('efmls-configs.fs')

return btv.async(function()
  local bin = btv.await(fs.executable('yapf'))

  -- Range formatting is expressed through `xargs`. Probe for it asynchronously; fall
  -- back to whole-buffer formatting when it is not available.
  local has_xargs = btv.await(fs.has_executable('xargs'))

  local command = bin
  if has_xargs then
    command = string.format(
      "%s $(echo ${--useless:rowStart} ${--useless:rowEnd} | xargs -n4 -r sh -c 'echo --lines=$(($1+1))-$(($3+1))')",
      bin
    )
  end

  return {
    formatCommand = command,
    formatStdin = true,
    formatCanRange = has_xargs,
    rootMarkers = { '.style.yapf', 'setup.cfg', 'pyproject.toml', 'setup.py' },
  }
end)
