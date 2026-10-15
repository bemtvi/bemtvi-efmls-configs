-- `fs.Scope.BUNDLE`: a Bundler project's own tool binaries win over $PATH.
--
-- Bundler puts runnable executables in two places: `bin/<name>` binstubs (from
-- `bundle binstubs`, which load `bundler/setup` themselves), and
-- `<bundle path>/ruby/<ruby version>/bin/<name>` when gems are installed into the
-- project (`bundle config set --local path vendor/bundle`, `BUNDLE_PATH`). The latter
-- are plain RubyGems wrappers that do not see the project's gems on their own, so
-- they are run through `bundle exec`, pinned to the project's Gemfile.

local fs = require('efmls-configs.fs')

local function chmod_x(path)
  btv.test.expect(btv.await(btv.run({ cmd = { 'chmod', '+x', path } })).code).to_be(0)
end

local function write_exe(path, body)
  btv.await(btv.fs.mkdir(btv.fname.modify(path, ':h'), { recursive = true }))
  btv.await(btv.fs.write(path, body or '#!/bin/sh\n'))
  chmod_x(path)
end

-- Run `fn` with the editor's cwd at `dir` (the base `fs.executable` resolves
-- project-local tools against), restoring the old cwd after.
local function in_project(t, dir, fn)
  local old = btv.cwd()
  t:cmd('cd ' .. dir)
  t:wait_for(function()
    return btv.cwd() ~= old
  end, { tries = 100, interval = 10, message = 'cwd did not change' })
  local ok, err = pcall(fn, btv.cwd())
  t:cmd('cd ' .. old)
  if not ok then
    error(err, 0)
  end
end

-- Put a stand-in `bundle` first on fs.executable's $PATH lookup.
local function with_bundle_on_path(fn)
  local bindir = btv.test.tempdir() .. '/bin'
  write_exe(bindir .. '/bundle')
  local old_path = btv.env.get('PATH')
  btv.env.set('PATH', bindir .. ':' .. (type(old_path) == 'string' and old_path or ''))
  local ok, err = pcall(fn, bindir .. '/bundle')
  btv.env.set('PATH', old_path)
  if not ok then
    error(err, 0)
  end
end

local TOOL = 'efmls-bundled-tool-xyzzy' -- on no real $PATH

btv.test.describe('fs.Scope.BUNDLE', function()
  btv.test.it('resolves a bin/ binstub', function(t)
    local dir = btv.test.tempdir()
    in_project(t, dir, function(root)
      write_exe(root .. '/bin/' .. TOOL)
      btv.test.expect(btv.await(fs.executable(TOOL, fs.Scope.BUNDLE))).to_be(root .. '/bin/' .. TOOL)
    end)
  end)

  btv.test.it('runs a gem installed under vendor/bundle through bundle exec', function(t)
    local dir = btv.test.tempdir()
    with_bundle_on_path(function(bundle)
      in_project(t, dir, function(root)
        btv.await(btv.fs.write(root .. '/Gemfile', "source 'https://rubygems.org'\n"))
        write_exe(root .. '/vendor/bundle/ruby/3.4.0/bin/' .. TOOL)
        btv.test
          .expect(btv.await(fs.executable(TOOL, fs.Scope.BUNDLE)))
          .to_be(string.format("BUNDLE_GEMFILE='%s/Gemfile' %s exec %s", root, bundle, TOOL))
      end)
    end)
  end)

  btv.test.it('honors the project BUNDLE_PATH from .bundle/config', function(t)
    local dir = btv.test.tempdir()
    with_bundle_on_path(function(bundle)
      in_project(t, dir, function(root)
        btv.await(btv.fs.write(root .. '/Gemfile', "source 'https://rubygems.org'\n"))
        btv.await(btv.fs.mkdir(root .. '/.bundle'))
        btv.await(btv.fs.write(root .. '/.bundle/config', '---\nBUNDLE_PATH: ".gems"\n'))
        write_exe(root .. '/.gems/ruby/3.3.0/bin/' .. TOOL)
        btv.test
          .expect(btv.await(fs.executable(TOOL, fs.Scope.BUNDLE)))
          .to_be(string.format("BUNDLE_GEMFILE='%s/Gemfile' %s exec %s", root, bundle, TOOL))
      end)
    end)
  end)

  btv.test.it('every BUNDLE preset runs the project binstub', function(t)
    local dir = btv.test.tempdir()
    in_project(t, dir, function(root)
      local presets = { rubocop = 'rubocop', reek = 'reek', sorbet = 'srb', slim_lint = 'slim-lint' }
      for preset, bin in pairs(presets) do
        write_exe(root .. '/bin/' .. bin)
        local cfg = btv.await(require('efmls-configs.linters.' .. preset)())
        local want = root .. '/bin/' .. bin .. ' '
        if cfg.lintCommand:sub(1, #want) ~= want then
          error(string.format('%s: lintCommand %q does not start with %q', preset, cfg.lintCommand, want))
        end
      end
    end)
  end)
end)
