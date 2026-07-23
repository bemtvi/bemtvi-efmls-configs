-- examples/sample.lua — a deliberately messy, slightly-buggy Lua file.
--
-- With efm-langserver + luacheck + stylua installed and this repo's examples/init.lua
-- loaded (see its header for how to run):
--
--   * DIAGNOSTICS — luacheck flags the unused variable and the undefined global
--     below (open the file and look at the gutter / :EfmlsHealth for tool status).
--
--   * FORMATTING — press <leader>lf and stylua reflows the ragged spacing and
--     indentation into canonical Lua style.

local    greeting     =    'hello'
local unused_local = 42

local function shout(   name )
        return   greeting .. ' ' ..    string.upper(name) .. '!'
end

-- `undefinedGlobalHelper` is never defined — luacheck reports it.
print(shout('world'), undefinedGlobalHelper)
