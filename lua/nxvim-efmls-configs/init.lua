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
--     timeout = 5000,
--     callback = function()
--       return efmls.load("lua", {          -- RETURN it: the read chain then waits
--         require("efmls-configs.linters.luacheck"),
--         require("efmls-configs.formatters.stylua"),
--       })
--     end,
--   })
--
-- `FileType` is an async-capable event, and returning `load`'s promise is what makes
-- the buffer land fully configured: nxvim holds the read sequence at the `FileType`
-- stage until every handler settles, so efm is registered + enabled BEFORE `BufEnter`
-- / `BufWinEnter` — no window where the file is interactive but nothing lints it. Drop
-- the promise instead and the wiring still happens, just unordered and with a failed
-- resolution surfacing as nothing at all. The `timeout` raises the 500 ms settle budget
-- the wait is bounded by: resolving a language probes the filesystem once per tool and
-- may restart a running efm, which routinely outruns the default.
--
-- `setup({ languages = { lua = { … } } })` is a convenience that registers exactly
-- those FileType autocmds for you — still lazy: each language resolves only when its
-- first buffer opens, and awaited the same way.
--
-- efm is a SECOND server on the buffer. Every enabled config whose filetypes match
-- attaches (`lua_ls` *and* efm on a Lua buffer, `ts_ls` *and* efm on a TypeScript
-- one): each publishes its own diagnostics, and nxvim merges them. That is what you
-- want for linting — and it is exactly why formatting must be aimed. A bare
-- `nx.lsp.format()` goes to the first attached server advertising
-- `documentFormatting`, in config-NAME order, so `biome` / `clangd` / `denols` /
-- `basedpyright` all win over `efm` and your prettier/stylua/black config is quietly
-- bypassed. Format through `efmls.format()` (or `nx.lsp.format({ name = "efm" })`).

local defaults = require('efmls-configs.defaults')
local fs = require('efmls-configs.fs')
local health = require('efmls-configs.health')

local M = {}

-- Re-export the default (factory) language map for convenience / introspection.
M.defaults = defaults

-- ----- accumulated efm state -------------------------------------------------

-- The nx.lsp config name for the shared efm server. ONE efm handles every loaded
-- language, exactly like the upstream neovim plugin.
local SERVER = 'efm'

-- efm's global options (command / init_options / root markers / hooks), set by
-- setup(). Defaults apply when setup() is never called.
M._opts = {}

-- The resolved config per language: filetype -> { <config>, … }, grown one language
-- at a time by load(); efm's whole `settings.languages` map.
M._languages = {}

-- The filetypes efm is configured for (accumulated, in load order).
M._filetypes = {}
local ft_seen = {}

-- filetype -> the in-flight/settled load() promise, so a language loads at most once
-- (and concurrent triggers share one resolution).
M._loaded = {}

-- True once efm has been configured/enabled at least once, so a later load knows to
-- RESTART the running server rather than rely on a config change reaching it.
local efm_live = false

-- Build efm's config from the accumulated state and register + enable it. efm reads
-- its `languages` map only at spawn (nxvim delivers the config once, at the
-- handshake; a running efm cannot be reconfigured at runtime), so when a language is
-- added *after* efm is already running we must RESTART it — otherwise the live server
-- would never see the new language. (The upstream neovim plugin sidesteps this by
-- configuring the whole map eagerly, before its one efm ever starts; nxvim's
-- `nx.lsp.restart` lets us do it lazily against one server instead.)
local function reconfigure(grew)
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

  nx.lsp.config(SERVER, cfg)
  nx.lsp.enable({ SERVER })
  -- If efm was already running before this language, the grown config won't reach the
  -- live server — restart it so it respawns with the full map.
  if grew and efm_live then
    nx.lsp.restart(SERVER)
  end
  efm_live = true
end

-- The actual per-language load: resolve the tool factories (in parallel, over nx.fs),
-- register the resolved configs under `ft`, and (re)configure the shared efm.
--
-- Each tool entry is a preset FACTORY (`require('efmls-configs.linters.eslint')`) or a
-- raw config table. nxvim's `require` returns TWO values (module, loader-path), and
-- the loader-path STRING leaks into the final slot of a `{ require(a), require(b) }`
-- constructor — a pervasive footgun — so those strings are ignored rather than
-- mistaken for a tool. Anything else (number/boolean/…) is a genuine mistake: loud.
local do_load = nx.async(function(ft, tools)
  local promises = {} -- factories: called, awaited in parallel
  local ready = {} -- raw config tables: used as-is
  for _, tool in ipairs(tools) do
    local kind = type(tool)
    if kind == 'function' then
      promises[#promises + 1] = tool()
    elseif kind == 'table' then
      ready[#ready + 1] = tool
    elseif kind ~= 'string' then
      error(
        ('nxvim-efmls-configs.load: %s has a %s tool entry (expected a preset factory or config table)'):format(
          ft,
          kind
        ),
        2
      )
    end
  end

  local configs = ready
  for _, cfg in ipairs(nx.await(nx.promise.all(promises))) do
    configs[#configs + 1] = cfg
  end
  if #configs == 0 then
    error('nxvim-efmls-configs.load: ' .. tostring(ft) .. ' has no tools', 2)
  end

  local grew = M._languages[ft] == nil
  M._languages[ft] = configs
  if not ft_seen[ft] then
    ft_seen[ft] = true
    M._filetypes[#M._filetypes + 1] = ft
  end

  reconfigure(grew)
  return configs
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

-- M.format() — format the current buffer with **efm**, whatever else is attached.
-- Returns nx.lsp.format's promise (resolves once the edits land), so it sequences and
-- can gate a write.
--
-- A buffer carries every server enabled for its filetype, and a bare
-- `nx.lsp.format()` picks the first one advertising `documentFormatting` in config-name
-- order — `biome`, `clangd`, `denols`, `basedpyright` all sort before `efm`. Naming the
-- server is the difference between running the formatter you configured here and
-- silently running someone else's. Bind it directly, or gate a write on it:
--
--   nx.keymap.set("n", "<leader>lf", efmls.format, { desc = "Format with efm" })
--
--   nx.autocmd.create("BufWritePre", {
--     pattern = "*.lua",
--     callback = function() return efmls.format() end, -- RETURN: the write waits
--   })
--
-- `BufWritePre` is nxvim's gated event: returning the promise holds the write until
-- efm's edits are in the buffer, so format-on-save writes the formatted text.
function M.format()
  return nx.lsp.format({ name = SERVER })
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
--   opts.load_timeout     ms   settle budget for those autocmds (default 5000)
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
    -- `FileType` is async-capable, so the callback RETURNS load()'s promise: nxvim holds
    -- the buffer's read sequence at the FileType stage until it settles, and efm is
    -- registered + enabled before BufEnter/BufWinEnter rather than racing them.
    --
    -- The wait is bounded by a settle budget (500 ms by default) — too tight here, since
    -- resolving a language probes the filesystem once per tool and may restart a running
    -- efm; blowing it costs nothing but a warning, yet a warning per language on every
    -- first open is noise about normal behaviour. 5 s is the default, `load_timeout`
    -- overrides it.
    local timeout = opts.load_timeout or 5000
    if type(timeout) ~= 'number' or timeout <= 0 then
      error('nxvim-efmls-configs.setup: load_timeout must be a positive number of ms', 2)
    end
    for ft, tools in pairs(languages) do
      nx.autocmd.create('FileType', {
        group = group,
        pattern = ft,
        timeout = timeout,
        callback = function()
          return M.load(ft, tools)
        end,
      })
    end
  end

  return M
end

-- M.health() — report tool resolution AND efm's live state (also `:EfmlsHealth`).
function M.health()
  return health.check({ filetypes = M._filetypes })
end

nx.command('EfmlsHealth', function()
  M.health()
end)

return M
