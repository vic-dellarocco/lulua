--
-- paths.lua -- show standard directories
--

local SDL = require "sdl"

print(string.format("Base directory: %s", SDL.getBasePath()))
print(string.format("Preference directory: %s", SDL.getPrefPath("Lua-SDL2", "Testing")))
