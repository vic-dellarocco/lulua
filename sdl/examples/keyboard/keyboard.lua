--
-- keyboard.lua -- process keyboard states
--

local SDL	= require "sdl"

SDL.init {
	SDL.flags.Video
}

SDL.createWindow {
	title	= "Keyboard",
	width	= 256,
	height	= 256
}

local keys = SDL.getKeyboardState()

while true do
	SDL.pumpEvents()

	if keys[SDL.scancode.Return] then
		print("Return pressed")
	end
	if keys[SDL.scancode.Escape] then
		print("Exiting!")
		break
	end

	SDL.delay(100)
end
