-- Native port of the `:checkhealth efmls-configs` report. nxvim has no
-- `vim.health` provider surface, so this reports the tool-resolution results that
-- `efmls-configs.fs.executable` accumulated into `_G._efmls.healthcheck` — each
-- bundled linter/formatter that was found on `$PATH` (or a project-local bin dir),
-- and each that was missing — through `nx.notify`. Surfaced to users as
-- `:EfmlsHealth` (registered by `nxvim-efmls-configs`).

local M = {}

local function healthcheck()
  return _G._efmls and _G._efmls.healthcheck or { errors = {}, ok = {} }
end

---Report the accumulated linter/formatter resolution status through `nx.notify`,
---and return it as `{ ok = string[], errors = string[] }`.
---@return { ok: string[], errors: string[] }
function M.check()
  local hc = healthcheck()

  for _, err in ipairs(hc.errors) do
    nx.notify('[efmls-configs] ' .. err, 'error')
  end
  for _, ok in ipairs(hc.ok) do
    nx.notify('[efmls-configs] ' .. ok, 'info')
  end

  if #hc.errors == 0 and #hc.ok == 0 then
    nx.notify('[efmls-configs] no linters/formatters configured yet — call setup() first', 'warn')
  end

  return { ok = hc.ok, errors = hc.errors }
end

return M
