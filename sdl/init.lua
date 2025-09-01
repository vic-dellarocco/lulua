
local m=assert(package.loadlib(package.base.."sdl/SDL.so","luaopen_SDL"))()
m.image=assert(package.loadlib(package.base.."sdl/image.so","luaopen_SDL_image"))()
m.mixer=assert(package.loadlib(package.base.."sdl/mixer.so","luaopen_SDL_mixer"))()
m.ttf  =assert(package.loadlib(package.base.."sdl/ttf.so","luaopen_SDL_ttf"))()
m.net  =assert(package.loadlib(package.base.."sdl/net.so","luaopen_SDL_net"))()
return m
