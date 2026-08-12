-- Metadata
-- languages: nix
-- url: https://github.com/NixOS/nixfmt

local fs = require('efmls-configs.fs')
return btv.async(function()
  local formatter = btv.await(fs.executable('nixfmt'))
  return {
    formatCommand = formatter,
    formatStdin = true,
    rootMarkers = {
      'flake.nix',
      'shell.nix',
      'default.nix',
    },
  }
end)
