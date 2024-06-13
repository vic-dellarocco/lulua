--
-- client.lua -- send "Hello" to a server using SDL_net
--

local sdl=require("sdl")
local net=sdl.net

-- Init net
net.init()

-- Create and connect
local addr = net.resolveHost("127.0.0.1", 5959)
local s,err = net.openTcp(addr)

if s==nil then
	print("Err: "..err.."\n")
	os.exit(1)
 end

if s then
s:send("Hello")
end



net.quit()
