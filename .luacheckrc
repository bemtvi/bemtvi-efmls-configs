-- bemtvi runs a vendored PUC Lua 5.4 backend (not LuaJIT), and plugin code targets
-- its `btv` global only. `vim` is left undeclared on purpose so a stray `vim.*` call
-- is flagged. selene.toml is the repo's lint gate; this file is what the examples/
-- luacheck demo (and anyone running luacheck here) picks up.
std = 'lua54'
read_globals = {
  btv = {
    other_fields = true,
    -- The variable/option tables are written by assignment (`btv.g.mapleader = ' '`).
    fields = {
      g = { read_only = false, other_fields = true },
      o = { read_only = false, other_fields = true },
      bo = { read_only = false, other_fields = true },
      wo = { read_only = false, other_fields = true },
    },
  },
}
-- The linter/formatter presets embed long shell command strings as data; a hard
-- column limit isn't meaningful for them.
max_line_length = false
