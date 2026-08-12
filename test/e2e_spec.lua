-- End-to-end: the real efm-langserver subprocess, configured by this plugin,
-- formatting a Lua buffer through stylua. Proves the whole LAZY chain bemtvi actually
-- runs — opening the file fires the FileType autocmd `setup()` registered -> load()
-- resolves stylua over btv.fs and configures efm -> `btv.lsp` spawns efm ->
-- `didChangeConfiguration` delivers the languages map -> a `textDocument/formatting`
-- round-trip rewrites the buffer.
--
-- Needs `efm-langserver` and `stylua` on $PATH. When either is missing this is the
-- only spec that won't run (the wiring itself is covered hermetically by
-- load_spec / fs_spec).

local efmls = require('bemtvi-efmls-configs')

-- Async $PATH lookup (mirrors efmls-configs.fs, without exposing its internals).
local function on_path(name)
  for dir in string.gmatch(vim.env.PATH or '', '([^:]+)') do
    if btv.await(btv.fs.exists(dir .. '/' .. name)) then
      return true
    end
  end
  return false
end

btv.test.describe('bemtvi-efmls-configs end-to-end (real efm-langserver + stylua)', function()
  btv.test.it('formats a Lua buffer through efm', function(t)
    if not (on_path('efm-langserver') and on_path('stylua')) then
      btv.notify('skip: efm-langserver / stylua not on $PATH', 'warn')
      return
    end

    local dir = btv.test.tempdir()
    -- A project root marker so efm resolves this dir as the workspace.
    btv.await(btv.fs.write(dir .. '/stylua.toml', '\n'))
    local file = dir .. '/sample.lua'
    btv.await(btv.fs.write(file, 'local   x=1\n'))

    -- Register the lazy FileType autocmd for lua (stylua formatter), rooted on
    -- stylua.toml. Nothing is resolved yet — that happens when the file opens.
    efmls.setup({
      root_markers = { 'stylua.toml', '.git/' },
      languages = { lua = { (require('efmls-configs.formatters.stylua')) } },
    })

    -- Opening the file fires FileType lua -> the autocmd load()s stylua -> efm attaches.
    t:cmd('edit ' .. file)

    -- Wait for efm to attach to this buffer.
    t:wait_for(function()
      local clients = btv.lsp.clients({ bufnr = 0 })
      for _, c in ipairs(clients) do
        if c.name == 'efm' then
          return true
        end
      end
      return false
    end, { tries = 300, interval = 20, message = 'efm did not attach to the lua buffer' })

    -- Trigger formatting and wait for stylua's rewrite to land in the buffer.
    btv.lsp.format()
    t:wait_for(function()
      return t:line(1) == 'local x = 1'
    end, { tries = 300, interval = 20, message = 'efm/stylua did not reformat the buffer' })

    btv.test.expect(t:line(1)).to_be('local x = 1')
  end)
end)
