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
      nx.autocmd.create('FileType', {
        pattern = 'lua',
        callback = function()
          efmls.load('lua', {
            require('efmls-configs.linters.luacheck'),
            require('efmls-configs.formatters.stylua'),
          })
        end,
      })

      -- 3. A convenience map: <leader>lf asks efm (via nx.lsp) to format the buffer.
      --    TYPE: <leader>lf on examples/sample.lua  →  SEE: stylua reflows it.
      nx.keymap.set('n', '<leader>lf', nx.lsp.format, { desc = 'Format with efm' })

      -- The same wiring, done for you: `efmls.setup({ languages = { lua = { … } } })`
      -- registers the FileType autocmd above. Use `languages = "*defaults"` to lazy-
      -- wire the whole bundled set (lua, python, go, js/ts, css, html, php, ruby, …).
      --
      -- Run `:EfmlsHealth` any time to see which tool binaries were found.
    end,
  },
})
