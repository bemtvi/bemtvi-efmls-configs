# bemtvi-efmls-configs

Ready-made [`efm-langserver`][efm-langserver] configurations for
[bemtvi](https://github.com/davidrios/bemtvi) — a native port of
[efmls-configs-nvim](https://github.com/creativenull/efmls-configs-nvim).

efm-langserver is a general-purpose language server that runs ordinary linters
and formatters (eslint, stylua, black, luacheck, …) and speaks their results
back over LSP. This plugin ships a curated config table for each of ~150 such
tools and drives them onto bemtvi's own `btv.lsp` control surface. There is **no
neovim compatibility layer** — each preset is plain data (`lintCommand` /
`formatCommand` / root markers) the engine understands directly, resolved
asynchronously over `btv.fs`.

> This plugin only *configures* tools; it does not install them. Install
> [`efm-langserver`][efm-langserver] and the linters/formatters you want
> yourself. A missing binary is reported by `:EfmlsHealth` and simply isn't
> run — bemtvi never pretends a tool that isn't there is working.

## Install

Declare it with the built-in `:Plugins` manager. Loading is **lazy and
per-language**: set efm's global options once, then load each language from a
`FileType` autocmd so a tool's binary is resolved only when a file that needs
it is opened.

```lua
btv.plugins({
  {
    "bemtvi/bemtvi-efmls-configs",
    config = function()
      local efmls = require("bemtvi-efmls-configs")
      efmls.setup({ root_markers = { ".git/" } })

      btv.autocmd.create("FileType", {
        pattern = "lua",
        timeout = 5000,
        callback = function()
          return efmls.load("lua", {
            require("efmls-configs.linters.luacheck"),
            require("efmls-configs.formatters.stylua"),
          })
        end,
      })
    end,
  },
})
```

**Return** `load()`'s promise. `FileType` is one of bemtvi's async-capable events, and
returning the promise holds the buffer's read sequence at that stage until efm is
registered and enabled — so the file is never interactive-but-unlinted for a beat.
`timeout` raises the 500 ms settle budget the wait is bounded by: resolving a language
probes the filesystem once per tool and may restart a running efm, which routinely
outruns the default.

Run `:PluginSync` to clone it, then open a file of a loaded type. Prefer the
bundled defaults over listing tools by hand? `setup({ languages = "*defaults" })`
lazily wires the whole default set — and does both of the above for you (override the
budget with `setup({ load_timeout = … })`).

## Formatting: aim it at efm

efm is a **second** server on the buffer — every enabled config whose filetypes
match attaches, so a Lua buffer carries `lua_ls` *and* efm. Their diagnostics
merge, which is the point of running it. But a bare `btv.lsp.format()` formats
with the first attached server advertising `documentFormatting` **in config-name
order**, and `biome` / `clangd` / `denols` / `basedpyright` all sort before
`efm` — so it quietly runs someone else's formatter instead of the one you
configured here. Name the server:

```lua
local efmls = require("bemtvi-efmls-configs")

-- efmls.format() is btv.lsp.format({ name = "efm" })
btv.keymap.set("n", "<leader>lf", efmls.format, { desc = "Format with efm" })

-- Format on save: BufWritePre is gated, so RETURN the promise and the write waits.
btv.autocmd.create("BufWritePre", {
  pattern = { "*.lua", "*.py" },
  callback = function()
    return efmls.format()
  end,
})
```

`:EfmlsHealth` reports which binaries resolved, whether efm is actually running,
and every server attached to the current buffer.

## Documentation

Full docs — `setup()` options, the `load()` loader, defaults, formatting,
`:EfmlsHealth`, and notes on the async port — live in the help file:

- In editor: `:help efmls-configs`
- On GitHub: [doc/efmls-configs.md](./doc/efmls-configs.md) (the help source)

The list of supported linters and formatters is in
[doc/SUPPORTED_LIST.md](./doc/SUPPORTED_LIST.md). Every preset lives under
`efmls-configs.linters.<name>` / `efmls-configs.formatters.<name>`.

## Development

The plugin carries a Lua test suite (`test/*_spec.lua`) on bemtvi's native
`btv.test` harness, including an end-to-end spec that formats a buffer through a
**real** `efm-langserver` + `stylua` subprocess. Run it from a checkout with:

```sh
bemtvi --test-plugin .
```

Generated files (regenerate after editing their sources):

- `doc/SUPPORTED_LIST.md` / `doc/supported-list.json` — from the preset
  `-- Metadata` frontmatter: `deno task gen`.
- `doc/efmls-configs.txt` — the vimdoc, from `doc/efmls-configs.md` via
  [panvimdoc](https://github.com/kdheepak/panvimdoc): `deno task doc` (needs
  `pandoc` + `git`). **Edit the `.md`, never the `.txt`.**

A pre-push hook (via [pre-commit](https://pre-commit.com)) verifies both are up
to date. Enable it once after cloning: `pre-commit install --hook-type pre-push`.

## Credits

A native bemtvi port of [efmls-configs-nvim][efmls] by Arnold Chand
(creativenull) — MIT, Copyright (c) 2021 — which supplies the curated tool
configurations ported here. [`efm-langserver`][efm-langserver] is by mattn.

[efm-langserver]: https://github.com/mattn/efm-langserver
[efmls]: https://github.com/creativenull/efmls-configs-nvim
