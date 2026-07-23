-- Binary resolution for the bundled linter/formatter configs — fully async, native.
--
-- Neovim's efmls-configs resolved each tool binary *synchronously* at module load
-- (`vim.fn.executable`/`exepath`/`filereadable` + blocking `vim.loop`). nxvim has no
-- blocking filesystem access from Lua — every fs op is an async `nx.fs.*` promise —
-- so `fs.executable` is async too: it returns a PROMISE of the resolved path, over
-- `nx.fs.exists`. Each preset is therefore an `nx.async` factory that awaits its
-- binaries while building its command; `nxvim-efmls-configs.setup` awaits the whole
-- set (in parallel) before handing the languages map to efm-langserver.
--
-- In a remote/daemon session the `nx.fs` ops route to the daemon host, so tools are
-- resolved on the machine efm actually runs on — the resolution is correct there,
-- not merely on the editor's box.

local M = {}

---@alias ScopeType
---| 'BUNDLE'
---| 'COMPOSER'
---| 'NODE'

M.Scope = {
  NODE = 'NODE',
  COMPOSER = 'COMPOSER',
  BUNDLE = 'BUNDLE',
}

local FilepathByScope = {
  NODE = 'node_modules/.bin',
  COMPOSER = 'vendor/bin',
  BUNDLE = 'vendor/bundle',
}

-- Platform sniff (a `package.config` constant — no IO). nxvim has no native win32
-- target, so this is `false` in practice; kept so the handful of tool configs that
-- branch on it read the same as upstream.
M.is_windows = package.config:sub(1, 1) == '\\'
local PATHSEP = M.is_windows and ';' or ':'

-- ----- health accumulator (surfaced by :EfmlsHealth) -------------------------

local function healthcheck()
  _G._efmls = _G._efmls or { healthcheck = { errors = {}, ok = {} } }
  return _G._efmls.healthcheck
end

---Start a fresh health report. Called by `setup()` before it resolves a config, so
---`:EfmlsHealth` reflects the current resolution rather than accumulating stale runs.
M.reset_health = function()
  _G._efmls = { healthcheck = { errors = {}, ok = {} } }
end

-- ----- async resolution ------------------------------------------------------

---Resolve `name` on the host `$PATH` to a full path, or `nil` if not found. When
---`name` is already a path (contains a separator) it is checked as-is. Async: returns
---a promise; await it inside an `nx.async` context.
---@param name string
---@return string|nil promise
M.which = nx.async(function(name)
  if name:find('/', 1, true) then
    return nx.await(nx.fs.exists(name)) and name or nil
  end

  local path = vim.env.PATH or ''
  for dir in string.gmatch(path, '([^' .. PATHSEP .. ']+)') do
    local candidate = dir .. '/' .. name
    if nx.await(nx.fs.exists(candidate)) then
      return candidate
    end
  end

  return nil
end)

---True when `name` resolves on `$PATH` (or is a readable path). Async — used by tool
---configs that branch on the presence of a helper binary (e.g. `xargs`).
---@param name string
---@return boolean promise
M.has_executable = nx.async(function(name)
  return nx.await(M.which(name)) ~= nil
end)

---Resolve a tool binary — the project-local scope dir first (npm/composer/bundler
---bin), then the global `$PATH` — recording the outcome for `:EfmlsHealth`. Async:
---returns a promise of the resolved path, or the bare `name` on a miss (so efm's own
---shell can still try it). Await it inside an `nx.async` preset.
---@param name string
---@param context? ScopeType
---@return string promise
M.executable = nx.async(function(name, context)
  local hc = healthcheck()

  -- project-local (node_modules/.bin, vendor/bin, …)
  local rel = context and FilepathByScope[context]
  if rel then
    local candidate = string.format('%s/%s/%s', vim.fn.getcwd(), rel, name)
    if nx.await(nx.fs.exists(candidate)) then
      table.insert(hc.ok, string.format('%q: found at %s', name, candidate))
      return candidate
    end
  end

  -- global $PATH
  local resolved = nx.await(M.which(name))
  if resolved then
    table.insert(hc.ok, string.format('%q: found at %s', name, resolved))
    return resolved
  end

  table.insert(hc.errors, string.format('%q: no executable found on $PATH', name))
  return name
end)

return M
