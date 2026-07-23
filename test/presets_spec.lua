-- Exhaustive smoke test: every bundled preset must `require` to an async factory
-- that, once awaited, produces a well-formed efm config table with a real (resolved)
-- command. This is what guards the ~150 data files against a straggler reaching for a
-- non-native / non-async API.

local fs = require('efmls-configs.fs')

-- This plugin's checkout on the runtimepath (the dir holding `lua/efmls-configs/`).
local function plugin_root()
  for _, path in ipairs(nx._runtime_paths()) do
    if path:match('efmls%-configs') then
      return path
    end
  end
  error('could not locate the nxvim-efmls-configs runtimepath entry')
end

-- List the `<name>` of every `*.lua` directly under `lua/efmls-configs/<kind>/`.
local function preset_names(root, kind)
  local dir = string.format('%s/lua/efmls-configs/%s', root, kind)
  local names = {}
  for _, rel in ipairs(nx.await(nx.fs.walk(dir))) do
    local name = rel:match('^([%w_]+)%.lua$')
    if name then
      names[#names + 1] = name
    end
  end
  table.sort(names)
  return names
end

nx.test.describe('bundled presets', function()
  nx.test.it('every preset is an async factory that resolves to a valid config', function()
    fs.reset_health()
    local root = plugin_root()
    local total = 0

    for _, kind in ipairs({ 'linters', 'formatters' }) do
      local names = preset_names(root, kind)
      nx.test.expect(#names > 20).to_be(true) -- sanity: we found the tree

      for _, name in ipairs(names) do
        local mod = 'efmls-configs.' .. kind .. '.' .. name
        local ok, factory = pcall(require, mod)
        nx.test.expect(ok).to_be(true)
        -- Each preset is an async factory ( () -> promise of config ).
        nx.test.expect(type(factory)).to_be('function')

        local ok2, cfg = pcall(function()
          return nx.await(factory())
        end)
        if not ok2 then
          error(mod .. ' failed to resolve: ' .. tostring(cfg))
        end
        nx.test.expect(type(cfg)).to_be('table')
        -- A real, non-empty command with no leftover placeholder.
        local cmd = cfg.lintCommand or cfg.formatCommand or ''
        nx.test.expect(#cmd > 0).to_be(true)
        nx.test.expect(cmd:find('${EFMLS', 1, true)).to_be_nil()
        total = total + 1
      end
    end

    nx.test.expect(total > 140).to_be(true)
  end)
end)
