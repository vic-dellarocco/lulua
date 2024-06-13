--VV:
penlight={}
package.path=package.path..package.base.."penlight/lua/?.lua;"
dofile(package.base.."penlight/lua/pl/init.lua")--modified to import into "penlight"
local ok=false
for k,v in pairs(penlight) do ok=true;end--default import should have loaded util at least.
if ok==false then io.stderr:write("Failed to import penlight.\n");os.exit(1);end
