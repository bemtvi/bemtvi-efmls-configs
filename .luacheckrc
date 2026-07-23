-- nxvim runs a vendored PUC Lua 5.4 backend (not LuaJIT) and injects the `nx` and
-- `vim` globals into every plugin chunk.
std = 'lua54'
read_globals = { 'vim', 'nx' }
-- The linter/formatter presets embed long shell command strings as data; a hard
-- column limit isn't meaningful for them.
max_line_length = false
