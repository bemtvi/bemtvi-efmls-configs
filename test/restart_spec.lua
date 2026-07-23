-- Regression: lazy loading a language AFTER efm is already running must still work.
-- efm reads its `languages` map only at spawn, so the plugin restarts the shared efm
-- (via nx.lsp.restart) when a language is added — this proves the newly-loaded
-- language actually formats through the restarted, single efm.
--
-- Self-contained: two synthetic filetypes, each with a custom stdin formatter
-- (`tr a-z A-Z`). Needs only the efm-langserver binary.

local efmls = require('nxvim-efmls-configs')

local function on_path(name)
  for dir in string.gmatch(vim.env.PATH or '', '([^:]+)') do
    if nx.await(nx.fs.exists(dir .. '/' .. name)) then
      return true
    end
  end
  return false
end

local function efm_attached()
  for _, c in ipairs(nx.lsp.clients({ bufnr = 0 })) do
    if c.name == 'efm' then
      return true
    end
  end
  return false
end

nx.test.describe('lazy multi-language through one efm (restart)', function()
  nx.test.it('a language loaded after efm is running formats via the restarted efm', function(t)
    if not on_path('efm-langserver') then
      nx.notify('skip: efm-langserver not on $PATH', 'warn')
      return
    end

    local dir = nx.test.tempdir()
    nx.await(nx.fs.write(dir .. '/root.marker', '\n'))
    local script = dir .. '/upper.sh'
    nx.await(nx.fs.write(script, '#!/bin/sh\ntr a-z A-Z\n'))
    nx.await(nx.run({ cmd = 'chmod', args = { '+x', script } }))

    -- A custom formatter preset (uppercase via stdin) — a plain async factory.
    local upper = nx.async(function()
      return { formatCommand = script, formatStdin = true }
    end)

    efmls.setup({ root_markers = { 'root.marker' } })

    -- Language ONE: load, open, format. efm spawns and is now RUNNING.
    local f1 = dir .. '/one.txt'
    nx.await(nx.fs.write(f1, 'alpha\n'))
    nx.await(efmls.load('ftone', { upper }))
    t:cmd('edit ' .. f1)
    t:cmd('set filetype=ftone')
    t:wait_for(efm_attached, { tries = 300, interval = 20, message = 'efm never attached to ftone' })
    nx.lsp.format()
    t:wait_for(function()
      return t:line(1) == 'ALPHA'
    end, { tries = 200, interval = 20, message = 'ftone not formatted' })

    -- Language TWO: loaded AFTER efm is already running. The plugin restarts efm so
    -- the grown languages map (now covering fttwo) reaches the live server.
    local f2 = dir .. '/two.txt'
    nx.await(nx.fs.write(f2, 'beta\n'))
    nx.await(efmls.load('fttwo', { upper }))
    t:cmd('edit ' .. f2)
    t:cmd('set filetype=fttwo')
    t:wait_for(efm_attached, { tries = 300, interval = 20, message = 'efm never attached to fttwo' })
    nx.lsp.format()
    t:wait_for(function()
      return t:line(1) == 'BETA'
    end, { tries = 200, interval = 20, message = 'fttwo not formatted — restart did not deliver the new language' })

    nx.test.expect(t:line(1)).to_be('BETA')

    -- One shared efm serves both filetypes.
    nx.test.expect(nx.lsp._config.efm.settings.languages.ftone).to_be_truthy()
    nx.test.expect(nx.lsp._config.efm.settings.languages.fttwo).to_be_truthy()
  end)
end)
