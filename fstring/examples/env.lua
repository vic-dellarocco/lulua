-- local F = require("F")

local assert = assert
local env = {x = "foo",F=F}
setfenv(1, env)

function gee()
   assert("foo" == x)
   assert("foo" == F'{x}')
end

gee()
