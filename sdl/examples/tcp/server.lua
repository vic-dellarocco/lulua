--
-- server.lua -- echo server using SDL_net
--

local sdl=require("sdl")
local net=sdl.net
sdl.init()
net.init()

-- Bind a socket
local addr = net.resolveHost(nil, 5959)
local s,err= net.openTcp(addr)

if s==nil then
	print("Err: "..err.."\n")
	os.exit(1)
 end

-- Create a set
local set = net.set(32)

-- Add the socket for accepting clients
set:add(s)

-- Store all clients too
local clients = { }

while true do
	local n = set:checkSockets(-1)

	if n > 0 then
		if s:ready() then
			local c = s:accept()
			if c then
				print("New client")
				table.insert(clients, c)
				set:add(c)
			end
		else
			for i, c in ipairs(clients) do
				if c:ready() then
					local value, n = c:recv(128)
	
					if not value then
						print("Client disconnected")
						set:del(c)
						table.remove(clients, i)
					else
						print(value)
					end
				end
			end
		end
	end
end

-- Close everything
net.quit()
