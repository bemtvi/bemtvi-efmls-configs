-- bemtvi-efmls-configs — ready-made efm-langserver configurations for bemtvi.
--
-- A native port of efmls-configs-nvim: a library of linter/formatter presets
-- (`efmls-configs.linters.*` / `efmls-configs.formatters.*`) driven onto bemtvi's own
-- `btv.lsp` control surface. There is no neovim compatibility layer — `efm-langserver`
-- is just an LSP server bemtvi spawns, and the presets are plain data (`lintCommand` /
-- `formatCommand` / root markers) it understands directly.
--
-- Loading is LAZY and per-language. Each preset is an async factory (`() -> promise`
-- of its config), and nothing is resolved until you ask for a specific language via
-- `load(ft, tools)`. The intended wiring is a FileType autocmd that loads exactly the
-- language of the buffer being opened, so a tool's binary is resolved (over btv.fs)
-- only when a file that needs it is first opened — never eagerly for the whole set.
--
--   local efmls = require("bemtvi-efmls-configs")
--   efmls.setup({ root_markers = { ".git/" } })  -- efm's global options (optional)
--
--   btv.autocmd.create("FileType", {
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
-- the buffer land fully configured: bemtvi holds the read sequence at the `FileType`
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
-- one): each publishes its own diagnostics, and bemtvi merges them. That is what you
-- want for linting — and it is exactly why formatting must be aimed. A bare
-- `btv.lsp.format()` goes to the first attached server advertising
-- `documentFormatting`, in config-NAME order, so `biome` / `clangd` / `denols` /
-- `basedpyright` all win over `efm` and your prettier/stylua/black config is quietly
-- bypassed. Format through `efmls.format()` (or `btv.lsp.format({ name = "efm" })`).

local defaults = require('efmls-configs.defaults')
local fs = require('efmls-configs.fs')
local health = require('efmls-configs.health')

local M = {}

-- Re-export the default (factory) language map for convenience / introspection.
M.defaults = defaults

-- ----- accumulated efm state -------------------------------------------------

-- The btv.lsp config name for the shared efm server. ONE efm handles every loaded
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

-- The same markers, spelled for bemtvi's root resolution. `rootMarkers` is efm's own
-- setting and follows efm's convention, where a trailing slash means "a DIRECTORY
-- marker" (`.git/`); bemtvi's `root_markers` matches a directory entry's NAME exactly,
-- so `.git/` handed to it never matches anything. One user-facing knob
-- (`setup{ root_markers = }`), translated per consumer.
local function btv_markers(markers)
  local out = {}
  for _, m in ipairs(markers) do
    if type(m) == 'string' then
      out[#out + 1] = (m:gsub('/+$', ''))
    else
      out[#out + 1] = m
    end
  end
  return out
end

-- Build efm's config from the accumulated state and register + enable it. efm reads
-- its `languages` map only at spawn (bemtvi delivers the config once, at the
-- handshake; a running efm cannot be reconfigured at runtime), so whenever the map
-- changes *after* efm is already running we must RESTART it — otherwise the live
-- server would never see the change. (The upstream neovim plugin sidesteps this by
-- configuring the whole map eagerly, before its one efm ever starts; bemtvi's
-- `btv.lsp.restart` lets us do it lazily against one server instead.)
--
-- EVERY change, not just a new language: this runs only from `do_load`, which a
-- filetype reaches on its first load or on a `force` re-load — and a force re-load
-- replaces that language's tools without adding one. Gating the restart on "the
-- language is new" left exactly that case silent: `btv.lsp._config` showed the
-- replacement while the running efm kept applying the tools it spawned with.
local function reconfigure()
  local o = M._opts
  local markers = o.root_markers or { '.git/' }
  local cfg = {
    cmd = o.command or { 'efm-langserver' },
    filetypes = M._filetypes,
    -- bemtvi's OWN root resolution, which decides how many efm processes exist: a
    -- server is keyed by (name, root), and with no `root_markers` bemtvi falls back to
    -- each file's own DIRECTORY. A project with `src/` and `test/` then runs one efm
    -- per directory — not the single shared server this plugin is built around, and
    -- every `load()` restarts all of them. Feeding it the same markers efm uses
    -- collapses a project onto one root, and one efm.
    --
    -- It reads as a duplicate of `settings.rootMarkers` below and is not: that one is
    -- efm's, telling efm's own linters where the project starts, and efm never sees
    -- this one.
    root_markers = btv_markers(markers),
    init_options = {
      documentFormatting = o.formatting ~= false,
      documentRangeFormatting = o.range_formatting ~= false,
    },
    settings = {
      rootMarkers = markers,
      languages = M._languages,
    },
  }
  if o.on_attach ~= nil then
    cfg.on_attach = o.on_attach
  end
  if o.capabilities ~= nil then
    cfg.capabilities = o.capabilities
  end

  btv.lsp.config(SERVER, cfg)
  -- `enable` also catches up every buffer already open — a language resolves over the
  -- async `btv.fs` seam, so the buffers that triggered it have long since had their
  -- `FileType` fired, and nothing re-fires it for a buffer whose filetype is set.
  btv.lsp.enable({ SERVER })
  -- If efm was already running, the changed config won't reach the live server —
  -- restart it so it respawns with the map as it stands now.
  if efm_live then
    btv.lsp.restart(SERVER)
  end
  efm_live = true
end

-- The actual per-language load: resolve the tool factories (in parallel, over btv.fs),
-- register the resolved configs under `ft`, and (re)configure the shared efm.
--
-- Each tool entry is a preset FACTORY (`require('efmls-configs.linters.eslint')`) or a
-- raw config table. bemtvi's `require` returns TWO values (module, loader-path), and
-- the loader-path STRING leaks into the final slot of a `{ require(a), require(b) }`
-- constructor — a pervasive footgun — so those strings are ignored rather than
-- mistaken for a tool. Anything else (number/boolean/…) is a genuine mistake: loud.
local do_load = btv.async(function(ft, tools)
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
        ('bemtvi-efmls-configs.load: %s has a %s tool entry (expected a preset factory or config table)'):format(
          ft,
          kind
        ),
        2
      )
    end
  end

  local configs = ready
  for _, cfg in ipairs(btv.await(btv.promise.all(promises))) do
    configs[#configs + 1] = cfg
  end
  if #configs == 0 then
    error('bemtvi-efmls-configs.load: ' .. tostring(ft) .. ' has no tools', 2)
  end

  M._languages[ft] = configs
  if not ft_seen[ft] then
    ft_seen[ft] = true
    M._filetypes[#M._filetypes + 1] = ft
  end

  reconfigure()
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
    error('bemtvi-efmls-configs.load: ft must be a non-empty string', 2)
  end
  if type(tools) ~= 'table' then
    error('bemtvi-efmls-configs.load: tools must be a list of preset factories', 2)
  end
  if M._loaded[ft] and not (opts and opts.force) then
    return M._loaded[ft]
  end
  local p = do_load(ft, tools)
  M._loaded[ft] = p
  return p
end

-- M.format() — format the current buffer with **efm**, whatever else is attached.
-- Returns btv.lsp.format's promise (resolves once the edits land), so it sequences and
-- can gate a write.
--
-- A buffer carries every server enabled for its filetype, and a bare
-- `btv.lsp.format()` picks the first one advertising `documentFormatting` in config-name
-- order — `biome`, `clangd`, `denols`, `basedpyright` all sort before `efm`. Naming the
-- server is the difference between running the formatter you configured here and
-- silently running someone else's. Bind it directly, or gate a write on it:
--
--   btv.keymap.set("n", "<leader>lf", efmls.format, { desc = "Format with efm" })
--
--   btv.autocmd.create("BufWritePre", {
--     pattern = "*.lua",
--     callback = function() return efmls.format() end, -- RETURN: the write waits
--   })
--
-- `BufWritePre` is bemtvi's gated event: returning the promise holds the write until
-- efm's edits are in the buffer, so format-on-save writes the formatted text.
function M.format()
  return btv.lsp.format({ name = SERVER })
end

-- M.setup(opts) — set efm's GLOBAL options (it does NOT resolve any language; that is
-- load()'s job). Synchronous. Returns M.
--
--   opts.command          argv efm-langserver command (default { "efm-langserver" })
--   opts.formatting       bool advertise document formatting (default true)
--   opts.range_formatting bool advertise range formatting (default true)
--   opts.root_markers     list where a project starts (default { ".git/" }). Drives
--                              BOTH efm's own `settings.rootMarkers` AND bemtvi's
--                              server-root resolution, so one project runs one efm
--                              rather than one per directory. A trailing slash is
--                              efm's "directory marker" spelling; it is stripped for
--                              bemtvi, which matches entry names exactly.
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
    error('bemtvi-efmls-configs.setup: opts must be a table', 2)
  end

  M._opts = opts
  fs.reset_health()

  local languages = opts.languages
  if languages == '*defaults' then
    languages = defaults.languages()
  end

  if type(languages) == 'table' then
    local group = btv.augroup.create('bemtvi-efmls-configs', { clear = true })
    -- `FileType` is async-capable, so the callback RETURNS load()'s promise: bemtvi holds
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
      error('bemtvi-efmls-configs.setup: load_timeout must be a positive number of ms', 2)
    end
    for ft, tools in pairs(languages) do
      btv.autocmd.create('FileType', {
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

btv.command('EfmlsHealth', function()
  M.health()
end)

return M
