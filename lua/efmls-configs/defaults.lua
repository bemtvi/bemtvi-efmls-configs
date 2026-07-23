-- The default linter/formatter set per language (mirrors doc/SUPPORTED_LIST.md).
--
-- Native port: upstream read `defaults.json` off disk at call time (`io.open` +
-- `vim.json.decode`). nxvim has no blocking Lua fs, so the mapping is inlined here as
-- data — `M.languages()` stays synchronous, collecting each tool preset through
-- `require`. Each preset is an `nx.async` factory (`() -> promise` of the efm config
-- table); `nxvim-efmls-configs.setup` awaits them to build the concrete map.

local M = {}

-- language -> { linters = {…}, formatters = {…} }, keyed by the module name under
-- `efmls-configs.linters.*` / `efmls-configs.formatters.*`.
local DEFAULTS = {
  { languages = { 'css', 'scss', 'less', 'sass' }, linters = { 'stylelint' }, formatters = { 'prettier' } },
  {
    languages = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
    linters = { 'eslint' },
    formatters = { 'prettier' },
  },
  { languages = { 'go' }, linters = { 'golangci_lint' } },
  { languages = { 'html' }, linters = { 'htmlhint' }, formatters = { 'prettier' } },
  { languages = { 'lua' }, linters = { 'luacheck' }, formatters = { 'stylua' } },
  { languages = { 'nix' }, formatters = { 'alejandra' } },
  { languages = { 'php' }, linters = { 'phpcs' }, formatters = { 'phpcbf' } },
  { languages = { 'python' }, linters = { 'flake8' }, formatters = { 'autopep8' } },
  { languages = { 'ruby' }, linters = { 'reek' } },
  { languages = { 'vim' }, linters = { 'vint' } },
  { languages = { 'blade' }, formatters = { 'blade_formatter' } },
  { languages = { 'proto' }, linters = { 'buf' }, formatters = { 'buf' } },
}

---Default language map: `{ [filetype] = { <async tool factory>, … } }`. Each factory
---is an `nx.async` function returning a promise of its efm config table; await them
---(as `setup()` does) to get the concrete `languages` map.
---@return table
function M.languages()
  local languages = {}
  for _, group in ipairs(DEFAULTS) do
    for _, lang in ipairs(group.languages) do
      local key = string.lower(lang)
      local tools = {}
      for _, linter in ipairs(group.linters or {}) do
        -- Parenthesised: nxvim's `require` returns (module, loader) — truncate to the
        -- module so the loader path does not leak in as a second list element.
        table.insert(tools, (require('efmls-configs.linters.' .. linter)))
      end
      for _, formatter in ipairs(group.formatters or {}) do
        table.insert(tools, (require('efmls-configs.formatters.' .. formatter)))
      end
      languages[key] = tools
    end
  end
  return languages
end

return M
