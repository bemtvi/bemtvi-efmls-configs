-- The async binary-resolution seam: `fs.executable` resolves a real path over
-- `nx.fs` (never blocking), recording the outcome for `:EfmlsHealth`.

local fs = require('efmls-configs.fs')

nx.test.describe('efmls-configs.fs.executable (async)', function()
  nx.test.it('resolves a present binary to a real path and records it as ok', function()
    fs.reset_health()
    -- `sh` is on $PATH on every host this runs on.
    local path = nx.await(fs.executable('sh'))
    nx.test.expect(path:match('/sh$')).to_be_truthy()

    local found = false
    for _, ok in ipairs(_G._efmls.healthcheck.ok) do
      if ok:find('sh', 1, true) then
        found = true
      end
    end
    nx.test.expect(found).to_be(true)
  end)

  nx.test.it('falls back to the bare name and records an error for a missing binary', function()
    fs.reset_health()
    local bogus = 'efmls-no-such-binary-xyzzy'
    local path = nx.await(fs.executable(bogus))
    nx.test.expect(path).to_be(bogus)

    local found = false
    for _, err in ipairs(_G._efmls.healthcheck.errors) do
      if err:find(bogus, 1, true) then
        found = true
      end
    end
    nx.test.expect(found).to_be(true)
  end)

  nx.test.it('has_executable is true for a present binary, false for a missing one', function()
    nx.test.expect(nx.await(fs.has_executable('sh'))).to_be(true)
    nx.test.expect(nx.await(fs.has_executable('efmls-no-such-binary-xyzzy'))).to_be(false)
  end)
end)
