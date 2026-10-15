-- The reek preset, end to end through the real efm-langserver against a stand-in
-- `reek` that keeps reek 6's CLI contract: it rejects a `--format` reek doesn't have
-- (the preset used to pass `txt`, which made every run fail), prints the text report
-- in the shape the location flags ask for, smells off the stdin it is fed, and exits
-- 2 when it found smells, 0 when it found none.
--
-- Needs `efm-langserver` on $PATH, like the e2e spec. The stand-in needs `sh` + `awk`.

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

-- One smell per `def <name>(x)` line, the way reek 6.6 reports
-- UncommunicativeParameterName. `--single-line` picks `<file>:<line>: ` over
-- `[<line>]:`, and without `--no-documentation` each line ends in a docs link.
local MOCK_REEK = [=[#!/bin/sh
fmt=text single= doc=1 file=
while [ $# -gt 0 ]; do
  case $1 in
    -f|--format)
      shift
      case $1 in
        html|text|yaml|json|xml|github) fmt=$1 ;;
        *) echo "invalid argument: --format $1 (OptionParser::InvalidArgument)" >&2; exit 1 ;;
      esac ;;
    -s|--single-line) single=1 ;;
    --no-documentation) doc= ;;
    --stdin-filename) shift; file=$1 ;;
    --no-color|--no-progress|--force-exclusion) ;;
    *) echo "invalid option: $1 (OptionParser::InvalidOption)" >&2; exit 1 ;;
  esac
  shift
done
[ "$fmt" = text ] || { echo "stand-in reek only speaks --format text" >&2; exit 1; }
[ -n "$file" ] || { echo "stand-in reek reads stdin only with --stdin-filename" >&2; exit 1; }
exec awk -v f="$file" -v single="$single" -v doc="$doc" '
  $0 ~ /def [a-z_]+\(x\)/ {
    loc = single ? sprintf("%s:%d: ", f, NR) : sprintf("[%d]:", NR)
    msg = "  " loc "UncommunicativeParameterName: has the parameter name \047x\047"
    if (doc) msg = msg " [https://github.com/troessner/reek/blob/v6.6.0/docs/Uncommunicative-Parameter-Name.md]"
    out[++n] = msg
  }
  END {
    if (n == 0) exit 0
    print f " -- " n " warning" (n > 1 ? "s" : "") ":"
    for (i = 1; i <= n; i++) print out[i]
    exit 2
  }'
]=]

local function reek_diagnostics(buf)
  local found = {}
  for _, d in ipairs(btv.diagnostic.get(buf)) do
    if d.source == 'efm/reek' then
      found[#found + 1] = d
    end
  end
  return found
end

btv.test.describe('reek preset (efm + stand-in reek)', function()
  btv.test.it('reports each smell on its line, as a warning, without the docs link', function(t)
    if not (on_path('efm-langserver') and on_path('awk')) then
      btv.notify('skip: efm-langserver / awk not on $PATH', 'warn')
      return
    end

    local dir = btv.test.tempdir()
    local bin = dir .. '/bin'
    btv.await(btv.fs.mkdir(bin))
    btv.await(btv.fs.write(bin .. '/reek', MOCK_REEK))
    btv.test.expect(btv.await(btv.run({ cmd = { 'chmod', '+x', bin .. '/reek' } })).code).to_be(0)
    btv.await(btv.fs.write(dir .. '/Gemfile', "source 'https://rubygems.org'\n"))
    local file = dir .. '/foo.rb'
    btv.await(btv.fs.write(file, '# Doc\nclass Foo\n  def bar(x)\n    x\n  end\nend\n'))

    -- Put the stand-in ahead of any real reek for fs.executable's $PATH lookup.
    local old_path = btv.env.get('PATH')
    btv.env.set('PATH', bin .. ':' .. (type(old_path) == 'string' and old_path or ''))
    local ok, err = pcall(function()
      efmls.setup({
        root_markers = { 'Gemfile' },
        languages = { ruby = { (require('efmls-configs.linters.reek')) } },
      })
      t:cmd('edit ' .. file)
      local buf = btv.buf.current()

      t:wait_for(function()
        return #btv.lsp.clients({ bufnr = buf, name = 'efm' }) > 0
      end, { tries = 400, interval = 20, message = 'efm did not attach to the ruby buffer' })
      -- The preset leaves efm's `lintAfterOpen` off (as every preset does), so efm
      -- lints on a change, not on open. Loading ruby restarts an efm that an earlier
      -- spec left running, and a change that reaches the outgoing instance is linted
      -- by nobody, so edit again until one lands on the live server.
      for _ = 1, 10 do
        t:feed('Go<Esc>')
        local linted = pcall(function()
          t:wait_for(function()
            return #reek_diagnostics(buf) > 0
          end, { tries = 50, interval = 20 })
        end)
        if linted then
          break
        end
      end
      btv.test.expect(#reek_diagnostics(buf) > 0).to_be(true)

      local diags = reek_diagnostics(buf)
      btv.test.expect(#diags).to_be(1)
      btv.test.expect(diags[1].lnum).to_be(2) -- 0-based: `def bar(x)` is line 3
      btv.test.expect(diags[1].severity).to_be(2)
      btv.test.expect(diags[1].message).to_match("UncommunicativeParameterName: has the parameter name 'x'")
      btv.test.expect(diags[1].message:find('https://', 1, true)).to_be_nil()
    end)
    btv.env.set('PATH', old_path)
    if not ok then
      error(err, 0)
    end
  end)
end)
