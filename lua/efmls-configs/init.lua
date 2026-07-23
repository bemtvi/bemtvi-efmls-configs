-- `require('efmls-configs')` — the tool-config *library*. The individual presets
-- live under `efmls-configs.linters.*` / `efmls-configs.formatters.*` and the default
-- language map under `efmls-configs.defaults`; this module just re-exports the pieces
-- for convenience.
--
-- To wire everything into efm-langserver in one call, use the plugin's native entry
-- point instead: `require('nxvim-efmls-configs').setup{ … }` (see its README).

local M = {}

M.defaults = require('efmls-configs.defaults')
M.fs = require('efmls-configs.fs')
M.utils = require('efmls-configs.utils')

return M
