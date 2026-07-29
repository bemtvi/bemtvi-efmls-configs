-- A file opened BEFORE efm was enabled still gets served.
--
-- Loading is lazy and asynchronous: the first `load()` for a filetype probes the
-- filesystem once per tool, so efm is registered and enabled several ticks after the
-- `FileType` that triggered it. Any buffer read inside that window has already had its
-- `FileType` fired, and nothing re-fires it for a buffer whose filetype is set — so the
-- catch-up `nx.lsp.enable` does is the only thing that can still reach those buffers.
-- It sweeps every open buffer (not just the current one), and the buffer left behind
-- attaches when it is displayed again.
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

local function has_efm(buf)
  for _, c in ipairs(nx.lsp.clients({ bufnr = buf })) do
    if c.name == 'efm' then
      return true
    end
  end
  return false
end

nx.test.describe('efm reaches buffers opened before it was enabled', function()
  nx.test.it('serves a file read while the first load was still in flight', function(t)
    if not (on_path('efm-langserver') and on_path('stylua')) then
      nx.notify('skip: efm-langserver / stylua not on $PATH', 'warn')
      return
    end

    local dir = nx.test.tempdir()
    nx.await(nx.fs.write(dir .. '/stylua.toml', '\n'))
    local first = dir .. '/first.lua'
    local second = dir .. '/second.lua'
    nx.await(nx.fs.write(first, 'local   x=1\n'))
    nx.await(nx.fs.write(second, 'local   y=2\n'))

    efmls.setup({
      root_markers = { 'stylua.toml' },
      languages = { lua = { (require('efmls-configs.formatters.stylua')) } },
    })

    -- Back to back: both reads land before the first load() settles, so efm is
    -- enabled only once BOTH FileType events are already spent.
    t:cmd('edit ' .. first)
    local buf_first = nx.buf.current()
    t:cmd('edit ' .. second)
    local buf_second = nx.buf.current()

    t:wait_for(function()
      return has_efm(buf_second)
    end, { tries = 400, interval = 20, message = 'efm did not attach to the current buffer' })

    -- The buffer left behind: it was bound by the same catch-up, so displaying it
    -- again serves it (document sync runs for the current buffer).
    t:cmd('buffer ' .. buf_first)
    t:wait_for(function()
      return has_efm(buf_first)
    end, {
      tries = 400,
      interval = 20,
      message = 'the buffer read before efm was enabled never got efm',
    })
    nx.test.expect(has_efm(buf_first)).to_be(true)
  end)
end)
