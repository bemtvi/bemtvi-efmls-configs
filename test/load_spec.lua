-- Lazy, per-language loading: load() resolves ONE language on demand and wires it
-- into efm; setup() only registers the FileType autocmds that call load() when a
-- buffer of that type is opened. Nothing resolves eagerly.

local efmls = require('nxvim-efmls-configs')

nx.test.describe('nxvim-efmls-configs.load', function()
  nx.test.it('resolves a language on demand and configures + enables efm', function()
    -- force: another spec may have already loaded `lua`; re-resolve for this assertion.
    local resolved = nx.await(efmls.load('lua', {
      -- Parenthesised: nxvim's `require` returns (module, loader); keep only the module.
      (require('efmls-configs.linters.luacheck')),
      (require('efmls-configs.formatters.stylua')),
    }, { force = true }))
    nx.test.expect(#resolved).to_be(2)

    local efm = nx.lsp._config.efm
    nx.test.expect(efm).to_be_truthy()
    nx.test.expect(nx.lsp._enabled.efm).to_be_truthy()
    nx.test.expect(vim.tbl_contains(efm.filetypes, 'lua')).to_be(true)

    -- Real resolved command (no placeholder), pointing at luacheck.
    local lint = efm.settings.languages.lua[1].lintCommand
    nx.test.expect(lint:find('${EFMLS', 1, true)).to_be_nil()
    nx.test.expect(lint).to_match('luacheck')
  end)

  nx.test.it("tolerates require's leaked loader-path (natural { require, require } syntax)", function()
    -- nxvim's `require` returns (module, loader-path); the final entry in a table
    -- constructor expands to BOTH, leaking a string into the list. load() must ignore
    -- it rather than reject it as a "non-function tool entry" (the reported bug).
    local resolved = nx.await(efmls.load('lua', {
      require('efmls-configs.linters.luacheck'),
      require('efmls-configs.formatters.stylua'), -- final slot: also yields a string
    }, { force = true }))
    nx.test.expect(#resolved).to_be(2) -- two real tools; the leaked string dropped
  end)

  nx.test.it("force REPLACES a language's tools, leaving no trace of the old ones", function()
    nx.await(efmls.load('toml', {
      { lintCommand = 'taplo lint -', lintStdin = true },
      { formatCommand = 'taplo fmt -', formatStdin = true },
    }, { force = true }))
    -- Re-resolve with a SHORTER list: the language must end up with exactly these
    -- tools. Merged entry-by-entry instead, tool 1 would keep `lintCommand` from the
    -- old first entry and the dropped second entry would survive — efm would run a
    -- config nobody wrote.
    nx.await(efmls.load('toml', {
      { formatCommand = 'taplo fmt -', formatStdin = true },
    }, { force = true }))

    local tools = nx.lsp._config.efm.settings.languages.toml
    nx.test.expect(#tools).to_be(1)
    nx.test.expect(tools[1].lintCommand).to_be_nil()
    nx.test.expect(tools[1].formatCommand).to_be('taplo fmt -')
  end)

  nx.test.it('accepts a raw config table as a tool entry', function()
    local resolved = nx.await(efmls.load('json', {
      { formatCommand = 'jq .', formatStdin = true },
    }, { force = true }))
    nx.test.expect(#resolved).to_be(1)
    nx.test.expect(resolved[1].formatCommand).to_be('jq .')
  end)

  nx.test.it('loads a language at most once (deduped)', function()
    local p1 = efmls.load('python', { (require('efmls-configs.linters.flake8')) })
    -- A second trigger for the same ft returns the SAME promise; its tools are ignored.
    local p2 = efmls.load('python', { (require('efmls-configs.formatters.black')) })
    nx.test.expect(p1).to_be(p2)
    nx.await(p1)
    nx.test.expect(#nx.lsp._config.efm.settings.languages.python).to_be(1)
  end)

  nx.test.it('accumulates languages across loads (efm stays one server)', function()
    nx.await(efmls.load('go', { (require('efmls-configs.linters.golangci_lint')) }))
    local efm = nx.lsp._config.efm
    -- lua (earlier) and go both present now.
    nx.test.expect(efm.settings.languages.lua).to_be_truthy()
    nx.test.expect(efm.settings.languages.go).to_be_truthy()
    nx.test.expect(vim.tbl_contains(efm.filetypes, 'go')).to_be(true)
  end)
end)

nx.test.describe('nxvim-efmls-configs.setup (lazy)', function()
  nx.test.it('does not resolve or configure a language eagerly', function()
    efmls.setup({ languages = { ruby = { (require('efmls-configs.linters.reek')) } } })
    -- The ruby autocmd is registered but has NOT fired (no ruby buffer opened), so
    -- efm carries no ruby languages yet.
    local efm = nx.lsp._config.efm
    local ruby = efm and efm.settings and efm.settings.languages and efm.settings.languages.ruby
    nx.test.expect(ruby).to_be_nil()
  end)

  nx.test.it('lazily loads a language when its FileType fires on open', function(t)
    efmls.setup({ languages = { markdown = { (require('efmls-configs.linters.markdownlint')) } } })

    local dir = nx.test.tempdir()
    local file = dir .. '/note.md'
    nx.await(nx.fs.write(file, '# hi\n'))
    t:cmd('edit ' .. file)

    t:wait_for(function()
      local efm = nx.lsp._config.efm
      return efm and efm.settings.languages.markdown ~= nil
    end, { tries = 200, interval = 20, message = 'markdown was not lazily loaded on FileType' })

    nx.test.expect(nx.lsp._config.efm.settings.languages.markdown).to_be_truthy()
  end)

  nx.test.it('holds the read sequence until the language is loaded', function(t)
    -- The registered autocmd RETURNS load()'s promise, so `FileType` does not advance
    -- until efm carries the language. `BufWinEnter` fires last in a buffer's read
    -- sequence — after BufReadPost/FileType/BufEnter have settled — so what it observes
    -- is exactly "was the buffer fully wired before it became interactive".
    --
    -- Drop the `return` in setup() and this reads nil: the load is still in flight when
    -- the buffer lands.
    efmls.setup({ languages = { yaml = { (require('efmls-configs.linters.yamllint')) } } })

    local seen
    nx.autocmd.create('BufWinEnter', {
      pattern = '*.yaml',
      callback = function()
        local efm = nx.lsp._config.efm
        seen = efm and efm.settings.languages.yaml or nil
      end,
    })

    local dir = nx.test.tempdir()
    local file = dir .. '/conf.yaml'
    nx.await(nx.fs.write(file, 'a: 1\n'))
    t:cmd('edit ' .. file)

    t:wait_for(function()
      return seen ~= nil
    end, { tries = 200, interval = 20, message = 'yaml was not loaded by the time the buffer was displayed' })
    nx.test.expect(seen).to_be_truthy()
  end)

  nx.test.it('rejects a load_timeout that is not a positive number of ms', function()
    nx.test
      .expect(function()
        efmls.setup({ load_timeout = 0, languages = { toml = { { lintCommand = 'true' } } } })
      end)
      .to_error('load_timeout')
  end)
end)
