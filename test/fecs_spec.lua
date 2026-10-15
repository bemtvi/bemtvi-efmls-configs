-- The fecs preset, end to end through the real efm-langserver against a stand-in
-- `fecs` that writes its stream output the way fecs 1.6.4 does: the formatted text,
-- one extra newline, then its `console.timeEnd` timing line, all on stdout. Without
-- the preset's filter, formatting wrote that timing line into the buffer.
--
-- Needs `efm-langserver` on $PATH, like the e2e spec. The stand-in needs `sh` + `sed`.

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

-- "Formats" by normalising the spacing around `=`, so the result depends on the input.
local MOCK_FECS = [=[#!/bin/sh
[ "$1" = format ] || { echo "stand-in fecs only implements format" >&2; exit 1; }
shift
stream=
for a; do
  case $a in
    --stream) stream=1 ;;
    --silent|--ignore) ;;
    -*) echo "stand-in fecs: unknown option $a" >&2; exit 1 ;;
  esac
done
[ -n "$stream" ] || { echo "stand-in fecs reads stdin only with --stream" >&2; exit 1; }
echo "(node:1) [DEP0055] DeprecationWarning: The util.isRegExp API is deprecated." >&2
sed 's/ *= */ = /g'
printf '\nfecs@1.6.4: 3.215ms\n'
]=]

btv.test.describe('fecs preset (efm + stand-in fecs)', function()
  btv.test.it('formats without writing fecs timing line into the buffer', function(t)
    if not (on_path('efm-langserver') and on_path('awk') and on_path('sed')) then
      btv.notify('skip: efm-langserver / awk / sed not on $PATH', 'warn')
      return
    end

    local dir = btv.test.tempdir()
    local bin = dir .. '/bin'
    btv.await(btv.fs.mkdir(bin))
    btv.await(btv.fs.write(bin .. '/fecs', MOCK_FECS))
    btv.test.expect(btv.await(btv.run({ cmd = { 'chmod', '+x', bin .. '/fecs' } })).code).to_be(0)
    btv.await(btv.fs.write(dir .. '/package.json', '{}\n'))
    local file = dir .. '/a.js'
    btv.await(btv.fs.write(file, 'var a=1;\nvar b  =  2;\n'))

    -- Put the stand-in ahead of any real fecs for fs.executable's $PATH lookup.
    local old_path = btv.env.get('PATH')
    btv.env.set('PATH', bin .. ':' .. (type(old_path) == 'string' and old_path or ''))
    local ok, err = pcall(function()
      efmls.setup({
        root_markers = { 'package.json' },
        languages = { javascript = { (require('efmls-configs.formatters.fecs')) } },
      })
      t:cmd('edit ' .. file)
      local buf = btv.buf.current()

      t:wait_for(function()
        return #btv.lsp.clients({ bufnr = buf, name = 'efm' }) > 0
      end, { tries = 400, interval = 20, message = 'efm did not attach to the javascript buffer' })

      btv.lsp.format()
      t:wait_for(function()
        return t:line(1) == 'var a = 1;'
      end, { tries = 400, interval = 20, message = 'efm/fecs did not reformat the buffer' })

      btv.test.expect(t:lines()).to_equal({ 'var a = 1;', 'var b = 2;' })
    end)
    btv.env.set('PATH', old_path)
    if not ok then
      error(err, 0)
    end
  end)
end)
