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
end)
