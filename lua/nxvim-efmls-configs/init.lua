-- nxvim-efmls-configs — ready-made efm-langserver configurations for nxvim.
--
-- A native port of efmls-configs-nvim: a library of linter/formatter presets
-- (`efmls-configs.linters.*` / `efmls-configs.formatters.*`) driven onto nxvim's own
-- `nx.lsp` control surface. There is no neovim compatibility layer — `efm-langserver`
-- is just an LSP server nxvim spawns, and the presets are plain data (`lintCommand` /
-- `formatCommand` / root markers) it understands directly.
--
-- Loading is LAZY and per-language. Each preset is an async factory (`() -> promise`
-- of its config), and nothing is resolved until you ask for a specific language via
-- `load(ft, tools)`. The intended wiring is a FileType autocmd that loads exactly the
-- language of the buffer being opened, so a tool's binary is resolved (over nx.fs)
-- only when a file that needs it is first opened — never eagerly for the whole set.
--
--   local efmls = require("nxvim-efmls-configs")
--   efmls.setup({ root_markers = { ".git/" } })  -- efm's global options (optional)
--
--   nx.autocmd.create("FileType", {
--     pattern = "lua",
--     callback = function()
--       efmls.load("lua", {
--         require("efmls-configs.linters.luacheck"),
--         require("efmls-configs.formatters.stylua"),
--       })
--     end,
--   })
--
-- `setup({ languages = { lua = { … } } })` is a convenience that registers exactly
-- those FileType autocmds for you — still lazy: each language resolves only when its
-- first buffer opens.

local defaults = require('efmls-configs.defaults')
local fs = require('efmls-configs.fs')
local health = require('efmls-configs.health')

local M = {}

-- Re-export the default (factory) language map for convenience / introspection.
M.defaults = defaults

-- ----- accumulated efm state -------------------------------------------------

-- efm's global options (command / init_options / root markers / hooks), set by
-- setup(). Defaults apply when setup() is never called.
M._opts = {}

-- The concrete, resolved efm config so far: filetype -> { <config>, … }, grown one
-- language at a time by load().
M._languages = {}

-- The filetypes efm is configured for (accumulated, in load order).
M._filetypes = {}
local ft_seen = {}

-- filetype -> the in-flight/settled load() promise, so a language loads at most once
-- (and concurrent triggers share one resolution).
M._loaded = {}

-- (Re)configure and enable efm from the accumulated state. Idempotent — nx.lsp.config
-- deep-merges and starts are idempotent server-side, so calling it once per newly
-- loaded language is fine, and nx.lsp.enable attaches the current buffer on the spot.
local function reconfigure()
  local o = M._opts
  local cfg = {
    cmd = o.command or { 'efm-langserver' },
    filetypes = M._filetypes,
    init_options = {
      documentFormatting = o.formatting ~= false,
      documentRangeFormatting = o.range_formatting ~= false,
    },
    settings = {
      rootMarkers = o.root_markers or { '.git/' },
      languages = M._languages,
    },
  }
  if o.on_attach ~= nil then
    cfg.on_attach = o.on_attach
  end
  if o.capabilities ~= nil then
    cfg.capabilities = o.capabilities
  end

  nx.lsp.config('efm', cfg)
  nx.lsp.enable({ 'efm' })
end

-- The actual per-language load: resolve the tool factories (in parallel, over nx.fs),
-- register the resolved configs under `ft`, and (re)configure efm.
local do_load = nx.async(function(ft, tools)
  local promises = {}
  for _, factory in ipairs(tools) do
    if type(factory) ~= 'function' then
      error('nxvim-efmls-configs.load: ' .. tostring(ft) .. ' has a non-function tool entry', 2)
    end
    promises[#promises + 1] = factory()
  end

  M._languages[ft] = nx.await(nx.promise.all(promises))
  if not ft_seen[ft] then
    ft_seen[ft] = true
    M._filetypes[#M._filetypes + 1] = ft
  end

  reconfigure()
  return M._languages[ft]
end)

-- ----- public API ------------------------------------------------------------

-- M.load(ft, tools[, opts]) — resolve `tools` (a list of async presets from
-- `efmls-configs.linters.*` / `.formatters.*`) for filetype `ft`, register them with
-- efm-langserver, and enable it. Async: returns a promise of the resolved config list.
--
-- Loads at most once per filetype (concurrent/repeat triggers share the one
-- resolution) — pass `opts.force = true` to re-resolve and replace `ft`'s tools. Call
-- it from a FileType autocmd so a language loads only when its buffer is opened.
function M.load(ft, tools, opts)
  if type(ft) ~= 'string' or ft == '' then
    error('nxvim-efmls-configs.load: ft must be a non-empty string', 2)
  end
  if type(tools) ~= 'table' then
    error('nxvim-efmls-configs.load: tools must be a list of preset factories', 2)
  end
  if M._loaded[ft] and not (opts and opts.force) then
    return M._loaded[ft]
  end
  local p = do_load(ft, tools)
  M._loaded[ft] = p
  return p
end

-- M.setup(opts) — set efm's GLOBAL options (it does NOT resolve any language; that is
-- load()'s job). Synchronous. Returns M.
--
--   opts.command          argv efm-langserver command (default { "efm-langserver" })
--   opts.formatting       bool advertise document formatting (default true)
--   opts.range_formatting bool advertise range formatting (default true)
--   opts.root_markers     list settings.rootMarkers (default { ".git/" })
--   opts.on_attach        fn   function(client, bufnr) run when efm attaches
--   opts.capabilities     tbl  client capabilities to broadcast
--   opts.languages        map  filetype -> { <preset factory>, … }. CONVENIENCE:
--                              registers a FileType autocmd per language that lazily
--                              load()s it on first open (still on-demand, not eager).
--                              Use "*defaults" as the value to lazy-wire the bundled
--                              default set.
function M.setup(opts)
  opts = opts or {}
  if type(opts) ~= 'table' then
    error('nxvim-efmls-configs.setup: opts must be a table', 2)
  end

  M._opts = opts
  fs.reset_health()

  local languages = opts.languages
  if languages == '*defaults' then
    languages = defaults.languages()
  end

  if type(languages) == 'table' then
    local group = nx.augroup.create('nxvim-efmls-configs', { clear = true })
    for ft, tools in pairs(languages) do
      nx.autocmd.create('FileType', {
        group = group,
        pattern = ft,
        callback = function()
          M.load(ft, tools)
        end,
      })
    end
  end

  return M
end

-- M.health() — report tool resolution status (also the `:EfmlsHealth` command).
function M.health()
  return health.check()
end

nx.command('EfmlsHealth', function()
  health.check()
end)

return M
