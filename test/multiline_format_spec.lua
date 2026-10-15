-- Regression: a multi-line reformat must not scramble lines. efm returns a LINE diff
-- (multiple zero-width inserts at the same position); applying them in the wrong order
-- swapped adjacent reformatted lines (e.g. a function header and its body). Fixed in
-- bemtvi core (apply_edits_to tie-breaking).

local efmls = require('bemtvi-efmls-configs')

local function on_path(name)
  -- `btv.env.get` returns a non-string sentinel (v:null) for an unset variable.
  local path = btv.env.get('PATH')
  for dir in string.gmatch(type(path) == 'string' and path or '', '([^:]+)') do
    if btv.await(btv.fs.exists(dir .. '/' .. name)) then
      return true
    end
  end
  return false
end

btv.test.describe('multiline format (no scrambling)', function()
  btv.test.it('reformats every line, in order, through efm + stylua', function(t)
    if not (on_path('efm-langserver') and on_path('stylua')) then
      btv.notify('skip', 'warn')
      return
    end
    local dir = btv.test.tempdir()
    -- Explicit style so the expected output is deterministic across stylua versions.
    btv.await(
      btv.fs.write(
        dir .. '/stylua.toml',
        'indent_type = "Spaces"\nindent_width = 2\nquote_style = "AutoPreferDouble"\n'
      )
    )
    local file = dir .. '/s.lua'
    btv.await(btv.fs.write(
      file,
      table.concat({
        "local    greeting     =    'hello'",
        'local unused_local = 42',
        '',
        'local function shout(   name )',
        "        return   greeting .. ' ' ..    string.upper(name) .. '!'",
        'end',
        '',
        'print(shout(greeting))',
        '',
      }, '\n')
    ))

    efmls.setup({ root_markers = { 'stylua.toml' } })
    btv.await(efmls.load('lua', { require('efmls-configs.formatters.stylua') }))
    t:cmd('edit ' .. file)
    t:wait_for(function()
      for _, c in ipairs(btv.lsp.clients({ bufnr = 0 })) do
        if c.name == 'efm' then
          return true
        end
      end
    end, { tries = 300, interval = 20, message = 'efm never attached' })

    btv.lsp.format()
    local want = table.concat({
      'local greeting = "hello"',
      'local unused_local = 42',
      '',
      'local function shout(name)',
      '  return greeting .. " " .. string.upper(name) .. "!"',
      'end',
      '',
      'print(shout(greeting))',
    }, '\n')
    t:wait_for(function()
      return table.concat(t:lines(), '\n') == want
    end, { tries = 300, interval = 20, message = 'buffer was scrambled or not formatted' })
    btv.test.expect(table.concat(t:lines(), '\n')).to_be(want)
  end)
end)
