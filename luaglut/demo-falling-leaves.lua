#!/usr/bin/env lulua
--[[Falling leaves or snowflakes.

	VV: an example program for lulua and luaglut.
	]]
require 'luagl'
require 'luaglut'
require 'memarray'

quit = false
fps  = 30
msec = 1000 / fps

leaves = {}
num_leaves=20

--Initialize and prime the random number generator:
math.randomseed(os.time())
math.random(); math.random(); math.random()

function byte(n)--convert n to a byte-sized number.
	local doc=[[Convert n to a byte.
		byte(n)-->byte

		n can be a string, a char, or a number.
		n must be convertible to an int.
		n must be in range [0..255], else an assertion fails.

		The luaglut memarray module needs to be fed bytes.
		]]
	n=int(n)
	assert(0<=n and n<=255,"byte: arg must be in range [0..255].")
	n=string.char(n)
	n=string.byte(n,1)
	return n
 end

Leaf=function(x,y)--Leaf class
	local self={}
	self.init  =function(self,x,y)
		self.x = x
		self.y = y
		self.rotation = math.random() * 360
		
		-- More controlled randomness
		self.rotation_speed = rotation_speed or (math.random() * 2 - 1) * 3
		self.fall_speed = fall_speed or (math.random() * 0.9 + 0.2)
		self.scale = math.random() * 0.3 + 0.2
		
		-- Add wind-like oscillation
		self.wind_amplitude = math.random() * 0.01  -- Small horizontal movement
		self.wind_frequency = math.random() * 0.1  -- Randomize wind frequency
		self.wind_phase = math.random() * math.pi * 2  -- Random starting phase

		return self
	 end
	self.update=function(self,dt)
		-- Rotation
		self.rotation = (self.rotation + self.rotation_speed * dt * 30) % 360
		-- Falling
		self.y = self.y - self.fall_speed * dt
		-- Wind-like horizontal movement
		self.x = self.x + self.wind_amplitude * 
				 math.sin(self.wind_frequency * glutGet(GLUT_ELAPSED_TIME) * 0.01 + self.wind_phase)
		
		-- Reset leaf
		if self.y < -1 then
			self.y = 1.2
			self.x = math.random() * 2 - 1
			-- Optionally reset wind parameters:
			self.wind_amplitude = math.random() * 0.01  -- Small horizontal movement
			self.wind_frequency = math.random() * 0.1  -- Randomize wind frequency
			self.wind_phase = math.random() * math.pi * 2  -- Random starting phase
		 end
	 end
	self:init(x,y)
	return self
 end

newhandle=(function()--get a new int suitable for a handle.
	local i=1234 --it seems that it can be any int.
	return function()
		i=i+1
		return i
	 end
 end)()

TEXTURES={}
_TEXTURES=0--index for TEXTURES
TEXTURES_NEXT=function()--Get circular index of next texture:
	_TEXTURES=circle_back(_TEXTURES,#TEXTURES)
	return TEXTURES[_TEXTURES]
 end
function _load_texture_p3(fname)--p3 (text) format ppm
	--[[This doesn't follow ppm specs, but it reads *my*
		files. That is good enough for now.
		ppm spec says that commented lines are valid.
		but that is too bad because I don't handle them.
		If you use them, the program will crash.

		When you want to do this right, see:
			https://netpbm.sourceforge.net/doc/ppm.html
		]]
	local f, width, height, depth, r,g,b,a

	f = assert(io.open(fname, 'r'))
	assert(f:read('*l') == 'P3')
	width = f:read('*n')
	height= f:read('*n')
	_____ = f:read('*l')--consume a newline.
	depth = f:read('*l')--assumed to be 255.
	assert(depth == '255','Use a ppm file with a bit depth of 255.')--ensured to be 255 or else!

	local arraylength=width * height * 4
	local ppm = memarray('uchar', arraylength)

	local i=0--memarray index: starts at zero.
	while 1 do
		r = f:read('*n')
		g = f:read('*n')
		b = f:read('*n')

		if  not r or not g or not b then
			break
		 end

		if i>=arraylength then
			break
		 end

		--Generate alpha channel value based on MAGENTA pixels:
		a=255
		if int(r)==255 and int(g)==0 and int(b)==255 then
			a=0
		end

		r=byte(r)
		g=byte(g)
		b=byte(b)
		a=byte(a)

		ppm[i+0]=r
		ppm[i+1]=g
		ppm[i+2]=b
		ppm[i+3]=a
		i=i+4
	end
	f:close()
	return ppm, width, height
 end
function loadtexture(TEXTURES,fname)
	local ss={}
	ss.pixels,ss.width,ss.height=_load_texture_p3(fname)
	ss.handle=newhandle()
	ss.fname=fname
	push(TEXTURES,ss)
	return TEXTURES
 end

function init_leaves()
	for i = 1, num_leaves do
		local x = math.random() * 2 - 1  -- Random x between -1 and 1
		local y = math.random() * 2 - 1  -- Random y between -1 and 1
		table.insert(leaves,Leaf(x,y))
	 end
 end

--glut callbacks:
function resize_func(w, h)
	local ratio = w / h
	glViewport(0, 0, w,h);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
 
	-- Set the projection based on the aspect ratio
	if (w >= h) then
		gluOrtho2D(-1 * ratio, 1 * ratio, -1, 1);
	else
		gluOrtho2D(-1, 1, -1 / ratio, 1 / ratio);
	 end
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
 end
function display_func()
	if quit then return  end

	-- local elapsed_time = glutGet(GLUT_ELAPSED_TIME) - start_time

	glClear(GL_COLOR_BUFFER_BIT)

	glMatrixMode(GL_MODELVIEW)
	glLoadIdentity()

	glEnable(GL_BLEND)
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

	-- Update and draw leaves
	local dt = 1/fps  -- Fixed time step

	for _, leaf in ipairs(leaves) do
		leaf:update(dt)
		
		glPushMatrix()
		glTranslated(leaf.x, leaf.y, 0) 
		glRotated(leaf.rotation, 0, 0, 1)
		glScaled(leaf.scale, leaf.scale, 1)
		
		-- Draw leaf as a textured quad
		glBegin(GL_QUADS)
		glTexCoord2d(0, 0); glVertex2d(-0.1, -0.1)
		glTexCoord2d(1, 0); glVertex2d(0.1, -0.1)
		glTexCoord2d(1, 1); glVertex2d(0.1, 0.1)
		glTexCoord2d(0, 1); glVertex2d(-0.1, 0.1)
		glEnd()
		
		glPopMatrix()
	 end

	glutSwapBuffers()
 end
function keyboard_func(key, x, y)
	if key == 32 then--space bar
		--change the texture
		local texture=TEXTURES_NEXT()
		print("Changed texture to "..texture.fname)
		glBindTexture(GL_TEXTURE_2D, texture.handle );
		glEnable(GL_TEXTURE_2D)
	 end
	if key == 27 then  -- ESC key
		quit = true
		glutDestroyWindow(window)
		os.exit(0)
	end
 end
function timer_func()
   if not quit then
	  glutPostRedisplay()
	  glutTimerFunc(msec, timer_func, 0)
	end
 end

function main(argv)
	init_leaves()

	-- GLUT initialization
	glutInit()
	glutInitDisplayMode(GLUT_DOUBLE+GLUT_RGB+GLUT_ALPHA)
	glutInitWindowSize(1024, 768)
	window = glutCreateWindow("Falling Leaves Demo")

	-- Set up textures:
	TEXTURES=loadtexture(TEXTURES,"snowflake.ppm")
	TEXTURES=loadtexture(TEXTURES,"leaf.ppm")--last texture loaded will be displayed.
	for k,v in ipairs(TEXTURES) do--make the textures known to opengl:
		local texture=TEXTURES[k]
		glBindTexture  (GL_TEXTURE_2D, texture.handle);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP)
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP)
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
		glTexImage2D   (GL_TEXTURE_2D, 0, 4, texture.width, texture.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, texture.pixels:ptr())
	 end
	glEnable(GL_TEXTURE_2D)

	-- Set up GLUT callbacks:
	glutDisplayFunc(display_func)
	glutReshapeFunc(resize_func)
	glutKeyboardFunc(keyboard_func)
	glutTimerFunc(msec, timer_func, 0)

	print("Press spacebar to change texture image.")
	print("Press escape to quit.")

	-- Run it:
	glClearColor(0.7, 0.7, 1.0, 1.0)-- blueish background
	glutMainLoop()
 end
main(arg)

