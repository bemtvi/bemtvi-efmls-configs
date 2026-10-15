-- Metadata
-- languages: rust
-- url: https://github.com/rust-lang/rustfmt

local fs = require('efmls-configs.fs')

return btv.async(function()
  local formatter = btv.await(fs.executable('rustfmt'))
  local command = string.format('%s --emit=stdout', formatter)

  -- Pass the crate's Rust edition to rustfmt. Read Cargo.toml for real over btv.fs,
  -- walking up from the cwd until it is found.
  local dir = btv.cwd()
  while dir and dir ~= '' do
    local cargo = dir .. '/Cargo.toml'
    if btv.await(btv.fs.exists(cargo)) then
      local ok, contents = pcall(function()
        return btv.await(btv.fs.read_text(cargo))
      end)
      if ok and contents then
        local edition = contents:match('edition%s*=%s*"(%d+)"')
        if edition then
          command = string.format('%s --edition=%s', command, edition)
        end
      end
      break
    end
    local parent = btv.fname.modify(dir, ':h')
    if parent == dir then
      break
    end
    dir = parent
  end

  return {
    formatCommand = command,
    formatStdin = true,
  }
end)
