-- Metadata
-- languages: elixir
-- url: https://hexdocs.pm/mix/Mix.html

local fs = require('efmls-configs.fs')

return nx.async(function()
  local formatter = 'mix'
  local args = 'format --stdin-filename ${INPUT} -'
  local command = string.format('%s %s', nx.await(fs.executable(formatter)), args)

  return {
    formatCommand = command,
    formatStdin = true,
    rootMarkers = {
      '.formatter.exs',
      'mix.exs',
    },
  }
end)
