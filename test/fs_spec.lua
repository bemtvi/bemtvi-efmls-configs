-- The async binary-resolution seam: `fs.executable` resolves a real path over
-- `btv.fs` (never blocking), recording the outcome for `:EfmlsHealth`.

local fs = require('efmls-configs.fs')

btv.test.describe('efmls-configs.fs.executable (async)', function()
  btv.test.it('resolves a present binary to a real path and records it as ok', function()
    fs.reset_health()
    -- `sh` is on $PATH on every host this runs on.
    local path = btv.await(fs.executable('sh'))
    btv.test.expect(path:match('/sh$')).to_be_truthy()

    local found = false
    for _, ok in ipairs(fs.health().ok) do
      if ok:find('sh', 1, true) then
        found = true
      end
    end
    btv.test.expect(found).to_be(true)
  end)

  btv.test.it('falls back to the bare name and records an error for a missing binary', function()
    fs.reset_health()
    local bogus = 'efmls-no-such-binary-xyzzy'
    local path = btv.await(fs.executable(bogus))
    btv.test.expect(path).to_be(bogus)

    local found = false
    for _, err in ipairs(fs.health().errors) do
      if err:find(bogus, 1, true) then
        found = true
      end
    end
    btv.test.expect(found).to_be(true)
  end)

  btv.test.it('has_executable is true for a present binary, false for a missing one', function()
    btv.test.expect(btv.await(fs.has_executable('sh'))).to_be(true)
    btv.test.expect(btv.await(fs.has_executable('efmls-no-such-binary-xyzzy'))).to_be(false)
  end)
end)
