-- Regression: `load(ft, tools, { force = true })` must reach a RUNNING efm.
--
-- efm reads its `languages` map only at spawn, so replacing a language's tools is a
-- config change the live server can never observe on its own — the plugin has to
-- restart it. The restart used to be conditional on the language being NEW (`grew`),
-- which a force reload by definition is not: the config table showed the new tools
-- while the running efm kept applying the old ones, with nothing to see. Asserting on
-- `nx.lsp._config` alone (as load_spec does) cannot catch that — only formatting
-- through the live server can.
--
-- Self-contained: one synthetic filetype and two custom stdin formatters that produce
-- visibly different text. Needs only the efm-langserver binary.

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

nx.test.describe('force-reloading a language reaches the running efm', function()
  nx.test.it('a replaced formatter takes effect on the live server', function(t)
    if not on_path('efm-langserver') then
      nx.notify('skip: efm-langserver not on $PATH', 'warn')
      return
    end

    local dir = nx.test.tempdir()
    nx.await(nx.fs.write(dir .. '/root.marker', '\n'))

    -- Two formatters with visibly different output, so the assertion distinguishes
    -- "the new tool ran" from "the old one did" rather than merely "something ran".
    local upper = dir .. '/upper.sh'
    local xes = dir .. '/xes.sh'
    nx.await(nx.fs.write(upper, '#!/bin/sh\ntr a-z A-Z\n'))
    nx.await(nx.fs.write(xes, '#!/bin/sh\ntr a-z x\n'))
    nx.await(nx.run({ cmd = 'chmod', args = { '+x', upper, xes } }))

    local function formatter(script)
      return nx.async(function()
        return { formatCommand = script, formatStdin = true }
      end)
    end

    efmls.setup({ root_markers = { 'root.marker' } })

    local file = dir .. '/one.txt'
    nx.await(nx.fs.write(file, 'alpha\n'))
    nx.await(efmls.load('ftforce', { formatter(upper) }))
    t:cmd('edit ' .. file)
    t:cmd('set filetype=ftforce')
    t:wait_for(efm_attached, { tries = 300, interval = 20, message = 'efm never attached' })

    nx.lsp.format()
    t:wait_for(function()
      return t:line(1) == 'ALPHA'
    end, { tries = 200, interval = 20, message = 'the first formatter never ran' })

    -- Replace the language's tools while efm is already RUNNING. Nothing about the
    -- filetype set changes — only the tools behind it.
    nx.await(efmls.load('ftforce', { formatter(xes) }, { force = true }))
    t:wait_for(efm_attached, {
      tries = 300,
      interval = 20,
      message = 'efm never came back after the force reload',
    })

    -- Reset the buffer text, then format with what should now be the `xes` formatter.
    t:cmd('%delete')
    t:feed('ialpha<Esc>')
    t:wait_for(function()
      nx.lsp.format()
      return t:line(1) == 'xxxxx'
    end, {
      tries = 200,
      interval = 20,
      message = 'the replaced formatter never reached the live efm (still the old one)',
    })
    nx.test.expect(t:line(1)).to_be('xxxxx')
  end)
end)
