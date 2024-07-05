--Lulua Examples
--[[This file is part of the Lulua lua distro,
	licensed under the MIT License (see the COPYRIGHT file).]]
if love~=nil then--[[A love2d example
	Run with love2d:
		love .
	To run tests, run as:
		love . LOVE2D -t
	The debugger won't work if the cwd is not the base dir.
	]]
	require("init")--You must get the batteries!
	--Now we have the batteries included!
	nfs=import("nativefs")--remove file restrictions!
	NAME="Lulua example"
	DEBUG=false

	function rgb(r,g,b) return {r/255,g/255,b/255};end
	black		 =rgb(  0,  0,  0)
	deep_sky_blue=rgb(  0,191,255)

	function love.conf(t)
		t.console = true
	 end
	function love.mousepressed()
		love.event.quit();
	 end
	function love.keypressed(key)
		if key == "escape" then love.event.quit();return;end
	 end
	function love.load(argv)
		local args=List(argv):slice(1)--command line args
		if args:has('-d','--debug') then DEBUG=true;end
		print("DEBUG: %s" % str(DEBUG))
		love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
		love.keyboard.setKeyRepeat=false
		love.window.setTitle(NAME)
		love.graphics.setBackgroundColor(black)
		love.graphics.setNewFont(48)
		love.window.setMode(1024,768,{resizable=false,vsync=0})
	 end
	function love.draw()
		love.graphics.clear(deep_sky_blue)
		love.graphics.print("Click to exit!")
	 end

else--[[Use the lulua lua interpreter:]]
	linenoise=import("linenoise")
	msg=[[Lulua example program.
	Enter quit or exit to quit or exit.
	]]
	print(msg)
	prompt=linenoise.linenoise
	PS1="cmd: "
	line,err=prompt(PS1)
	while true do
		if line=="quit" or line=="exit" then os.exit();end
		line,err=prompt(PS1)
	 end
end--lulua
