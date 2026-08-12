-- `:EfmlsHealth` reports efm's LIVE state, not just which binaries resolved.
--
-- A tool can resolve perfectly and still lint nothing, because efm never attached to
-- the buffer (its language was never loaded, or `efm-langserver` itself is missing and
-- the spawn failed). Reporting only the binaries made that look healthy — the exact
-- "loads ≠ works" failure the project convention warns about.
--
-- The report is read off `btv.lsp.clients`, so it must agree with the live registry
-- whether or not an earlier spec in this session left a real efm running.

local efmls = require('bemtvi-efmls-configs')

local function joined(report)
  return table.concat(report.status, '\n')
end

btv.test.describe('bemtvi-efmls-configs.health', function()
  btv.test.it("reports efm's live state, agreeing with btv.lsp.clients", function()
    local live = #btv.lsp.clients({ name = 'efm' }) > 0
    local report = efmls.health()

    btv.test.expect(report.running).to_be(live)
    btv.test.expect(joined(report)).to_match(live and 'efm is running' or 'efm is NOT running')
    btv.test.expect(report.attached).to_be(#btv.lsp.clients({ bufnr = 0, name = 'efm' }) > 0)
    btv.test.expect(joined(report)).to_match('servers on this buffer')
  end)

  btv.test.it('lists the languages a load has configured', function()
    btv.await(efmls.load('markdown', {
      { lintCommand = 'markdownlint --stdin', lintStdin = true },
    }, { force = true }))
    local report = efmls.health()
    btv.test.expect(joined(report)).to_match('languages loaded:.*markdown')
  end)
end)
