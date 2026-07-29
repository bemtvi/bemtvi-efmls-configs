-- `:EfmlsHealth` reports efm's LIVE state, not just which binaries resolved.
--
-- A tool can resolve perfectly and still lint nothing, because efm never attached to
-- the buffer (its language was never loaded, or `efm-langserver` itself is missing and
-- the spawn failed). Reporting only the binaries made that look healthy — the exact
-- "loads ≠ works" failure the project convention warns about.
--
-- The report is read off `nx.lsp.clients`, so it must agree with the live registry
-- whether or not an earlier spec in this session left a real efm running.

local efmls = require('nxvim-efmls-configs')

local function joined(report)
  return table.concat(report.status, '\n')
end

nx.test.describe('nxvim-efmls-configs.health', function()
  nx.test.it("reports efm's live state, agreeing with nx.lsp.clients", function()
    local live = #nx.lsp.clients({ name = 'efm' }) > 0
    local report = efmls.health()

    nx.test.expect(report.running).to_be(live)
    nx.test.expect(joined(report)).to_match(live and 'efm is running' or 'efm is NOT running')
    nx.test.expect(report.attached).to_be(#nx.lsp.clients({ bufnr = 0, name = 'efm' }) > 0)
    nx.test.expect(joined(report)).to_match('servers on this buffer')
  end)

  nx.test.it('lists the languages a load has configured', function()
    nx.await(efmls.load('markdown', {
      { lintCommand = 'markdownlint --stdin', lintStdin = true },
    }, { force = true }))
    local report = efmls.health()
    nx.test.expect(joined(report)).to_match('languages loaded:.*markdown')
  end)
end)
