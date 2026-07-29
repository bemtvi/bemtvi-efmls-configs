-- Native port of the `:checkhealth efmls-configs` report. nxvim has no
-- `vim.health` provider surface, so this reports, through `nx.notify`:
--
--   * the tool-resolution results `efmls-configs.fs.executable` accumulated into
--     `_G._efmls.healthcheck` — each bundled linter/formatter found on `$PATH` (or in
--     a project-local bin dir), and each that was missing;
--   * efm's LIVE state, read off `nx.lsp.clients` — is the server actually running,
--     and is it attached to the buffer you are in?
--
-- The second half is the half that answers "why is nothing linting this file?".
-- A tool can resolve perfectly and still do nothing because efm never attached here
-- (its language was never loaded for this filetype, or `efm-langserver` itself is not
-- installed and the spawn failed). Reporting only the binaries made that look healthy.
--
-- Surfaced to users as `:EfmlsHealth` (registered by `nxvim-efmls-configs`).

local M = {}

local SERVER = 'efm'

local function healthcheck()
  return _G._efmls and _G._efmls.healthcheck or { errors = {}, ok = {} }
end

-- The live efm picture: is it running anywhere, and is it on the current buffer?
local function client_status(filetypes)
  local running = #nx.lsp.clients({ name = SERVER })
  local here = #nx.lsp.clients({ bufnr = 0, name = SERVER })
  local loaded = (filetypes and #filetypes > 0) and table.concat(filetypes, ', ') or 'none'

  local lines = { ('languages loaded: %s'):format(loaded) }
  if running == 0 then
    lines[#lines + 1] = 'efm is NOT running'
      .. (
        loaded == 'none' and ' (no language loaded yet — open a file of a configured type)'
        or ' — is `efm-langserver` installed and on $PATH?'
      )
  else
    lines[#lines + 1] = ('efm is running (%d client%s)'):format(running, running == 1 and '' or 's')
    lines[#lines + 1] = here > 0 and 'efm is attached to this buffer'
      or 'efm is NOT attached to this buffer — its filetype has no language loaded'
  end
  -- Every server on this buffer, so a formatter that "runs the wrong tool" is
  -- obvious: a bare `nx.lsp.format()` picks by config name, not by what you meant.
  local names = {}
  for _, c in ipairs(nx.lsp.clients({ bufnr = 0 })) do
    names[#names + 1] = c.name
  end
  table.sort(names)
  lines[#lines + 1] = ('servers on this buffer: %s'):format(#names > 0 and table.concat(names, ', ') or 'none')
  if #names > 1 then
    lines[#lines + 1] = 'more than one server here — format with `require("nxvim-efmls-configs").format()`'
      .. ' so efm formats, not whichever server sorts first'
  end
  return lines, running > 0, here > 0
end

---Report tool resolution AND efm's live state through `nx.notify`, and return
---`{ ok = string[], errors = string[], status = string[], running = bool, attached = bool }`.
---@param opts? { filetypes?: string[] } the filetypes a language has been loaded for
---@return { ok: string[], errors: string[], status: string[], running: boolean, attached: boolean }
function M.check(opts)
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

  local status, running, attached = client_status(opts and opts.filetypes)
  for _, line in ipairs(status) do
    nx.notify('[efmls-configs] ' .. line, running and 'info' or 'warn')
  end

  return { ok = hc.ok, errors = hc.errors, status = status, running = running, attached = attached }
end

return M
