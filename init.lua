--[[This file is autorun by lulua lua.
	Change it however you want.
	The file "init.lua" must exist. It can be blank.
 ]]

--Turn off jit if using luajit:
-- if jit then jit.off() end

if love~=nil then
	io.stderr:write("init.lua: LOVE2D detected.\n")
	package.base=love.filesystem.getSource().."/"
 end

local file=io.open(package.base.."VERSION","r")
LULUA_VERSION=file:read("*l")
file:close()
file=nil
io.stderr:write("Lulua Lua Distro "..LULUA_VERSION.."\n")

--[[set up path for modules that don't have an init.lua file:]]
package.path =package.path ..package.base.."gambiarra/src/?.lua;" --test()
package.path =package.path ..package.base.."lunit/lua/?.lua;"--lunit,lunitx
package.cpath=package.cpath..package.base.."linenoise/?.so;"--linenoise
package.cpath=package.cpath..package.base.."luaglut/?.so;" --luaglut,luagl,memarray
package.cpath=package.cpath..package.base.."int64/?.so;" --int64
package.path =package.path ..package.base.."lpeg/?.lua;"  --re
package.cpath=package.cpath..package.base.."lpeg/?.so;" --lpeg

package.cpath=package.cpath..package.base.."signal/?.so;"
package.cpath=package.cpath..package.base.."curses/?.so;"

--[[Penlight defaults to importing submodules into the global namespace.
	penlight's init.lua has been modified to import into namespace "penlight".]]
require("penlight")
-- pl=penlight

require("stdlib")

--Luajit will have bit already defined:
if bit==nil then bit=require("bit") end
assert(bit~=nil, "Unable to load bit module.")

--Add current working dir to path if installing as system lua:
-- local pwd = os.getenv("PWD")
-- package.path  = package.path..   pwd.. "/?.lua;"
-- package.path  = package.path..   pwd.. "/?/init.lua;"
-- package.cpath = package.cpath..  pwd.. "/?.so;"

--info:
-- io.stderr:write("package.base=" .."\""..package.base .."\"".."\n")
-- io.stderr:write("package.path=" .."\""..package.path .."\"".."\n")
-- io.stderr:write("package.cpath=".."\""..package.cpath.."\"".."\n")
