--
-- client.lua -- UDP client
--

local sdl=require("sdl")
local net=sdl.net

-- Init
net.init()

-- "connect" to host and send hello
local addr = net.resolveHost("localhost", 9898)
local s,err = net.openUdp(0)

-- Send "Hello"
local ret, err = s:send("Hello", addr)

