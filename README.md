# nxvim-efmls-configs

Ready-made [`efm-langserver`][efm-langserver] configurations for
[nxvim](https://github.com/davidrios/nxvim) — a native port of
[efmls-configs-nvim](https://github.com/creativenull/efmls-configs-nvim).

efm-langserver is a general-purpose language server that runs ordinary linters and
formatters (eslint, stylua, black, luacheck, …) and speaks their results back over
LSP. This plugin ships a curated config table for each of ~150 such tools, plus a
one-call `setup()` that assembles them into an efm `languages` map and drives it onto
nxvim's own [`nx.lsp`](https://github.com/davidrios/nxvim) control surface.

There is **no neovim compatibility layer** — `efm-langserver` is just an LSP server
nxvim spawns, and each preset is plain data (`lintCommand` / `formatCommand` / root
markers) the engine understands directly. Everything is **async and native**: tool
binaries are resolved over `nx.fs` (nxvim has no blocking Lua filesystem access), so
`setup()` returns a promise that fulfils once efm is configured and enabled.

> This plugin only *configures* tools; it does not install them. Install
> [`efm-langserver`][efm-langserver] and the linters/formatters you want yourself. A
> missing binary is reported by `:EfmlsHealth` and simply isn't run — nxvim never
> pretends a tool that isn't there is working.

## Supported linters and formatters

See [doc/SUPPORTED_LIST.md](./doc/SUPPORTED_LIST.md). Every preset lives under
`efmls-configs.linters.<name>` / `efmls-configs.formatters.<name>` and is a plain
`require`-able table.

## Install

Declare it with the built-in `:Plugins` manager in your `init.lua`. Loading is **lazy
and per-language** — you set efm's global options once, then load each language when a
buffer of that type is opened, via a `FileType` autocmd:

```lua
nx.plugins({
  {
    "nxvim/nxvim-efmls-configs",
    config = function()
      local efmls = require("nxvim-efmls-configs")

      -- efm's global options (all optional).
      efmls.setup({ root_markers = { ".git/" } })

      -- Load lua tools only when a lua buffer is opened.
      nx.autocmd.create("FileType", {
        pattern = "lua",
        callback = function()
          efmls.load("lua", {
            require("efmls-configs.linters.luacheck"),
            require("efmls-configs.formatters.stylua"),
          })
        end,
      })
    end,
  },
})
```

Run `:PluginSync` to clone it. Open a file of a loaded type and, if `efm-langserver`
and the tools are installed, efm attaches. Nothing is resolved until the first buffer
of a given filetype opens — a tool's binary is looked up (over `nx.fs`) only when it
is actually needed.

## Usage

### `load(ft, tools[, opts])` — the async, on-demand loader

Resolves `tools` (a list of async presets from `efmls-configs.linters.*` /
`efmls-configs.formatters.*`) for filetype `ft`, registers them with efm, and enables
it. Async: returns a promise of the resolved config list. Loads at most once per
filetype (repeat/concurrent triggers share the one resolution); pass
`{ force = true }` to re-resolve and replace a filetype's tools. Call it from a
`FileType` autocmd (as in Install) so a language loads exactly when it's opened.

### `setup({ … })` — efm's global options

Synchronous. Sets efm's server-wide options; it does **not** resolve any language —
that is `load()`'s job.

```lua
require("nxvim-efmls-configs").setup({
  -- The efm-langserver command (default { "efm-langserver" }).
  command = { "efm-langserver" },

  -- Advertise document / range formatting (both default true).
  formatting = true,
  range_formatting = true,

  -- Project-root markers efm uses to locate a workspace (default { ".git/" }).
  root_markers = { ".git/", ".luacheckrc", "stylua.toml" },

  -- Run when efm attaches to a buffer, and client capabilities to broadcast.
  on_attach = function(client, bufnr) end,
  capabilities = {},

  -- CONVENIENCE: registers a FileType autocmd per language that lazily load()s it on
  -- first open — still on-demand, never eager. Equivalent to writing the autocmds
  -- yourself. Pass the string "*defaults" to lazy-wire the bundled default set.
  languages = {
    lua = { require("efmls-configs.formatters.stylua") },
    python = { require("efmls-configs.linters.flake8") },
  },
})
```

Lazy-wire the bundled default set (lua, python, go, js/ts, css, html, php, ruby, …),
each language still resolving only when its first buffer opens:

```lua
require("nxvim-efmls-configs").setup({ languages = "*defaults" })
```

### Formatting a buffer

efm formatting rides nxvim's native LSP verbs. Bind one:

```lua
nx.keymap.set("n", "<leader>lf", nx.lsp.format, { desc = "Format with efm" })
```

### The library (native path)

You don't have to use `setup()`. Each preset is an async factory, so you can await
them and drive `nx.lsp` directly, building the `languages` map yourself — see the
presets under `efmls-configs.linters.*` / `efmls-configs.formatters.*` and
`require("efmls-configs.defaults").languages()` for the default (factory) map.
Remember to await each: `local cfg = nx.await(require("efmls-configs.formatters.stylua")())`.

### `:EfmlsHealth`

Reports which tool binaries have been resolved so far (as languages are loaded) and
which were missing — the async analogue of neovim's `:checkhealth efmls-configs`. Also
available as `require("nxvim-efmls-configs").health()`.

## Notes on the port

- **Lazy async factories.** Upstream resolved each tool binary synchronously at module
  load and returned a config table. nxvim forbids blocking Lua fs, so each preset is
  instead an `nx.async` factory — `require("efmls-configs.linters.eslint")` returns a
  **function** that, when called, returns a promise of the config table. Nothing is
  resolved until `load(ft, …)` asks for a specific language, which awaits that
  language's factories (in parallel) and grows efm's `languages` map by one entry. If
  you consume a preset directly, call and await it: `local cfg = nx.await(preset())`.
- **Binary resolution** runs over `nx.fs.exists` (`fs.executable` is async). A tool
  that can't be found falls back to its bare name (so efm's own shell can still try
  it) and is flagged in `:EfmlsHealth`. Project-local tools (npm `node_modules/.bin`,
  composer `vendor/bin`, bundler `vendor/bundle`) are preferred over the global
  `$PATH` when present, exactly as upstream.
- **Version/file probes** that upstream ran synchronously are now real async: the
  golangci-lint version check runs over `nx.run`, and rustfmt reads `Cargo.toml` for
  its edition over `nx.fs` — no shell trickery, no blocking.
- **One efm, grown lazily.** Like upstream, a single efm-langserver instance handles
  every language (its `languages` setting is a `filetype → tools` map). Upstream
  configures that whole map eagerly, before efm starts. Loading lazily means a
  language can be added *after* efm is already running — but efm reads its `languages`
  map only at spawn, so the plugin **restarts** efm (`nx.lsp.restart`) when a new
  language is loaded, respawning it with the grown map. `nx.lsp.restart` is a small
  nxvim-core capability added for this (it also underpins a general `:LspRestart`).

## Development

The plugin carries a Lua test suite (`test/*_spec.lua`) on nxvim's native `nx.test`
harness, including an end-to-end spec that formats a buffer through a **real**
`efm-langserver` + `stylua` subprocess. Run it from a checkout with:

```sh
nxvim --test-plugin .
```

[efm-langserver]: https://github.com/mattn/efm-langserver
