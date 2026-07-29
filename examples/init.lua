-- Runnable demo for nxvim-efmls-configs — lazily wiring efm-langserver with a linter
-- and a formatter, loaded on demand from a FileType autocmd.
--
--     NXVIM_CONFIG=examples nxvim examples/sample.lua
--
-- Run it from a checkout of this repo. It lints Lua with luacheck and formats it with
-- stylua — but only once a Lua buffer is actually opened. Install those three binaries
-- first:
--
--     efm-langserver  https://github.com/mattn/efm-langserver
--     luacheck        https://github.com/mpeterv/luacheck
--     stylua          https://github.com/JohnnyMorganz/StyLua
--
-- Any missing binary is reported by `:EfmlsHealth` (and efm simply won't run that
-- tool) — nxvim never pretends a tool that isn't installed is working.

vim.g.mapleader = ' '

-- Load the plugin straight from this repo (a local-dev spec: `dir` is never cloned).
-- A real config declares `{ "nxvim/nxvim-efmls-configs", config = … }` and runs
-- `:PluginSync` — see the README's Install section.
nx.plugins({
  {
    name = 'nxvim-efmls-configs',
    dir = vim.fn.expand('<sfile>:p:h:h'), -- the repo root (this file's grandparent dir)
    config = function()
      local efmls = require('nxvim-efmls-configs')

      -- 1. efm's GLOBAL options (all optional). setup() is synchronous and resolves
      --    nothing — it just stores these and, if given `languages`, registers the
      --    lazy FileType autocmds for you.
      efmls.setup({
        formatting = true, -- advertise document + range formatting
        root_markers = { '.git/', '.luacheckrc', 'stylua.toml' },
        on_attach = function(_, bufnr)
          nx.notify(('efm attached (buf %d)'):format(bufnr))
        end,
      })

      -- 2. Load the lua tools ON DEMAND — only when a lua buffer is opened. Each preset
      --    is an async factory (a function returning a promise of its efm config);
      --    load() awaits them and resolves the binaries over nx.fs, never at startup.
      --    TYPE: :edit examples/sample.lua  →  SEE: "efm attached" once efm starts.
      --    RETURN the promise: FileType is async-capable, so nxvim holds the buffer's
      --    read sequence there until efm is registered and enabled — the file is never
      --    interactive-but-unlinted. `timeout` raises the 500 ms settle budget, which a
      --    per-tool filesystem probe routinely outruns.
      nx.autocmd.create('FileType', {
        pattern = 'lua',
        timeout = 5000,
        callback = function()
          return efmls.load('lua', {
            require('efmls-configs.linters.luacheck'),
            require('efmls-configs.formatters.stylua'),
          })
        end,
      })

      -- 3. A convenience map: <leader>lf asks EFM to format the buffer. Aimed at efm
      --    on purpose: a bare nx.lsp.format() formats with whichever attached server
      --    sorts first by config name (lua_ls, biome, denols, …), which on a real
      --    config is not the tool you set up here.
      --    TYPE: <leader>lf on examples/sample.lua  →  SEE: stylua reflows it.
      nx.keymap.set('n', '<leader>lf', efmls.format, { desc = 'Format with efm' })

      -- 4. Format on save. BufWritePre is nxvim's gated event: RETURN the promise and
      --    the write waits for efm's edits, so what lands on disk is formatted.
      --    TYPE: mangle examples/sample.lua, then :w  →  SEE: it is stylua'd, then saved.
      nx.autocmd.create('BufWritePre', {
        pattern = '*.lua',
        callback = function()
          return efmls.format()
        end,
      })

      -- The same wiring, done for you: `efmls.setup({ languages = { lua = { … } } })`
      -- registers the FileType autocmd above. Use `languages = "*defaults"` to lazy-
      -- wire the whole bundled set (lua, python, go, js/ts, css, html, php, ruby, …).
      --
      -- Run `:EfmlsHealth` any time to see which tool binaries were found, whether efm
      -- is running, and which servers are attached to the buffer you are in.
    end,
  },
})
