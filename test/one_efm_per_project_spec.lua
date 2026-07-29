-- Regression: ONE efm per project, not one per directory.
--
-- nxvim keys a language server by `(config name, root)`, and resolves that root from
-- the config's own `root_markers` — falling back to the buffer's own DIRECTORY when
-- there are none. `setup{ root_markers = }` used to reach only `settings.rootMarkers`,
-- which is efm's *internal* setting (where efm's linters think the project starts) and
-- says nothing to nxvim. So a project with `src/` and `test/` ran an efm per directory:
-- each load() then restarted all of them, and each held its own copy of the languages
-- map — against a plugin whose whole design is one shared efm.
--
-- Asserted by identity, not by counting: both buffers must be served by the SAME
-- client id. A count is confounded by servers other specs left running.
--
-- Self-contained: one synthetic filetype and a `cat` formatter. Needs only the
-- efm-langserver binary.

local efmls = require('nxvim-efmls-configs')

local function on_path(name)
  for dir in string.gmatch(vim.env.PATH or '', '([^:]+)') do
    if nx.await(nx.fs.exists(dir .. '/' .. name)) then
      return true
    end
  end
  return false
end

-- The id of the efm client serving `buf`, or nil.
local function efm_id(buf)
  local serving = nx.lsp.clients({ bufnr = buf, name = 'efm' })[1]
  return serving and serving.id or nil
end

nx.test.describe('one efm per project', function()
  nx.test.it('two directories of one project share a single efm', function(t)
    if not on_path('efm-langserver') then
      nx.notify('skip: efm-langserver not on $PATH', 'warn')
      return
    end

    -- A project root marked with `.git`, holding two source directories.
    local dir = nx.test.tempdir()
    nx.await(nx.fs.mkdir(dir .. '/.git', { recursive = true }))
    nx.await(nx.fs.mkdir(dir .. '/src', { recursive = true }))
    nx.await(nx.fs.mkdir(dir .. '/test', { recursive = true }))
    local a = dir .. '/src/a.txt'
    local b = dir .. '/test/b.txt'
    nx.await(nx.fs.write(a, 'alpha\n'))
    nx.await(nx.fs.write(b, 'beta\n'))

    local passthrough = nx.async(function()
      return { formatCommand = 'cat', formatStdin = true }
    end)

    -- `.git/` in efm's spelling — the trailing slash is efm's "directory marker"
    -- convention, and the plugin must translate it for nxvim's exact-name matching.
    efmls.setup({ root_markers = { '.git/' } })
    nx.await(efmls.load('ftproject', { passthrough }))

    t:cmd('edit ' .. a)
    t:cmd('set filetype=ftproject')
    local buf_a = nx.buf.current()
    t:wait_for(function()
      return efm_id(buf_a) ~= nil
    end, { tries = 400, interval = 20, message = 'efm never attached in src/' })

    t:cmd('edit ' .. b)
    t:cmd('set filetype=ftproject')
    local buf_b = nx.buf.current()
    t:wait_for(function()
      return efm_id(buf_b) ~= nil
    end, { tries = 400, interval = 20, message = 'efm never attached in test/' })

    nx.test.expect(efm_id(buf_a)).to_be(efm_id(buf_b))
  end)
end)
