-- The bundled default language map (inlined data — no disk read). Each entry is now
-- an async tool factory.

local defaults = require('efmls-configs.defaults')

nx.test.describe('efmls-configs.defaults.languages', function()
  nx.test.it('maps the documented filetypes to lists of async tool factories', function()
    local langs = defaults.languages()

    -- A representative spread of the SUPPORTED_LIST defaults.
    nx.test.expect(langs.lua).to_be_truthy()
    nx.test.expect(langs.python).to_be_truthy()
    nx.test.expect(langs.go).to_be_truthy()
    nx.test.expect(langs.typescript).to_be_truthy()

    -- lua gets luacheck (linter) + stylua (formatter), each an async factory.
    nx.test.expect(#langs.lua).to_be(2)
    nx.test.expect(type(langs.lua[1])).to_be('function')
    nx.test.expect(type(langs.lua[2])).to_be('function')
  end)

  nx.test.it('awaiting a factory yields a resolved efm config with a real command', function()
    local langs = defaults.languages()
    local lint = nx.await(langs.lua[1]()) -- luacheck
    local fmt = nx.await(langs.lua[2]()) -- stylua

    nx.test.expect(lint.lintCommand).to_be_truthy()
    nx.test.expect(fmt.formatCommand).to_be_truthy()
    -- Real resolution, not a placeholder.
    nx.test.expect(lint.lintCommand:find('${EFMLS', 1, true)).to_be_nil()
    nx.test.expect(lint.lintCommand).to_match('luacheck')
  end)
end)
