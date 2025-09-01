--
-- audio.lua -- testing the SDL audio API
--

dir=package.base.."sdl/examples/audio/"

local SDL	= require "sdl"

-- Init SDL
SDL.init {
	SDL.flags.Audio
}

-- Channel for data and the callback
local channel	= SDL.getChannel "Audio"

-- Prepare the audio spec we want
local spec	= {
	callback	= dir.."audio-processor.lua",
	allowchanges	= true,
	frequency	= 44100,
	format		= SDL.audioFormat.S16,
	samples		= 1024,
	channels	= 2
}

local wav, err = SDL.loadWAV(dir.."gun.wav")
if not wav then
	error(err)
end

-- Pass the wav file to the audio-processor
channel:push(wav)

local dev, err = SDL.openAudioDevice(spec)
if not dev then
	error(err)
end

dev:pause(false)
SDL.delay(5000)
