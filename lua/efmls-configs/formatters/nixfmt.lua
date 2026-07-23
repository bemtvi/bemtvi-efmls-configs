-- Metadata
-- languages: nix
-- url: https://github.com/NixOS/nixfmt

local fs = require('efmls-configs.fs')
return nx.async(function()
  local formatter = nx.await(fs.executable('nixfmt'))
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
