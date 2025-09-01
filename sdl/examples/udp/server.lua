--
-- server.lua -- UDP server
--

local sdl=require("sdl")
local net=sdl.net

-- Init
net.init()

-- Create a server socket
local s,err = net.openUdp(9898)

while true do
	local v,num,err = s:recv(32)
	print(err)

	if v then
		print(v)
	end
end
