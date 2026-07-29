-- efm is a SECOND server on the buffer, so formatting has to be aimed at it.
--
-- Every enabled config whose filetypes match attaches to a buffer, and a bare
-- `nx.lsp.format()` picks the first attached server advertising `documentFormatting`
-- in config-NAME order. `efm` loses that race to anything sorting earlier (`biome`,
-- `clangd`, `denols`, `basedpyright`, …), which silently formats with a tool the user
-- never configured here. `efmls.format()` names efm, so it always runs the formatter
-- this plugin set up.
--
-- The rival server here is a second efm-langserver under the name `aaa` (it sorts
-- first) whose only formatter uppercases through `tr` — so which server formatted is
-- unambiguous from the buffer text alone.
--
-- Needs `efm-langserver` and `stylua` on $PATH, like the e2e spec.

local efmls = require('nxvim-efmls-configs')

local function on_path(name)
  for dir in string.gmatch(vim.env.PATH or '', '([^:]+)') do
    if nx.await(nx.fs.exists(dir .. '/' .. name)) then
      return true
    end
  end
  return false
end

nx.test.describe('formatting is aimed at efm', function()
  nx.test.it('formats with efm even when another server sorts first', function(t)
    if not (on_path('efm-langserver') and on_path('stylua')) then
      nx.notify('skip: efm-langserver / stylua not on $PATH', 'warn')
      return
    end

    local dir = nx.test.tempdir()
    nx.await(nx.fs.write(dir .. '/stylua.toml', '\n'))
    local file = dir .. '/aimed.lua'
    nx.await(nx.fs.write(file, 'local   x=1\n'))

    -- The rival: same binary, earlier name, an obviously-different formatter.
    nx.lsp.config('aaa', {
      cmd = { 'efm-langserver' },
      filetypes = { 'lua' },
      root_markers = { 'stylua.toml' },
      init_options = { documentFormatting = true },
      settings = {
        rootMarkers = { 'stylua.toml' },
        languages = { lua = { { formatCommand = 'tr a-z A-Z', formatStdin = true } } },
      },
    })
    nx.lsp.enable({ 'aaa' })

    efmls.setup({
      root_markers = { 'stylua.toml' },
      languages = { lua = { (require('efmls-configs.formatters.stylua')) } },
    })

    t:cmd('edit ' .. file)

    t:wait_for(function()
      local seen = {}
      for _, c in ipairs(nx.lsp.clients({ bufnr = 0 })) do
        seen[c.name] = true
      end
      return seen.efm and seen.aaa
    end, { tries = 400, interval = 20, message = 'efm and the rival server did not both attach' })

    -- Aimed: stylua's reflow, NOT the rival's uppercase.
    efmls.format()
    t:wait_for(function()
      return t:line(1) ~= 'local   x=1'
    end, { tries = 300, interval = 20, message = 'efmls.format() never changed the buffer' })
    nx.test.expect(t:line(1)).to_be('local x = 1')

    nx.lsp.disable({ 'aaa' })
  end)

  nx.test.it('format-on-save writes the formatted text, not the pre-format text', function(t)
    if not (on_path('efm-langserver') and on_path('stylua')) then
      nx.notify('skip: efm-langserver / stylua not on $PATH', 'warn')
      return
    end

    local dir = nx.test.tempdir()
    nx.await(nx.fs.write(dir .. '/stylua.toml', '\n'))
    local file = dir .. '/onsave.lua'
    nx.await(nx.fs.write(file, 'local   y=2\n'))

    efmls.setup({
      root_markers = { 'stylua.toml' },
      languages = { lua = { (require('efmls-configs.formatters.stylua')) } },
    })

    -- The documented recipe: BufWritePre is gated, so RETURNING the promise holds the
    -- write until efm's edits are in the buffer. Drop the `return` and the file on disk
    -- is the unformatted text — the whole point of the gate.
    nx.autocmd.create('BufWritePre', {
      pattern = '*.lua',
      callback = function()
        return efmls.format()
      end,
    })

    t:cmd('edit ' .. file)
    t:wait_for(function()
      for _, c in ipairs(nx.lsp.clients({ bufnr = 0 })) do
        if c.name == 'efm' then
          return true
        end
      end
      return false
    end, { tries = 400, interval = 20, message = 'efm did not attach before the write' })

    t:cmd('write')
    -- Poll the file itself, in the test body: reading it is async, and a `wait_for`
    -- predicate runs outside the async context.
    local saved
    for _ = 1, 300 do
      saved = nx.await(nx.fs.read(file))
      if saved == 'local y = 2\n' then
        break
      end
      t:sleep(20)
    end
    nx.test.expect(saved).to_be('local y = 2\n')
  end)
end)
