<!-- DO NOT EDIT doc/efmls-configs.txt BY HAND. It is generated from this file by
panvimdoc — run `scripts/gen-vimdoc.sh` (or `deno task doc`) after editing. -->

Ready-made `efm-langserver` configurations for nxvim — a native port of efmls-configs-nvim. A
curated config table for each of ~150 linters and formatters (eslint, stylua, black, luacheck, …),
assembled into an efm `languages` map and driven onto nxvim's own `nx.lsp` control surface.

There is NO neovim compatibility layer — `efm-langserver` is just an LSP server nxvim spawns, and
each preset is plain data (`lintCommand` / `formatCommand` / root markers) the engine understands
directly. Everything is async and native: tool binaries are resolved over `nx.fs` (nxvim has no
blocking Lua filesystem access), so presets are async factories and `load()` returns a promise.

This plugin only configures tools; it does not install them. Install `efm-langserver` and the
linters/formatters you want yourself. A missing binary is reported by `:EfmlsHealth` and simply
isn't run — nxvim never pretends a tool that isn't there is working.

# Setup

Loading is LAZY and per-language. You set efm's global options once with `setup()`, then load each
language when a buffer of that type is opened — either by writing a FileType autocmd yourself that
calls `load()`, or by passing a `languages` map to `setup()`, which registers those autocmds for you
(still on-demand, never eager).

```lua
local efmls = require("nxvim-efmls-configs")

-- efm's global options (all optional).
efmls.setup({ root_markers = { ".git/" } })

-- Load lua tools only when a lua buffer is first opened.
nx.autocmd.create("FileType", {
  pattern = "lua",
  timeout = 5000,
  callback = function()
    return efmls.load("lua", {
      require("efmls-configs.linters.luacheck"),
      require("efmls-configs.formatters.stylua"),
    })
  end,
})
```

Note the `return` and the `timeout`. `FileType` is one of nxvim's async-capable events: a handler
may hand back a promise, and the buffer's read sequence waits at that stage before advancing to
`BufEnter` / `BufWinEnter`. Returning `load()`'s promise is what makes the buffer land fully wired
— efm registered and enabled before the file is interactive — instead of racing the first
keystroke, and it makes a failed resolution surface as a rejection rather than vanish.

The wait is bounded by a settle budget, 500 ms by default, which is too tight here: resolving a
language probes the filesystem once per tool and may restart a running efm. Blowing it is harmless
(the sequence advances and the load still finishes) but warns, so raise it with `timeout`. The
`languages` convenience below does both for you.

`setup(opts)` sets efm's server-wide options; it does NOT resolve any language — that is `load()`'s
job. Synchronous. Returns the module.

```lua
require("nxvim-efmls-configs").setup({
  -- The efm-langserver command (default { "efm-langserver" }).
  command = { "efm-langserver" },

  -- Advertise document / range formatting (both default true).
  formatting = true,
  range_formatting = true,

  -- Project-root markers efm uses to locate a workspace (default { ".git/" }).
  root_markers = { ".git/", ".luacheckrc", "stylua.toml" },

  -- Run when efm attaches, and client capabilities to broadcast.
  on_attach = function(client, bufnr) end,
  capabilities = {},

  -- CONVENIENCE: registers a FileType autocmd per language that lazily
  -- load()s it on first open — still on-demand, never eager. Pass the
  -- string "*defaults" to lazy-wire the bundled default set. Each of those
  -- autocmds returns load()'s promise, so the read sequence waits for it.
  languages = {
    lua = { require("efmls-configs.formatters.stylua") },
    python = { require("efmls-configs.linters.flake8") },
  },

  -- The settle budget for those autocmds, in ms (default 5000).
  load_timeout = 5000,
})
```

The options `setup()` accepts:

- `command` — argv for the efm-langserver command (default `{ "efm-langserver" }`).
- `formatting` — bool, advertise document formatting (default `true`).
- `range_formatting` — bool, advertise range formatting (default `true`).
- `root_markers` — list, `settings.rootMarkers` (default `{ ".git/" }`).
- `on_attach` — `function(client, bufnr)` run when efm attaches.
- `capabilities` — table, client capabilities to broadcast.
- `languages` — map `filetype -> { <preset factory>, … }` (or the string `"*defaults"`); registers a
  FileType autocmd per language that lazily `load()`s it on first open, returning the promise so
  the buffer's read sequence waits for it.
- `load_timeout` — ms, the settle budget for those autocmds (default `5000`). A positive number;
  anything else raises.

# Load

`load(ft, tools[, opts])`

Resolve `tools` (a list of async presets from `efmls-configs.linters.*` /
`efmls-configs.formatters.*`, or raw config tables) for filetype `ft`, register them with
efm-langserver, and enable it. Async: returns a promise of the resolved config list.

Loads at most once per filetype — repeat or concurrent triggers share the one resolution. Pass
`{ force = true }` to re-resolve and replace a filetype's tools (a replacement, not a merge: tools
dropped from the list are gone from efm's config, and a running efm is restarted so it applies the
replacement rather than the tools it spawned with). Call it from a FileType autocmd so a language
loads exactly when its buffer is opened; a tool's binary is looked up (over `nx.fs`) only when a
file that needs it is first opened.

A file opened while the very first `load()` is still resolving is served too: efm is registered a
few ticks after that buffer's `FileType` already fired, and `nx.lsp.enable` catches up every open
buffer, so the file attaches as soon as it is on screen.

```lua
nx.autocmd.create("FileType", {
  pattern = "typescript",
  timeout = 5000,
  callback = function()
    return require("nxvim-efmls-configs").load("typescript", {
      require("efmls-configs.linters.eslint"),
      require("efmls-configs.formatters.prettier"),
    })
  end,
})
```

# Defaults

Default configurations are an opt-in feature — a curated tool per bundled language (lua, python, go,
js/ts, css, html, php, ruby, …). See `efmls-configs-supported` for the full list.

Lazy-wire the whole default set (each language still resolving only when its first buffer opens):

```lua
require("nxvim-efmls-configs").setup({ languages = "*defaults" })
```

The default (factory) language map is also available directly for introspection or to extend:

```lua
local defaults = require("efmls-configs.defaults").languages()
```

# Formatting

efm is a SECOND server on the buffer. Every enabled config whose filetypes match attaches, so a Lua
buffer carries `lua_ls` *and* efm, a TypeScript one `ts_ls` *and* efm. Each publishes its own
diagnostics and nxvim merges them — which is exactly what you want from a linter, and exactly why
formatting has to be aimed.

A bare `nx.lsp.format()` formats with the first attached server that advertises `documentFormatting`,
in config-NAME order. `biome`, `clangd`, `cssls`, `denols`, `basedpyright` all sort before `efm`, so
on a real config the bare call quietly runs someone else's formatter and your prettier / stylua /
black setup here never gets a look in. Name the server:

```lua
local efmls = require("nxvim-efmls-configs")

-- efmls.format() is nx.lsp.format({ name = "efm" }): efm formats, whatever else attached.
nx.keymap.set("n", "<leader>lf", efmls.format, { desc = "Format with efm" })
```

`format()` returns the promise `nx.lsp.format` returns — it resolves once the edits are in the
buffer, so it can gate a write. `BufWritePre` is nxvim's gated event: RETURN the promise and the
write waits, so format-on-save writes formatted text rather than racing the save.

```lua
nx.autocmd.create("BufWritePre", {
  pattern = { "*.lua", "*.py" },
  callback = function()
    return efmls.format()
  end,
})
```

`:EfmlsHealth` lists every server attached to the current buffer, so it is easy to see when
something else is in the running.

# Health

`:EfmlsHealth`

The async analogue of neovim's `:checkhealth efmls-configs`, in two halves:

- which tool binaries have been resolved so far (as languages are loaded) and which were missing;
- efm's LIVE state — the languages loaded, whether efm is actually running, whether it is attached
  to the buffer you are in, and every server that is.

The second half is the one that answers "why is nothing linting this file?": a tool can resolve
perfectly and still do nothing because efm never attached here (its language was never loaded for
this filetype, or `efm-langserver` itself isn't installed and the spawn failed).

Also available as `require("nxvim-efmls-configs").health()`, which returns
`{ ok, errors, status, running, attached }`.

# Troubleshooting

Run `:EfmlsHealth` when you get no response from a linter or formatter you expected. A "no
executable found" result means the tool was not found on the provided filepath — ensure it is
installed globally or on a valid path. "efm is NOT running" means no language has been loaded yet
(open a file of a configured type) or `efm-langserver` is missing; "efm is NOT attached to this
buffer" means this filetype has no language loaded.

Formatting that runs the wrong tool is a different failure: see `efmls-configs-formatting` — use
`format()`, not a bare `nx.lsp.format()`.

For nodejs/npm, php/composer, ruby/bundler: project-local tools are preferred over the global
`$PATH`, so check whether the tool is installed in your `node_modules/.bin` (npm), `vendor/bin`
(composer), or `vendor/bundle` (bundler) project folder, or installed globally.

# Notes on the port

## Lazy async factories

Upstream resolved each tool binary synchronously at module load and returned a config table. nxvim
forbids blocking Lua fs, so each preset is instead an `nx.async` factory —
`require("efmls-configs.linters.eslint")` returns a FUNCTION that, when called, returns a promise of
the config table. Nothing is resolved until `load()` asks for a specific language, which awaits that
language's factories (in parallel) and grows efm's `languages` map by one entry. If you consume a
preset directly, call and await it:
`local cfg = nx.await(require("efmls-configs.formatters.stylua")())`.

## Binary resolution

Runs over `nx.fs.exists` (`fs.executable` is async). A tool that can't be found falls back to its
bare name (so efm's own shell can still try it) and is flagged in `:EfmlsHealth`. Project-local
tools are preferred over the global `$PATH` when present, exactly as upstream.

## Async probes

Probes upstream ran synchronously are now real async: the golangci-lint version check runs over
`nx.run`, and rustfmt reads `Cargo.toml` for its edition over `nx.fs` — no shell trickery, no
blocking.

## One shared efm

Like upstream, a single efm-langserver instance handles every language (its `languages` setting is a
`filetype → tools` map). Upstream configures that whole map eagerly, before efm starts. Loading
lazily means the map can change AFTER efm is already running — but efm reads its `languages` map
only at spawn, so the plugin RESTARTS efm (`nx.lsp.restart`) on every change, respawning it with the
map as it stands. That covers a newly-loaded language and a `{ force = true }` reload alike: a force
reload adds no language, so restarting only on growth would leave the live server running the tools
it was spawned with while the config showed the replacement.

# Supported tools

See `doc/SUPPORTED_LIST.md` in this plugin for the full list. Every preset lives under
`efmls-configs.linters.<name>` / `efmls-configs.formatters.<name>` and is a plain `require`-able
async factory.

The efm-langserver schema (the shape of a preset's config) is documented at
<https://github.com/mattn/efm-langserver/blob/master/schema.json>.

# Credits

This plugin is a native nxvim port of efmls-configs-nvim by Arnold Chand (creativenull), which
supplies the curated tool configurations ported here. All credit for the original collection of
linter/formatter configs belongs to that project and its contributors.

- Original project: efmls-configs-nvim — <https://github.com/creativenull/efmls-configs-nvim>
- License: MIT — Copyright (c) 2021 Arnold Chand

efm-langserver itself is by mattn — <https://github.com/mattn/efm-langserver>.

The vimdoc is generated with panvimdoc (MIT, Dheepak Krishnamurthy) —
<https://github.com/kdheepak/panvimdoc>.
