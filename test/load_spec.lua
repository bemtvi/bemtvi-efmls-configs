-- Lazy, per-language loading: load() resolves ONE language on demand and wires it
-- into efm; setup() only registers the FileType autocmds that call load() when a
-- buffer of that type is opened. Nothing resolves eagerly.

local efmls = require('bemtvi-efmls-configs')

btv.test.describe('bemtvi-efmls-configs.load', function()
  btv.test.it('resolves a language on demand and configures + enables efm', function()
    -- force: another spec may have already loaded `lua`; re-resolve for this assertion.
    local resolved = btv.await(efmls.load('lua', {
      -- Parenthesised: bemtvi's `require` returns (module, loader); keep only the module.
      (require('efmls-configs.linters.luacheck')),
      (require('efmls-configs.formatters.stylua')),
    }, { force = true }))
    btv.test.expect(#resolved).to_be(2)

    local efm = btv.lsp._config.efm
    btv.test.expect(efm).to_be_truthy()
    btv.test.expect(btv.lsp._enabled.efm).to_be_truthy()
    btv.test.expect(btv.tbl.contains(efm.filetypes, 'lua')).to_be(true)

    -- Real resolved command (no placeholder), pointing at luacheck.
    local lint = efm.settings.languages.lua[1].lintCommand
    btv.test.expect(lint:find('${EFMLS', 1, true)).to_be_nil()
    btv.test.expect(lint).to_match('luacheck')
  end)

  btv.test.it("tolerates require's leaked loader-path (natural { require, require } syntax)", function()
    -- bemtvi's `require` returns (module, loader-path); the final entry in a table
    -- constructor expands to BOTH, leaking a string into the list. load() must ignore
    -- it rather than reject it as a "non-function tool entry" (the reported bug).
    local resolved = btv.await(efmls.load('lua', {
      require('efmls-configs.linters.luacheck'),
      require('efmls-configs.formatters.stylua'), -- final slot: also yields a string
    }, { force = true }))
    btv.test.expect(#resolved).to_be(2) -- two real tools; the leaked string dropped
  end)

  btv.test.it("force REPLACES a language's tools, leaving no trace of the old ones", function()
    btv.await(efmls.load('toml', {
      { lintCommand = 'taplo lint -', lintStdin = true },
      { formatCommand = 'taplo fmt -', formatStdin = true },
    }, { force = true }))
    -- Re-resolve with a SHORTER list: the language must end up with exactly these
    -- tools. Merged entry-by-entry instead, tool 1 would keep `lintCommand` from the
    -- old first entry and the dropped second entry would survive — efm would run a
    -- config nobody wrote.
    btv.await(efmls.load('toml', {
      { formatCommand = 'taplo fmt -', formatStdin = true },
    }, { force = true }))

    local tools = btv.lsp._config.efm.settings.languages.toml
    btv.test.expect(#tools).to_be(1)
    btv.test.expect(tools[1].lintCommand).to_be_nil()
    btv.test.expect(tools[1].formatCommand).to_be('taplo fmt -')
  end)

  btv.test.it('accepts a raw config table as a tool entry', function()
    local resolved = btv.await(efmls.load('json', {
      { formatCommand = 'jq .', formatStdin = true },
    }, { force = true }))
    btv.test.expect(#resolved).to_be(1)
    btv.test.expect(resolved[1].formatCommand).to_be('jq .')
  end)

  btv.test.it('loads a language at most once (deduped)', function()
    local p1 = efmls.load('python', { (require('efmls-configs.linters.flake8')) })
    -- A second trigger for the same ft returns the SAME promise; its tools are ignored.
    local p2 = efmls.load('python', { (require('efmls-configs.formatters.black')) })
    btv.test.expect(p1).to_be(p2)
    btv.await(p1)
    btv.test.expect(#btv.lsp._config.efm.settings.languages.python).to_be(1)
  end)

  btv.test.it('accumulates languages across loads (efm stays one server)', function()
    btv.await(efmls.load('go', { (require('efmls-configs.linters.golangci_lint')) }))
    local efm = btv.lsp._config.efm
    -- lua (earlier) and go both present now.
    btv.test.expect(efm.settings.languages.lua).to_be_truthy()
    btv.test.expect(efm.settings.languages.go).to_be_truthy()
    btv.test.expect(btv.tbl.contains(efm.filetypes, 'go')).to_be(true)
  end)
end)

btv.test.describe('bemtvi-efmls-configs.setup (lazy)', function()
  btv.test.it('does not resolve or configure a language eagerly', function()
    efmls.setup({ languages = { ruby = { (require('efmls-configs.linters.reek')) } } })
    -- The ruby autocmd is registered but has NOT fired (no ruby buffer opened), so
    -- efm carries no ruby languages yet.
    local efm = btv.lsp._config.efm
    local ruby = efm and efm.settings and efm.settings.languages and efm.settings.languages.ruby
    btv.test.expect(ruby).to_be_nil()
  end)

  btv.test.it('lazily loads a language when its FileType fires on open', function(t)
    efmls.setup({ languages = { markdown = { (require('efmls-configs.linters.markdownlint')) } } })

    local dir = btv.test.tempdir()
    local file = dir .. '/note.md'
    btv.await(btv.fs.write(file, '# hi\n'))
    t:cmd('edit ' .. file)

    t:wait_for(function()
      local efm = btv.lsp._config.efm
      return efm and efm.settings.languages.markdown ~= nil
    end, { tries = 200, interval = 20, message = 'markdown was not lazily loaded on FileType' })

    btv.test.expect(btv.lsp._config.efm.settings.languages.markdown).to_be_truthy()
  end)

  btv.test.it('holds the read sequence until the language is loaded', function(t)
    -- The registered autocmd RETURNS load()'s promise, so `FileType` does not advance
    -- until efm carries the language. `BufWinEnter` fires last in a buffer's read
    -- sequence — after BufReadPost/FileType/BufEnter have settled — so what it observes
    -- is exactly "was the buffer fully wired before it became interactive".
    --
    -- Drop the `return` in setup() and this reads nil: the load is still in flight when
    -- the buffer lands.
    efmls.setup({ languages = { yaml = { (require('efmls-configs.linters.yamllint')) } } })

    local seen
    btv.autocmd.create('BufWinEnter', {
      pattern = '*.yaml',
      callback = function()
        local efm = btv.lsp._config.efm
        seen = efm and efm.settings.languages.yaml or nil
      end,
    })

    local dir = btv.test.tempdir()
    local file = dir .. '/conf.yaml'
    btv.await(btv.fs.write(file, 'a: 1\n'))
    t:cmd('edit ' .. file)

    t:wait_for(function()
      return seen ~= nil
    end, { tries = 200, interval = 20, message = 'yaml was not loaded by the time the buffer was displayed' })
    btv.test.expect(seen).to_be_truthy()
  end)

  btv.test.it('rejects a load_timeout that is not a positive number of ms', function()
    btv.test
      .expect(function()
        efmls.setup({ load_timeout = 0, languages = { toml = { { lintCommand = 'true' } } } })
      end)
      .to_error('load_timeout')
  end)
end)
