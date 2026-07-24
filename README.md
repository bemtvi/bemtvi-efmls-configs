# nxvim-efmls-configs

Ready-made [`efm-langserver`][efm-langserver] configurations for
[nxvim](https://github.com/davidrios/nxvim) — a native port of
[efmls-configs-nvim](https://github.com/creativenull/efmls-configs-nvim).

efm-langserver is a general-purpose language server that runs ordinary linters
and formatters (eslint, stylua, black, luacheck, …) and speaks their results
back over LSP. This plugin ships a curated config table for each of ~150 such
tools and drives them onto nxvim's own `nx.lsp` control surface. There is **no
neovim compatibility layer** — each preset is plain data (`lintCommand` /
`formatCommand` / root markers) the engine understands directly, resolved
asynchronously over `nx.fs`.

> This plugin only *configures* tools; it does not install them. Install
> [`efm-langserver`][efm-langserver] and the linters/formatters you want
> yourself. A missing binary is reported by `:EfmlsHealth` and simply isn't
> run — nxvim never pretends a tool that isn't there is working.

## Install

Declare it with the built-in `:Plugins` manager. Loading is **lazy and
per-language**: set efm's global options once, then load each language from a
`FileType` autocmd so a tool's binary is resolved only when a file that needs
it is opened.

```lua
nx.plugins({
  {
    "nxvim/nxvim-efmls-configs",
    config = function()
      local efmls = require("nxvim-efmls-configs")
      efmls.setup({ root_markers = { ".git/" } })

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

Run `:PluginSync` to clone it, then open a file of a loaded type. Prefer the
bundled defaults over listing tools by hand? `setup({ languages = "*defaults" })`
lazily wires the whole default set.

## Documentation

Full docs — `setup()` options, the `load()` loader, defaults, `:EfmlsHealth`,
and notes on the async port — live in the help file:

- In editor: `:help efmls-configs`
- On GitHub: [doc/efmls-configs.md](./doc/efmls-configs.md) (the help source)

The list of supported linters and formatters is in
[doc/SUPPORTED_LIST.md](./doc/SUPPORTED_LIST.md). Every preset lives under
`efmls-configs.linters.<name>` / `efmls-configs.formatters.<name>`.

## Development

The plugin carries a Lua test suite (`test/*_spec.lua`) on nxvim's native
`nx.test` harness, including an end-to-end spec that formats a buffer through a
**real** `efm-langserver` + `stylua` subprocess. Run it from a checkout with:

```sh
nxvim --test-plugin .
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

A native nxvim port of [efmls-configs-nvim][efmls] by Arnold Chand
(creativenull) — MIT, Copyright (c) 2021 — which supplies the curated tool
configurations ported here. [`efm-langserver`][efm-langserver] is by mattn.

[efm-langserver]: https://github.com/mattn/efm-langserver
[efmls]: https://github.com/creativenull/efmls-configs-nvim
