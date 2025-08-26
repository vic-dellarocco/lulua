--[[A standard library for the Lulua Lua Distro]]
--[[This file is part of the Lulua lua distro,
	licensed under the MIT License (see the COPYRIGHT file).]]
--[[Setup]]
	_GLOBALS={unpack(_G)}--compare _G to _GLOBALS later to see what was added.
	_GLOBALS._VERSION=false--set this to a non-nil value so that the comparision check works later.
	_GLOBALS._G=false      --set this to a non-nil value so that the comparision check works later.
	--[[Save original global functions that are redefined later]]
	_TYPE=type
	_SORT=table.sort
	_PRINT=print
	--[[]]
	MAIN=function()--[[Check if this program is called as a script.]]
		local doc=[[Returns true if this program is called as a script.
			Usage:
				if MAIN() then
					do_whatever()
				 end

			Use this just like the pythonic: if __NAME__=="__MAIN__"
			]]
		--[[if imported, this function ends up being 4 levels
			deep!,so check  for the top level at 5.]]
		if pcall(debug.getlocal,5,1) then--level:5,index:1
			return false--(imported or "required")
		 else
			return true--MAIN
		 end
	 end
--[[Import]]
	function import(module)--load a module
		local doc=[[Load a module.
			import(module)-->mod

			Load a module like require(),except:
			.lua file extension is ignored.
			Use '/' or '.' as module delimiter.
			The syntax is more permissive than require.
			imports are relative to package.base

			Ex:
				mymodule=import("foo/bar/mymodule.lua")
				foo=import "foo_module"
				foo=import("foo_module")
				foo=import{"foo_module"}
				foo=import({"foo_module"})

			Only loads one module.
			]]
		if type(module)=="table" or type(module)=="List" then module=module[1];end
		module=module:gsub("%.lua", "")--remove .lua extension
		module=module:gsub('/','.') --slash to dot
		return require(module)
	 end
	function reload(module)--always load module
		local doc=[[Always load a module.
			foo=reload("foo_module")

			It doesn't have to reload, you can use it the first time too.
			Uses same syntax as import.
			]]
		package.loaded[module]=nil--will force reload.
		return import(module)
	 end
	trace=import("debug/debugger.lua");trace.auto_where=10
	F=import("fstring")--f strings (like python)
	f=F--for those who hate pressing the shift key.
	if not jit then--use lua bitops:
		bit=import("bit")
	 end
--[[Copy]]
	--[[NONE of these can copy closures.]]
	function copy(src) --Shallow copy of array.
		local doc=[[Shallow copy of array.
			copy(src)-->srccopy

			Ex:
				foo=copy(bar)
				bar=copy({11,22,33})--perfect for numbers and strings
				baz=copy(00,bar,44)-->{00,{11,22,33},44}--shallow copy
				bar[2]=88--baz is now {00,{11,88,33},44}--beware.
			]]
		return {unpack(src)}
	 end
	function deepcopy(src,_seen)
		local doc=[[Deep copy of table.
			deepcopy(src)-->acopy

			Will copy metatables.
			Doesn't capture upvalues. You can't copy closures with this.

			Ex:
				dest=deepcopy(src)
			]]
		_seen=_seen or {}
		if _TYPE(src)~="table" then return src end
		if _seen[src] then return _seen[src] end
		local ss={}
		_seen[src]=ss
		for k,v in next,src,nil do
			ss[deepcopy(k,_seen)]=deepcopy(v,_seen)
		end
		setmetatable(ss,deepcopy(getmetatable(src),_seen))
		return ss
	 end
	function merge(src,dst)--Merge copy
		--[[
			]]
		local doc=[[Merge src to dst, will overwrite keys and values.
			merge(src,dst)
			dst=merge(src,dst)--same effect as the first form.
							  --I just like to return the results.

			Result is that dst is updated with k,v from src.

			If you don't want to update a table, then try this:
				dst=merge(src)--shallow copy

			Don't:
				merge(src,foo.dst)--no result is realized.

			Useless:
				merge(src)--no result is realized.
			]]
		local ss=dst or {}
		for k,v in pairs(src) do
			-- dbg{"merge:%s=%s"%{k,v},s="copy"}
			ss[k]=v
		 end
		return ss
	 end--merge()
	function clone(tbl)     --Shallow copy of numeric keys.
		local doc=[[Shallow copy of numeric keys.
			clone(src)-->tbl
			]]
		local t={}
		for k,v in pairs(tbl) do
			if type(k)=="number" then
				t[k]=v
			 end
		 end
		return t
	 end
	function cloneiter(iter)--Shallow copy of numeric keys from iterator.
		local doc=[[Shallow copy of numeric keys from iterator.
			cloneiter(iter)-->tbl

			Expects a {k,v} type of iter such as ipairs.
			]]
		local t={}
		for k,v in iter do
			if type(k)=="number" then
				t[k]=v
			 end
		 end
		return t
	 end
--[[Math]]
	--Why  2^53-1 and not  2^53? Because  2^53 and  2^53+1 are indistinguishable.
	MAXINT= 9007199254740991 --Assumes 64 bit IEEE 794, int( 2^53-1)
	--Why -2^53+1 and not -2^53? Because -2^53 and -2^53-1 are indistinguishable.
	MININT=-9007199254740991 --Assumes 64 bit IEEE 794, int(-2^53+1)
	--These were added to lua in version 5.3:
	math.maxinteger=MAXINT
	math.mininteger=MININT
	int   =function(n)
		local doc=[[Convert n into an int by truncation.
			int(n)-->i

			Works on strings too.

			Ex: i=int(n)
				i=int(3.14)-->3.0
				i=int("2.7")-->2.0

			Can fail with an assertion error.
			]]
		if n==nil then return 0.0 end
		if type(n)=="number" then return math.floor(n) end
		if type(n)=="string" then return math.floor(tonumber(n)) end
		assert(false,"unable to make int")
	 end
	float =function(n)
		local doc=[[Convert n into a float.
			float(n)--number

			Works on strings too.

			Ex:
				i=float()-->0
				i=float(3.14)-->3.14
				i=float("2.7")-->2.7

			Can fail with an assertion error.
			]]
		if n==nil then return 0.0 end
		if type(n)=="number" then return n end
		if type(n)=="string" then return tonumber(n) end
		assert(false,"unable to make float")
	 end
	flr   =math.floor
	abs   =math.abs
	rand  =math.random
	sqrt  =math.sqrt
	clamp =function(n,lower,upper)
		local doc=[[Return a number in the range [lower..upper]
			clamp(n,lower,upper)

			Ex: clamp(2,5,10) --> 5
				clamp(20,5,10)-->10
				clamp(7,5,10) --> 7

			Will swap lower,upper if upper < lower.
			]]
		if upper < lower then
			lower,upper=upper,lower
		 end
		return math.max(lower,math.min(upper,n))
	 end
	intmod=function(x,m)--moduluo: x mod m, returns an int
		local doc=[[Moduluo: x mod m, returns an int.
			intmod(x,m)

			Because mod is defined as this in lua:
			a % b == a - math.floor(a/b)*b
			if a is not an int, the result is not an int!

			So use INTMOD to get an int result.

			Will return nan values.
			]]
		x=int(x)
		m=int(m)
		return x-(m*int(x/m))
	 end
	round =function(n,_decimals)--round n to _decimals decimal places or nearest int.
		local doc=[[Round n to _dp decimal places or nearest int.
			round(3.14)  -->3

			_decimals arg is optional.
			Ex:
				round(3.14,1)-->3.1
			]]
		local dec=10^(_decimals or 0)
		if n<0 then
			return math.ceil( n*dec-0.5)/dec
		else
			return math.floor(n*dec+0.5)/dec
		end
	 end
--[[Datatypes]]
	def 	 =function(f)--just syntax sugar for defining something.
		local doc=[[Syntax sugar for defining something.
			def(f)-->f

			It just returns its arg.
			It allows alternate syntax for define and call:
				foo=(foo definition...in here)()
				foo=def(foo definition...in here)()

			I use this to define functions that return functions:

				Foo=def(...)()
				Foo()

			Instead of:

				Foo=function...end
				Foo()()
			]]
		return f
	 end
	settype  =def(function()--Yes you can add new types.
		local _type=type
		local ss=function(tbl,t)
			local doc=[[Yes you can add new types.
				settype(obj,typename)

				Uses the secret __type field that Lua5.1 wasn't using.
				Uses the metatable.
				]]
			assert(_type(tbl)=="table")
			local mt=getmetatable(tbl) or {}
			mt.__type=t
			setmetatable(tbl,mt)
			return tbl
		 end
		return ss
	 end)()
	type 	 =def(function()--get type name including your custom types.
		local _type=type--closure
		local t=function(obj)
			local doc=[[Return the type of an object.

				Ex:
					settype(myobj,"myobj_type")
					type(myobj)-->"myobj_type"
					type("hello")-->"string" --works on build in types too.

				Yes you can add new types.
				Stores the type name as a string in the __type field that
				Lua5.1 wasn't using.
				]]
			local ss=_type(obj)
			if ss=="table" then
				local mt=getmetatable(obj) or {}
				return mt.__type or ss
			 else
				return ss
			 end
		 end
		return t
	 end)()--[[type]]
	method 	 =function(name,obj,...)--Call method name on object.
		local doc=[[Call method name on object.
			method(method_name,object,...)

			Suppose:
				foo=Foo()

			Same as foo:dofoo() or foo.dofoo(foo):
				method("dofoo",foo)

			Same as foo:dofoo(arg1,arg2):
				method("dofoo",foo,arg1,arg2)
			]]
		local arrgs={...}
		return obj[name](obj,unpack(arrgs))
	 end
	methodist=function(obj,ftab)--make functions in ftab methods of obj.
		local doc=[[Make functions from the table ftab methods of obj.
			methodist(obj,ftab)

			Uses the object's metatable.
			]]
		local mt=getmetatable(obj) or {}
		local index={}
		if ftab==nil then--no functions to methodize.
			return obj
		 end
		for k,v in pairs(ftab) do --only methodize functions.
			if type(v)=="function" then
				index[k]=v
			 end
		 end
		mt.__index=merge(index,mt.__index)--update.
		setmetatable(obj,mt)
		return obj
	 end
	Enum 	 =function(names,...)--Make an Enumeration.
		local doc=[[Make an Enumeration.

			myenum=Enum(names...)
			myenum=Enum{names...}

			Pass in a list of names (strings) and get back
			something like this: { "name1"=1,"name2"=2, etc}

			Don't try to add items later, it is designed to be
			made all at once. So get your list of names together
			and then make your enumeration.
			]]
		--[[pass a list of strings as args
			or a {list} of strings
		]]
		local args={...}
		local e={}

		if len(args)<1 then
			return {}
		 end

		if type(names)=="string" then
			e[names]=1
			for i=1,#args do
				e[args[i]]=i+1
			 end
		 else--names must be a list of strings
			for i=1,#names do
				e[names[i]]=i
			 end
		 end
		return e
	 end
--[[Structures]]
	Array=def(function(...)--A zero-based array type for numbers
		local doc=[[A zero-based array type for numbers
			myarray=Array(size)
			myarray=Array(size,default)
			myarray=Array{size,default}
			myarray=Array{size=NUM}
			myarray=Array{size,default=VAL}
			myarray=Array{size=NUM,default=VAL}

			default is optional, it is 0 if unset.
			You can't use the brackets [] for anything but numbers.
			Number indices will be truncated to ints
			Ex: myarray[3.14]-->myarray[3.0]

			myarray=Array(5,1)-->[1,1,1,1,1]

			methods:
				len:  return the number of elements in the array.
				push: add an item to the end of the array. This
					  grows the array.
				iter: function that returns a zero-aware iterator.

			How to loop through the array:
				for i,v in myarray:iter() do
					myarray[i]=v+1
				 end
			]]
		--{size,default}
		--[[
			You can't use the brackets [] for anything but numbers.
			Number indices will be truncated to ints
			]]
		local self={}
		local args={...}
		if len(args)<1  then args[1]=0;end
		if len(args)==1 and (type(args[1])=="table" or type(args[1])=="List") then
			args=args[1]
		 end
		local size    = args[1] or args.size    or args.s or 0
		local default = args[2] or args.default or 0
		settype(self,"Array")
		self._array={}
		local default_val
		for i=1,size do--initialize
			if type(default)=="function" then
				default_val=default()
			else
				default_val=default
			 end
			self._array[i]=default_val
		 end
		default_val=nil
		self.len=function(self)
			return #self._array
		 end
		self.size=self.len
		self.push=function(self,v)
			push(self._array,v)
		 end
		self.iter=function(self)--zero aware array iterator
			local n=-1
			local s=self:len()
			return function()
				n=n+1
				if n<s then return n,self[n] end
			 end
		 end
		local mt={
			__index=function(self,k)
				-- print("key type:"..type(k))
				if type(k)=='number' then
					return self._array[flr(k)+1]
				 elseif k==nil then
					assert(false,'index key must be a number')
					return nil
				 else
					-- print('rawGet')
					return rawget(self,k)
				 end
			 end
			,__newindex=function(self,k,v)
				if type(k)=='number' then
					self._array[flr(k)+1]=v
				 elseif k==nil then
					return nil
				 else
					rawset(self,k,v)
				 end
			 end
			--[[Does not work in luaJIT
			,__len=function(self)
				return rawlen(self._array)
			 end
			--]]
		 }
		setmetatable(self,mt)
		return self
	 end)
	Deque=def(function(args)--Fast deque from "Programming in Lua"
		local doc=[[Fast deque from "Programming in Lua"

			d=Deque()     --create an empty deque.
			d=Deque(list) --create from a List or table.

			Methods:
				push(val)
				pop
				bot
				top
				left
				right
				pushleft(val)
				popleft
				iter

			Use the iter function to loop through it:
				for i,v in d:iter() do ...
			]]
		-- [[init=]]function(self,args)
		local self={}
		settype(self,"Deque")
		self.first=0
		self.last=-1
		self.push     =function(self,val)
			local last=self.last+1
			self.last=last
			self[last]=val
			return self
		 end
		self.pop      =function(self)
			local last=self.last
			if self.first > last then
				self.first=0
				self.last=-1
				return nil,self
			 end
			local val=list[last]
			list[last]=nil
			list.last=last-1
			return val,self
		 end
		self.bot      =function(self)
			return self[self.first],self
		 end
		self.top      =function(self)
			return self[self.last],self
		 end
		self.left     =function(self)
			return self[self.first],self
		 end
		self.right    =function(self)
			return self[self.last],self
		 end
		self.pushleft =function(self,val)
			local first=self.first-1
			self.first=first
			self[first]=val
			return self
		 end
		self.popleft  =function(self)
			local first=self.first
			if first > self.last then
				self.first=0
				self.last=-1
				return nil,self
			 end
			local val=self[first]
			self[first]=nil
			self.first=first+1
			return val,self
		 end
		self.iter=function(self)--iterator
			local n=self.first-1--n=-1
			local s=self.last--s=self:len()
			return function()
				n=n+1
				if n<=s then return n,self[n] end
			 end
		 end
		--create the deque from the list args: deque(list)
		if type(args)=="table" or type(args)=="List" then
			for i=1,#args do
				self:push(args[i])
			 end
		 else
			--creates empty deque.
			pass()
		 end
		return self
	 end)
	Stack=def(function(args)--A stack
		local doc=[[A stack

			mystack=Stack()

			methods:
				push(val)
				pop
				top
			]]
		--a stack.
		-- [[init=]]function(self,list)
		local self={}
		settype(self,"Stack")
		self._tbl=List() or {}
		self.len =function(self)
			return #self._tbl
		 end
		self.push=function(self,val) self._tbl[#self._tbl+1]=val; return self end
		self.pop =function(self) val=self._tbl[#self._tbl]; self._tbl[#self._tbl]=nil; return val,self; end
		self.top =function(self) return self._tbl[#self._tbl] end
		return self
	 end)--Stack()
--[[Functions]]
	len   =function(tbl)--Get the total number of keys in table.
		local doc=[[Get the total number of keys in table.
			len(tbl)

			len(tbl) counts all keys.
			#tbl only counts consecutive ints starting at 1.
			]]
		local i=0
		for k,v in pairs(tbl) do
			i=i+1
		 end
		return i
	 end
	exec  =function(s)--Execute code.
		local doc=[[Execute code.
			exec(code_string)
			]]
		assert(loadstring(s))()
	 end
	range =function(start,finish)--Inclusive range(2,4)->{2,3,4}. Generates a table.
		local doc=[[Inclusive range
			range(2,4)->{2,3,4}
			]]
		if finish==nil then--range(3)-->{1,2,3}
			finish=start
			start=1
		 end
		local ss={}
		for i=start,finish,1 do
			ss[#ss+1]=i
		 end
		return ss
	 end
	range0=function(start,finish)--Zero based range. open right interval.
		local doc=[[Zero based range. open right interval.
			range0(3)-->{0,1,2}
			]]
		if finish==nil then--range0(3)-->{0,1,2}
			finish=start
			start=0
		 end
		return range(start,finish-1)
	 end
--[[Iterators]]
	function IRANGE(start,finish) --Inclusive range iterator.
		local doc=[[Inclusive range iterator.
			IRANGE(start,finish)

			Ex:
				for i in IRANGE(3) do print(i);end
				--{1,2,3}
				for i in IRANGE(11,15) do print(i);end
				--{11,12,13,14,15}
			]]
		if finish==nil then--irange(3)-->{1,2,3}
			finish=start
			start=1
		 end
		local n=start-1
		local s=finish+1
		return function()
			n=n+1
			if n<s then return n end
		 end
	 end
	 irange=IRANGE--for those who prefer lowercase.
	function IRANGE0(start,finish)--Zero based iterator. open right interval.
		local doc=[[Zero based iterator. open right interval.
			IRANGE0(start,finish)

			Ex:
				for i in IRANGE0(3) do print(i);end
				--{0,1,2}
				for i in IRANGE0(10,15) do print(i);end
				--{10,11,12,13,14}
			]]
		if finish==nil then--irange0(3)-->{0,1,2}
			finish=start
			start=0
		 end
		local n=start-1
		local s=finish
		return function()
			n=n+1
			if n<s then return n end
		 end
	 end
	 irange0=IRANGE0--for those who prefer lowercase.
	function IPAIRS(tbl)--Use as a reference of how to make a stateless iterator.
		local doc=[[Pairs iterator.
			IPAIRS(tbl)

			Reference implementation of a stateless iterator.
			This has the same functionality as ipairs()
			]]
		local function _IPAIRS(tbl,i)
			i=i+1
			local v=tbl[i]
			if v~=nil then
				return i,v
			 else
				return nil
			 end
		 end
		return _IPAIRS,tbl,0
	 end
	function IARRAY(tbl)--start at zero. Another way to make an iterator. Uses closures.
		local doc=[[Iterator for arrays, starts at zero.
			IARRAY(tbl)
			Another way to make an iterator. Uses closures.
			]]
		local n=-1
		local s=#tbl+1--+1 because we start at zero
		return function()
			n=n+1
			if n<s then return n,tbl[n] end
		 end
	 end
	function CONCAT(...)
		local doc=[[Concatenation iterator.
			CONCAT(...)
			Pass in one or more lists, it iterates over each.

			Accepts tables as lists or the List() type.

			for v in CONCAT({1},{2,3}) do print(v);end
				--{1,2,3}
			]]
		local tbls={...}
		local cats={}

		-- Yup, it makes another table.
		for i,t in ipairs(tbls) do
			for j,v in ipairs(t) do
				cats[#cats+1]=v
			 end
		 end

		-- Return cats iterator:
		local i=nil
		return function()
			local v
			i,v=next(cats,i)
			if i==nil then
				return nil
			 else
				return i+1,v
			 end
		 end
	 end
	function REVERSE(tbl)--reverse ipairs
		local doc=[[Reverse ipairs iterator
			REVERSE(tbl)
			]]
		local n=#tbl+1
		local s=0
		return function()
			n=n-1
			if n>s then return n,tbl[n] end
		 end
	 end
	function REVERSEARRAY(tbl)--Reverse order iterator for zero-based arrays.
		local doc=[[Reverse order iterator for zero-based arrays.
			REVERSEARRAY(tbl)
			]]
		local n=#tbl+1
		if tbl[0]~=nil then n=n+1;end
		local s=-1
		return function()
			n=n-1
			if n>s then return n,tbl[n] end
		 end
	 end
	function FLATTEN(tbl)--Iterator that flattens a list one level
		local doc=[[Iterator that flattens a list one level
			FLATTEN(tbl)
			]]
		-- Makes an flattened list, then returns an iterator over that.
		local function _flatten(_tbl)--get list flattened one level.
			local ss={}
			for k,v in ipairs(_tbl) do
				if type(v)=="table" or type(v)=="List" then
					for kk,vv in ipairs(v) do
						push(ss,vv)
					 end
				 else
					push(ss,v)
				 end
			 end
			if type(_tbl)=="List" then ss=List(ss) end
			return ss
		 end
		local ss=_flatten(tbl)

		local i=nil
		return function()
			local v
			i,v=next(ss,i)
			if i==nil then
				return nil
			 else
				return i+1,v
			 end
		 end
	 end
	function UNROLL(tbl)--Iterator to completely flatten a list (Lua5.1)
		local doc=[[Iterator to completely flatten a list (Lua5.1)
			UNROLL(tbl)

			Makes an unrolled list, then returns an iterator over that.
			]]
		local function _unroll(_tbl) --get list of all leaf nodes,depth first
			local ss={}
			for k,v in ipairs(_tbl) do
				if type(v)=="table" or type(v)=="List" then
					extend(ss,_unroll(v))
				 else
					push(ss,v)
				 end
			 end
			if type(_tbl)=="List" then ss=List(ss) end
			return ss
		 end
		local ss=_unroll(tbl)

		local n=0
		local s=#ss+1
		if #ss==0 then s=0;end
		return function()
			n=n+1
			if n<s then return n,ss[n] end
		 end
	 end
		-- if false then--UNROLL -- hasn't been tested.
		if jit then--UNROLL
			assert(loadstring([[
			function UNROLL(tbl)
				--iterator to completely flatten a list (luajit)
				--Won't work in Lua5.1 because Lua5.1 doesn't have a goto statement.
				--The benefit of this implementation is that it won't use all of the
				--stack space with recursive calls.
				--
				local n=0
				local p={{0,tbl}}
				return function()
					while true do
						if #p<1 then return nil end
						p[#p][1]=p[#p][1]+1
						if p[#p][1]<=#p[#p][2]
						 and type(p[#p][2][p[#p][1]  ])=="table"
						 or  type(p[#p][2][p[#p][1]  ])=="List"
						 then
							p[#p+1]={0,p[#p][2][p[#p][1] ]}--push
							goto continue
						 end
						if p[#p][1]<=#p[#p][2] then
							n=n+1
							return n,p[#p][2][p[#p][1]  ]
						 else
							p[#p]=nil--pop
						 end
					 ::continue::
					 end--while
				 end
			 end
			]]))()
		 end--jit UNROLL
--[[Table]]
	function push(tbl,val)
		local doc=[[Adds a value to the end of the table.
			push(tbl,val)

			Returns the modified table.
			]]
		tbl[#tbl+1]=val; return tbl; end
	function pushleft(tbl,val)
		local doc=[[Inserts a value at the beginning of the table.
			pushleft(tbl,val)

			Returns the modified table.
			]]
		table.insert(tbl,1,val); return tbl; end
	function pop(tbl)
		local doc=[[Removes and returns the last element of the table.
			pop(tbl)
			]]
		val=tbl[#tbl]; tbl[#tbl]=nil; return val; end
	function popleft(tbl)
		local doc=[[Removes and returns the first element of the table.
			popleft(tbl)
			]]
		return table.remove(tbl,1); end
	function bot(tbl)
		local doc=[[Returns the first element of the table.
			bot(tbl)
			]]
		return tbl[1]; end
	function top(tbl)
		local doc=[[Returns the last element of the table.
			top(tbl)
			]]
		return tbl[#tbl]; end
	function left(tbl)
		local doc=[[Alias for `bot`, returning the first element of the table.
			left(tbl)
			]]
		return bot(tbl); end
	function right(tbl)
		local doc=[[Alias for `top`, returning the last element of the table.
			right(tbl)
			]]
		return top(tbl); end
	function slice(tbl,first,last,step)--pythonic slice
		local doc=[[Performs a Pythonic slice operation on a table.
			slice(tbl,first,last,step)

			Negative values are not supported for
				start (first), stop (last), and step.

			Lua tables start at index 1, and so does this function.

			Ex:
				table.slice({11,22,33},2)  -->{22,33}
				table.slice({11,22,33},2,2)-->{22}

			If the input is of type List, it converts the result
			back to a List object. Otherwise, it returns a table.
			]]
		local ss={}
		for i=first or 1,last or #tbl,step or 1 do
			ss[#ss+1]=tbl[i]
		 end
		if type(tbl)=="List" then
			return List(ss)
		else
			return ss
		end
	 end
	function has(tbl,...)--like python's 'in' operator.
		local doc=[[Check if a table has any item from a list of items.
			has(tbl,...}
			lst:has(...)--as a list method.

			Checks if any value from a variadic argument list is present
			in a table. Similar to Python's in operator usage with lists.
			Returns true if any value from {...} is in tbl, else false.

			Ex:
				has(tbl,'bar')
				has(tbl,'bar','baz')
				has({11,22,33},88,22)-->true because of 22
			]]
		local args={...}
		for k,v in pairs(tbl) do
			for kk,vv in pairs(args) do
				if v==vv then
					return true
				 end
			 end
		 end
		return false
	 end
	function haskey(tbl,...)--like python's 'in' operator, for keys.
		local doc=[[Check if a table has any item from a list of items.
			haskey(tbl,...}
			lst:haskey(...)--as a list method.

			Checks if any value from a variadic argument list is present
			in a table's keys. Similar to Python's in operator usage 
			with lists.

			Returns true if any key from {...} is a key in tbl,
			else false.

			Ex:
				haskey(tbl,'bar')
				haskey(tbl,'bar','baz')
				haskey({11,22,33},88,2)-->true because key 2 exists.
			]]
		local arrgs={...}
		for k,v in pairs(tbl) do
			for kk,vv in pairs(arrgs) do
				if k==vv then
					return true
				 end
			 end
		 end
		return false
	 end
	function extend(tbl,src)--Extends a table with elements from another table.
		local doc=[[Extends a table with elements from another table.
			extend(tbl,src)

			Copies items from src to tbl, preserving order.

			Can be used as a List method.
			]]
		for k,v in ipairs(src) do
			push(tbl,v)
		 end
		return tbl
	 end
	function coalesce(tbl,src)--Condenses sparse bucket arrays by merging them.
		local doc=[[Condenses sparse bucket arrays by merging them.
			coalesce(tbl,src)-->tbl
			coalesce(src)-->tbl

			Preserves the values but not the keys.

			Order of elements may not be preserved.
			Dupplicate elements are preserved.

			Only considers numerical keys, which may be negative.

			Ex:
				cc=coalesce({},{[-1]=22,[444]=321})
					-->{22,321}

			Modifies tbl, and also returns it.

			Can be used as a method of the List type:
				cc=List({[-1]=22,[444]=321})
				cc:coalesce()
			]]

		--allow one arg:
		if src==nil and tbl~=nil then
			src=tbl
			tbl={}
		 end

		for k,v in pairs(src) do
			if type(k)=="number" then
				push(tbl,v)
			 end
		 end
		return tbl
	 end
	function flatten(tbl)--Flattens a table or List by one level.
		local doc=[[Flattens a table or List by one level.
			flatten(tbl)-->tbl

			Ex:
				flatten({1,{2,3},4})  -->{1,2,3,4}
				flatten({1,{2,{3}},4})-->{1,2,{3},4}

			Preserves the order of elements.
			]]
		local ss={}
		for k,v in ipairs(tbl) do
			if type(v)=="table" or type(v)=="List" then
				for kk,vv in ipairs(v) do
					push(ss,vv)
				 end
			 else
				push(ss,v)
			 end
		 end
		if type(tbl)=="List" then ss=List(ss) end
		return ss
	 end
	function unroll(tbl) --get list of all leaf nodes,depth first
		local doc=[[Recursively unrolls a table or List.
			unroll(tbl)
			Returns a table or List of all leaf nodes, depth-first.
			]]
		local ss={}
		for k,v in ipairs(tbl) do
			if type(v)=="table" or type(v)=="List" then
				extend(ss,unroll(v))
			 else
				push(ss,v)
			 end
		 end
		if type(tbl)=="List" then ss=List(ss) end
		return ss
	 end
	--[[Add table ops to the table table:
		Note, that these are not made methods because then the
		function names would conflict with the names that you
		can store in a table when using it as a dict. The
		List() type, defined below, has all the table functions
		as methods, for your convenience.
		]]
		table.push    =push
		table.pushleft=pushleft
		table.pop     =pop
		table.popleft =popleft
		table.top     =top
		table.slice   =slice
		table.has     =has
		table.haskey  =haskey
		table.extend  =extend
		table.coalesce=coalesce
		table.flatten =flatten
		table.unroll  =unroll
		table.pack=function(...)
			local ss={...}
			return ss
		 end
		table.unpack=unpack--Lua5.1/5.2/luaJIT compat.
		table.is_empty=function(tbl)--true if table is empty.
			local doc=[[Checks if a given table is empty.
				:is_empty()
				Returns true if the table has no key-value pairs;
				otherwise, returns false.
				]]
			for k,v in pairs(tbl) do
				if k ~= nil then
					return false
				end
			 end
			return true
		 end
		table.is_blank=function(tbl)--true if table is empty or contains only blank strings
			local doc=[[True if a table is empty or only blank strings.
				:is_blank()
				Returns true if the table is empty or all string values
				are blank after trimming whitespace;
				otherwise, returns false.
				]]
			for k,v in pairs(tbl) do
				if type(v)=="string" then
					if string.trimall(v)=="" then
						pass()
					 else
						return false
					 end
				elseif v~=nil then
					return false
				end
			 end
			return true
		 end
	List=function(...)--Pythonical list type. Has Lua table functions as methods.
		local doc=[[Pythonical list type. Has Lua table functions as methods.
			So versatile!
				List(...)    --create list from a list.
				List(lst)    --create list from a list.
				List(lst,...)--same as List(...)
				List{lst}    --create list from a list.
				List()       --create an empty list.
				List{}       --create an empty list.
				List{size=n,default=v}--create list of size n, value v.
				List{v,size=n}        --create list of size n, value v.
				List{v,s=n}           --s can be used instead of size.
				List{n,default=v}     --create list of size n, value v.
			]]
		local self={}
		local args={...}
		if #args==1 and (type(args[1])=="table" or type(args[1])=="List") then
			args.size=args[1].size or args[1].s or 0
			args.default=args[1].default
			if args.size and args.default==nil then
				args.default=args[1][1]
			 elseif args.default~=nil and args.size==nil then
				args.size=args[1][1] or 0
			 end
			if args.size~=nil and args.size~=0 and args.default~=nil then
				for i=1,args.size do--List{size=n,default=v}
					dbg{"List.init(): i:%s %s" % {i,args.default},s="structures"}
					self[i]=args.default
				 end
			 else
				self=args[1]--List(lst),List{...},List{}
			 end
		 elseif #args==0 then--List()
				self={}
		 else
			self=args
		 end
		self.s 	    =nil--another name for size
		self.size   =nil--name doesn't clash with "table" table, but remove anyway.
		self.default=nil--name doesn't clash with "table" table, but remove anyway.
		methodist(self,table)
		methodist(self,{len=function(self) return #self end})
		settype(self,"List")
		return self
	 end
	--[[not List methods:]]
	function cons(a,b)--cons-entrate.
		local doc=[[cons function.
			cons(a,b)

			Combine a,b into one list.

			a,b-->{a,b}
			{1,2},3->{1,2,3}
			{1,2,3},{4,5}->{1,2,3,4,5}

			]]
		local uselist=false
		if type(a)=="List" or type(b)=="List" then
			uselist=true
		 end
		if not (type(a)=="table" or type(a)=="List") then
			a={a}
		 end
		if not (type(b)=="table" or type(b)=="List") then
			b={b}
		 end
		local ss=extend(a,b)
		if uselist then
			ss=List(ss)
		 end
		return ss
	 end
	function sort(tbl,comp)--because table.sort doesn't return the table!!! WHY NOT?!
		local doc=[[Returns a new sorted table.
			tbl=sort(tbl,comp)
			]]
		local ss=copy(tbl)
		_SORT(ss,comp)
		return ss
	 end
	function uniq(tbl)--like UNIX uniq command. Use on sorted lists.
		local doc=[[Removes duplicate consecutive entries from a sorted list.
			uniq(tbl)
			Like the UNIX `uniq` command, it assumes the input table is
			already sorted.
			]]
		--todo: make it return a List if input was a List.
		local ss={}
		local last
		for k,v in ipairs(tbl) do
			if v~=last then
				last=v
				push(ss,v)
			 end
		 end
		return ss
	 end
--[[Strings]]
	function repr(s)--string representation of basic types.
		local doc=[[string representation of basic types.
			repr(foo)
			]]
		--todo:more escape sequences for strings. or not.
		local ss={}
		if type(s)=="string" then--quote strings
			push(ss,'"')
			push(ss,s:gsub('"','\\"') )
			push(ss,'"')
		 elseif type(s)=="table" or type(s)=="List" then
			push(ss,tbl_repr(s))
		 else
			push(ss,tostring(s))
		 end
		return table.concat(ss)
	 end
	function indent(s,i)--Indent string s by indentation level i.
		local doc=[[Indent string s by indentation level i.
			indent(i,s)

			indent(1,"Hello world.")-->"    Hello world."

			An indentation level is 4 spaces.
			]]
		local ss={}
		for i=1,i do
			push(ss,"    ")--there shall be 4 spaces per indent level.
		 end
		push(ss,s)
		return table.concat(ss)
	 end
	function tbl_repr(arg,i,_hide)--string representation of a table.
		local doc=[[Return the string representation of a table.
			tbl_repr(arg,i,_hide)

			arg:table or List --the table
			i:int 			  --indentation level. can be 0 or nil.
			__hide:bool 	  --if true, hide double underscore keys.
			]]
		if i==nil then i=0; end
		local s={}
		local ss={}
		if table.is_empty(arg) then
			return "{}"
		 end
		for k,v in pairs(arg) do
			if __hide==true
				and type(k)=="string" 
				and k[1]=='_'
				and k[2]=='_'
				then --hide double underscore keys:
					pass()
			 else
				s={}
				s=push(s,indent("[",i+1))
				s=push(s,repr(k))
				s=push(s,"]=")
				if type(v)=="table" or type(v)=="List" then
					s=push(s,tbl_repr(v,i+2,_hide))
				 else
					s=push(s,repr(v))
				 end
				ss=push(ss,table.concat(s))
			 end
		 end
		ss={table.concat(ss,",\n")}
		ss=pushleft(ss,"{")
		ss=push(ss,indent("  }",i))--two extra spaces so that code folding can work.
		ss=table.concat(ss,"\n")
		return ss
	 end
	function tbl_str(arg,i)--Table-->string, hides string keys that start with a double underscore.
		local doc=[[Table to string, hides double underscore string keys.
			tbl_str(arg)-->string
			]]
		return tbl_repr(arg,i,true)
	 end
	do--[[string indexing]]
		--[[
		a='abcdef'
		return a[4]       --> d
		return a(3,5)     --> cde
		return a{1,-4,5}  --> ace
		]]
		getmetatable("").__index=function(str,i)--to enable string indexing
			if type(i)=="number" then
				return string.sub(str,i,i)
			 else
				return string[i]
			 end
		 end
		getmetatable("").__call=function(str,i,j)--to enable string indexing
			if type(i)~="table" then return string.sub(str,i,j) 
			 else local t={} 
				for k,v in ipairs(i) do t[k]=string.sub(str,v,v) end
				return table.concat(t)
			 end
		 end
	 end--[[string indexing]]
	do--[[string interpolation]]
		getmetatable("").__mod=function(a, b)--enable string interpolation
			if not b then
				return a
			 elseif type(b) == "table" then
				return string.format(a, unpack(b))
			 else
				return string.format(a, b)
			 end
		 end
	 end--[[string interpolation]]
	function str(val)--function to make an object printable.
		local doc=[[Convert an object to a string.
			str(obj)-->a string

			Use this when you want to print an object.
			]]
		if type(val)=="table" or type(val)=="List" then
			return tbl_str(val)
		 else
			return tostring(val)
		 end
	 end
	function print(s,...)--print(a,b,c)--and it works!
		local doc=[[Print function that accepts multiple args.
			print(s,...)

			Modeled after the python print function.
			print(a,b,c)--and it works!
			]]
		local sep=' '
		local ss={str(s)}
		local args={...}
		for k,v in pairs(args) do
			push(ss,sep)
			push(ss,str(v))
		 end
		push(ss,'\n')
		ss=table.concat(ss)
		io.stdout:write(ss)
	 end
	function printf(s,...)
		local doc=[[printf function.
			printf(s,...)
			]]
		local arrgs={...}
		return io.write(s:format(unpack(arrgs)))
	 end
	function sprintf(s,...)
		local doc=[[sprintf function.
			sprintf(s,...)-->string
			]]
		local arrgs={...}
		return s:format(unpack(arrgs))
	 end
	string.trim   =function(s)--trim string
		local doc=[[Removes leading and trailing whitespace.
			string.trim(s)-->string
			s:trim()--is also a string method

			string.trim("   ok  ")->"ok"
			]]
		return s:match( "^%s*(.-)%s*$" )
	 end
	string.ltrim  =function(s)--trim leading whitespace from string.
		local doc=[[Removes leading whitespace from a string.
			string.ltrim(s) --> trimmedString
			
			Ex:
				string.ltrim("   Hello, World   ") --> "Hello, World!   "
			]]
		return string.gsub(s,"^%s*", "")
	 end
	string.rtrim  =function(s)--trim trailing whitespace from string.
		local doc=[[Removes trailing whitespace from a string.
			string.rtrim(s) --> trimmedString
			
			Ex:
				string.rtrim("   Hello, World   ") --> "   Hello, World!"
			]]
		return string.gsub(s,"%s+$", "")
	 end
	string.trimall=function(s)--Removes all whitespace from a string.
		local doc=[[Removes all whitespace from a string.
			string.trimall(s) --> s without any whitespace

			Ex:
				string.trimall("  This is a test  ")-->"Thisisatest"

			You might use this on base64 encoded strings, for example.
				]]
		--[[gsub returns two results, I only want the first one 
			here so I assign the result to a variable.
			]]
		local ss=s:gsub("%s+",'')
		return ss
	 end
	string.split  =function(s,sep,_max,_regex)--like python string split.
		local doc=[[Splits a string into a table of substrings.
			s (string): The string to split.
			sep (string, optional): The separator to split on.
				Defaults to '%s+' (space characters).
			_max (number, optional): Maximum number of splits.
				Defaults to -1 (no limit).
			_regex (boolean, optional): Whether the separator should
				be treated as a regex pattern. Defaults to false.

			Returns:
				A table of substrings resulting from splitting the input
				string.

			Ex:
				string.split("1-2-3", "-") --> {"1","2","3"}
			]]
		if sep=='' or sep==nil then
			sep='%s+'--split on space chars
			_regex=true
		 end
		assert(_max == nil or _max >= 1)
		local ss={}
		if s:len() > 0 then
			local plain = not BOOL(_regex)
			_max=_max or -1
			local i=1
			local start=1
			local first,last=s:find(sep,start,plain)
			while first and _max ~= 0 do
				ss[i]=s:sub(start,first-1)
				i=i+1
				start=last+1
				first,last=s:find(sep,start,plain)
				_max=_max-1
			 end
			ss[i]=s:sub(start)
		 end
		return ss
	 end
	string.join   =function(s,tbl)--like python string join.
		local doc=[[Joins a table of strings into a string.
			string.join(s,tbl)

			s (string):  The delimiter to use between items.
			tbl (table): The table of strings to join.

			Returns a single string composed of the joined table elements.

			Ex:
				string.join(", ", {"apple", "banana", "cherry"})
					--> "apple, banana, cherry"
				string.join("", {"a", "b", "c"})--> "abc"
			]]
		return table.concat(tbl,s)
	 end
	string.slice  =function(s,first,last,step)--pythonic slice, but in lua we start at 1
		local doc=[[Slices a string from a Pythonic perspective.
			string.slice(s,first,last,step)

			s (string): The string to slice.
			first (number, optional): The starting index of the 
				slice. Defaults to 1.
			last  (number, optional): The ending index of the slice.
				Defaults to the length of the string.
			step  (number, optional): The step size for slicing.
				Defaults to 1.

			Returns:
				A substring of the input string, sliced according to the
				provided parameters.

			Ex:
				string.slice("Hello, World!", 8, 12, 2)
				string.slice("Lua is great!", 1, 7, 2)
			]]
		local ss={}
		for i=first or 1,last or #s,step or 1 do
			ss[#ss+1]=s[i]
		 end
		return table.concat(ss)
	 end
	string.startswith=function(s,start)
		local doc=[[Checks if a string starts with another.
			string.startswith(s,start)

			s (string): The string to check.
			start (string): Does it start with this string?

			Returns a boolean indicating whether the string starts with
			the specified substring.

			Ex:
				string.startswith("Hello, World!", "Hello") --> true
				string.startswith("Lua is great!", "great!") --> false
			]]
		return s:sub(1,#start)==start
	 end
	function dbg(args)--debug print
		local doc=[[Debug print function with filtering capabilities.
			dbg(args)

			args (table): A table containing arguments to print. The
			table may contain a key `s` to specify a filter class
			for the message.

			Usage:
				dbg({"message", s="filter_class"})
				dbg{"message",  s="filter_class"} --prefer this syntax.

			Filtering:
				Set `DBG_SUPPRESS` to control which messages get
				printed. Any key set to a non-false, non-nil value
				will suppress messages of that type.
				
				Example:
					DBG_SUPPRESS["error"] = true
					dbg({"An error occurred.", s="error"})
						--message will be suppressed due to the filter.
					dbg({"A general log message."})
						 -- message will still be printed.
			]]
		if DEBUG then
			if not DBG_SUPPRESS[args.s] then
				for _,v in ipairs(args) do
					io.stderr:write(str(v).." ")
				 end
				io.stderr:write("\n")
				io.stderr:flush()
			 end
		 end
	 end
	 DBG_SUPPRESS={}--[[Used to filter out debug messages. Set a key to any
		non-false,non-nil value to exclude debug messages of that type.
		Ex: DBG_SUPPRESS["foo_error"]=1
			dbg{"found a foo error!",s="foo_error"}--message will be suppressed.
		]]
--[[Functional]]
	--functional and logical: IF,IFF,NOT,BOOL use Python-style boolean logic.
	function BOOL(arg)--Return false if arg in [nil,zero,false,"",{}] else return true
		local doc=[[Python style boolean function.
			BOOL(arg)

			return false if arg in
				[nil,zero,false,"",{},List()] else return true

			In Lua only nil and false are false, but Python is more
			permissive, where zero,empty strings,empty lists and dicts,
			all evaulate as false. This function uses the Python style.
			]]
		if arg==nil or arg==0 or arg==false or arg == ""
			or (type(arg)=='table' and table.is_empty(arg)) --empty table
			or (type(arg)=='List'  and arg:len()==0 )		  --empty list
		 then
			return false
		 else
			return true
		 end
	 end
	function IF(bool,v1,v2) --if BOOL(bool) v1 else v2
		local doc=[[if BOOL(bool) v1 else v2
			IF(bool,v1,v2)

			Evaluates a boolean expression and returns either v1 or v2
			based on the result.

			Uses python-style boolean evauation.

			IF(true, "true", "false")-->"true"
			IF(false, "true", "false")-->"false"
			]]
		if BOOL(bool) then
			return v1
		 else
			return v2
		 end
	 end
	function IFF(bool,f1,f2)--if BOOL(bool) f1() else f2()
		local doc=[[IFF function.
			IFF(bool,f1,f2)

			Similar to IF but takes functions f1 and f2 instead of values.
			Executes f1() if BOOL(bool) returns true,
			otherwise executes f2().

			Uses python-style boolean evauation.

			IFF(true,function() print("f1") end,
					 function() print("f2") end)-->f1()
			]]
		if BOOL(bool) then
			return f1()
		 else
			return f2()
		 end
	 end
	function NOT(arg) --Return true  if arg in [nil,zero,false,"",{}] else return false
		local doc=[[NOT function.
			NOT(arg)

			Returns true if arg is in [nil,zero,false,"",{}],
			else returns false.

			Uses python-style boolean evauation.

			NOT(nil)-->true
			NOT(0)-->true
			NOT(false)-->true
			NOT("")-->true
			NOT({})-->true
			]]
		if not BOOL(arg) then
			return true
		 else
			return false
		 end
	 end
	function CALL(f,_args)--Call function f if f not nil
		local doc=[[Calls f if it is a function and is not nil.
			CALL(f,_args)

			If args is nil, calls f() directly;
			otherwise, unpacks args and passes them to f().
			CALL(function() print("Hello") end, {})-->prints "Hello"
			CALL(function(a) print(a) end, {"World"})-->prints "World"
			]]
		if type(f)=="function" then
			if _args==nil then 
				return f()--can't unpack nil.
			 else
				return f(unpack(_args))
			 end
		 end
		return nil
	 end
	function DYNAMIC(name)--Dynamic scoping function.
		local doc=[[Dynamic scoping function.
			DYNAMIC(name)

			Returns a function that, when called, returns the dynamically
			scoped value of the global variable named by the input string.

			DYNAMIC("print")()-->returns the current print function.
			]]
		local name=name--closure
		return function()
				return _G[name]
		 end
	 end
	function ANY(args)--true if BOOL(arg) for any arg in args.
		local doc=[[Returns true if true for any argument.
			ANY(args)

			Uses python-style boolean evauation.

			ANY({true, false})-->true
			ANY({true, true}) -->true
			ANY({false,false})-->false
			ANY({})           -->false
			ANY(List())       -->false
			]]
		if type(args)=="table" and table.is_empty(args) then
			return false
		 end
		if (type(args)=='List'  and args:len()==0 ) then 
			return false
		 end
		for _,arg in ipairs(args) do
			if BOOL(arg) then return true end
		 end
		return false
	 end
	function ALL(args)--true if BOOL(arg) for all arg in args.
		local doc=[[returns true if BOOL(arg) for all arg in args.
			ALL(args)

			Uses python-style boolean evauation.

			ALL({"!"})      -->true
			ALL({1,2,3})    -->true
			ALL({1,0,3})    -->false
			ALL({})         -->false
			ALL(List())     -->false
			ALL({"nope",""})-->false
			]]
		if type(args)=="table" and table.is_empty(args) then
			return false
		 end
		if (type(args)=='List'  and args:len()==0 ) then 
			return false
		 end
		for _,arg in ipairs(args) do
			if not BOOL(arg) then return false end
		 end
		return true
	 end
	function PARTIAL(f,arrg)
		local doc=[[PARTIAL function application.
			PARTIAL(f,arrg)

			Returns a variadic function where arrg is the first argument.

			The original function f is expected to take arrg as its first
			argument, followed by any number of additional arguments.

			PARTIAL(print, "Hello")("World")-->prints "Hello World"
			PARTIAL(print, "Hello")("Steve")-->prints "Hello Steve"
			]]
		return function(...)
			local arrgs={...}
			return f(unpack{arrg,unpack(arrgs)})
		 end
	 end
	function APPLY(f,...)
		local doc=[[APPLY function.
			APPLY(f,...)

			Calls function f with the optional arg list.

			APPLY(math.sqrt,16)-->returns 4
			]]
		local _args={...}
		return f(unpack(_args))
	 end
	function MAP(f,args,iter)--Applies the function f to every element in the list args.
		local doc=[[Applies the function f to every item in the list args.
			MAP(f,args)
			MAP{f,args}
			MAP(f,args,iter)
			MAP{f,args,iter=pairs}--alternate syntax allows named arg.

			Returns a list of the results.

			Will iterate over elements in args using an iterator function,
			which defaults to ipairs().

			Examples:
			MAP(function(x) return x * 2 end, {1, 2, 3})
			--> {2, 4, 6}
			
			Using the default iterator (ipairs):
			MAP(function(x) return x + 1 end, {1, 2, 3})
			--> {2, 3, 4}
			
			Specifying a custom iterator:
			local t = {[1] = "a", [2] = "b", [3] = "c", ["foo"]="bar"}
			MAP(function(v) return v end, t, pairs)
			--> {"a","b","c","bar"}
			]]
		if type(f)=="table" or type(f)=="List" then--MAP{f,args,iter}
			assert(args==nil and iter==nil,"expected MAP{f,args,iter}. Did you mean MAP(f,args,iter)?")
			local argv=f
			f   =argv[1] or argv.f
			args=argv[2] or argv.args
			iter=argv[3] or argv.iter --this is how to allow named args!
		 end
		local ss={}
		if iter==nil then--use ipairs
			iter=ipairs
		 end
		for k,v in iter(args) do
			ss[k]=f(v)
		 end
		if type(args)=="List" then
			ss=List(ss)
		 end
		return ss
	 end
	 -- _MAP=MAP--what a terrible name for a function. Save it as _MAP because I inevitably make a variable named MAP.
	function FOREACH(f,args,iter)
		--to be defined as MAP
	 end
	 FOREACH=MAP
	function MIN(args)--Returns the smallest item in args or nil if args is empty.
		local doc=[[Returns the smallest item in args or nil if args is empty.
			MIN(args)

			Iterates through the sequence to find the minimum value.

			MIN({10, 20, 30})-->10
			MIN({})-->nil
		]]
		local m=args[1] or nil--yes I know that if args is empty then args[1] is nil. I would intentionally return nil in that case, hence the 'or nil' part that really isn't necessary.
		for _,v in ipairs(args) do
			if v<m then
				m=v
			 end
		 end
		return m
	 end
	function MAX(args)--Returns the largest  item in args or nil if args is empty.
		local doc=[[Returns the largest item in args or nil if args is empty.
			MAX(args)

			Iterates through the sequence to find the maximum value.

			MAX({10, 20, 30})-->30
			MAX({})-->nil
		]]
		local m=args[1] or nil
		for _,v in ipairs(args) do
			if v>m then
				m=v
			 end
		 end
		return m
	 end
	function SUM(args)--Sum a seqence of numbers.
		local doc=[[Sums a sequence of numbers.
			SUM(args)

			Returns the sum of all numeric values in the sequence.
			The sequence must contain only numbers.
			Returns 0 if args is empty.

			SUM({1, 2, 3, 4, 5})-->15
			SUM({10, 20, 30, 40, 50})-->150
			SUM({})-->0
		]]
		local acc=0
		for k,v in ipairs(args) do
			acc=acc+v
		 end
		return acc
	 end
	function DEPTH(f,arrgs)--Depth-first traversal: f(arg) for arg in args.
		local doc=[[--Depth-first traversal: f(arg) for arg in args.
			DEPTH(f,args)

			Depth-first traversal, applies function f as it goes.
			Returns the arg sequence unchanged.

			Example:
				t = {1,2,{3,{4}},5}
				DEPTH(print, t)--> prints 1 2 3 4 5
		]]
		for _,v in ipairs(arrgs) do
			if type(v)=='table' then
				DEPTH(f,v)
			else
				f(v)
			 end
		 end
		return arrgs
	 end
		DEPTHFIRST=DEPTH
	function CURRY(f)--Curry2 in lua.
		local doc=[[Curry2 in lua.
			CURRY(f)

			This function is designed to implement currying in Lua.
			Currying is a technique in functional programming where a
			function with multiple arguments is transformed into a
			weirdo function structure that represents the curried form
			of the input function. Each level of nesting corresponds to
			a fixed argument of the original function.

			To use this function, pass the original function as the
			argument. The resulting curried function can then be called
			with the required number of arguments, either all at once or
			over multiple calls.

			This is curry2, so it needs a function with 2 arguments.

			function add(a,b)
				return a+b
			 end
			cad=CURRY(add)

			--all at once:
			print(cad(1)(2))--> 3

			--one at a time:
			c =cad(2^5)
			cc=c(1)
			print(cc)-->33
			]]
		return function(x)
			return function(y)
				local args={x,y}--gotta do this or else x is not in scope.
				return f(unpack(args))
			 end
		 end
	 end
		curry=CURRY
	function FILTER(f,args)
		local doc=[[Filters a table or List based on a predicate function, f.
			FILTER(f,args)

			Returns a table or List containing the items where
			f(item) is true.

			Ex:
				even=function(n) return n % 2 == 0;end
				nn=FILTER(even, {1, 2, 3, 4, 5})
				print(nn) --> {2, 4}
			]]
		local is_list=false
		if type(args)=="List" then
			is_list=true
		 end
		local ss={}
		for k,v in ipairs(args) do
			if f(v) then
				ss[#ss+1]=v
			 end
		 end
		if is_list==true then ss=List(ss);end
		return ss
	 end
	function BSIEVE(f,args)--Binary sieve: separates the haves from the have-nots.
		local doc=[[Binary sieve: separates the haves from the have-nots.
			haves,havenots=BSIEVE(f,args)

			This function separates elements in a table (args) into two
			sets based on a predicate function (f). Elements that satisfy
			the predicate function are placed in the 'haves' set, while
			those that do not satisfy the predicate are placed in the
			'havenots' set.

			Parameters:
				f: 	A predicate function that takes one argument and
					returns a boolean indicating whether the element
					belongs to the 'haves' set.
				args: A table containing elements to be separated.

			Returns:
				Two tables: The first contains elements from args that
				satisfy the condition defined by the predicate function
				f, and the second contains elements that do not.

			Example usage:
				over_ten = function(n) return n > 10 end

				over,under=BSIEVE(over_ten,{9, 10, 11, 12, 13})
				print("> 10:", unpack(over))  --{11, 12, 13}
				print("<=10:", unpack(under)) --{9, 10}
			]]
		local haves={}
		local havenots={}
		for k,v in ipairs(args) do
			if f(v) then
				haves[#haves+1]=v
			 else
				havenots[#havenots+1]=v
			 end
		 end
		return haves,havenots
	 end
	 bsieve=BSIEVE
	function ZIP(seq1,seq2)--Python zip. Stops at length of shortest sequence.
		local doc=[[Makes a sequence of pairs from 2 sequences.
			ZIP(seq1, seq2)

			Like Python's zip function.
			Stops at the end of the shortest sequence.

			Ex:
				local seq1 = {1, 2, 3}
				local seq2 = {'a', 'b', 'c'}
				local zipped = ZIP(seq1, seq2)
				--zipped-->{{1, 'a'}, {2, 'b'}, {3, 'c'}}

			]]
		local uselist=false
		if type(seq1)=="List" or type(seq2)=="List" then
			uselist=true
		 end
		local ss={}
		local i=1
		while true do
			if seq1[i]==nil or seq2[i]==nil then
				if uselist==true then ss=List(ss);end
				return ss
			 end
			ss[#ss+1]={seq1[i],seq2[i]}
			i=i+1
		 end
	 end
	function FULLZIP(seq1,seq2,placeholder)--Python zip but uses the longest sequence with a non-nil placeholder for missing data.
		local doc=[[Makes a sequence of pairs from 2 sequences.
			FULLZIP(seq1,seq2,placeholder)

			Python zip but uses the longest sequence.

			The placeholder cannot be nil.

			Ex:
				seq1 = {1, 2, 3, 4}
				seq2 = {'a', 'b'}
				placeholder = 'X'
				zippy = FULLZIP(seq1, seq2, placeholder)
				--zippy-->{{1,'a'},{2,'b'},{3,'X'},{4,'X'}}
			]]
		local uselist=false
		if type(seq1)=="List" or type(seq2)=="List" then
			uselist=true
		 end
		assert(placeholder~=nil,"placeholder can't be nil.")
		local ss={}
		local i=1
		while true do
			if seq1[i]==nil and seq2[i]==nil then
				if uselist==true then ss=List(ss);end
				return ss
			 end
			if seq1[i]==nil then
				ss[#ss+1]={placeholder,seq2[i]}
			elseif seq2[i]==nil then
				ss[#ss+1]={seq1[i],placeholder}
			else
				ss[#ss+1]={seq1[i],seq2[i]}
			end
			i=i+1
		 end
	 end
	function INTERLEAVE(seq1,seq2)--True interleave. Stops at length of shortest sequence.
		local doc=[[Interleave 2 sequences.
			INTERLEAVE(seq1, seq2)

			Interleaves two sequences (seq1 and seq2),
			stopping at the length of the shortest sequence.

			Ex:
				seq1 = {1,2,3}
				seq2 = {'a','b','c'}
				interleaved = INTERLEAVE(seq1, seq2)
				--interleaved-->{1,'a',2,'b',3,'c'}
			]]
		local uselist=false
		if type(seq1)=="List" or type(seq2)=="List" then
			uselist=true
		 end
		local ss={}
		local i=1
		while true do
			if seq1[i]==nil or seq2[i]==nil then
				if uselist==true then ss=List(ss);end
				return ss
			 end
			ss[#ss+1]=seq1[i]
			ss[#ss+1]=seq2[i]
			i=i+1
		 end
	 end
	function FULLINTERLEAVE(seq1,seq2,placeholder)--longest sequence, non-nil placeholder for missing data.
		local doc=[[Interleave 2 sequences, with placeholder values.
			FULLINTERLEAVE(seq1, seq2, placeholder)

			Returns a sequence containing alternating elements from seq1
			and seq2, using the placeholder for missing values in the
			shorter sequence.

			Returns a List if seq1 and/or seq2 is a List.

			Ex:
				seq1 = {1,2,3,4}
				seq2 = {'a','b'}
				placeholder='X'
				interleaved=FULLINTERLEAVE(seq1,seq2,placeholder)
				--interleaved-->{1,'a',2,'b',3,'X',4,'X'}
			]]
		local uselist=false
		if type(seq1)=="List" or type(seq2)=="List" then
			uselist=true
		 end
		assert(placeholder~=nil,"placeholder can't be nil.")
		local ss={}
		local i=1
		while true do
			if seq1[i]==nil and seq2[i]==nil then
				if uselist==true then ss=List(ss);end
				return ss
			 end
			if seq1[i]==nil then
				ss[#ss+1]=placeholder
				ss[#ss+1]=seq2[i]
			elseif seq2[i]==nil then
				ss[#ss+1]=seq1[i]
				ss[#ss+1]=placeholder
			else
				ss[#ss+1]=seq1[i]
				ss[#ss+1]=seq2[i]
			end
			i=i+1
		 end
	 end
	function PARTITION(f,seq,_retain)
		local doc=[[Partition a sequence.
			PARTITION(f, seq,_retain)

			f is a boolean function that determines the separator
			item.

			_retain has 3 modes: set it to "keep" and it will retain
			the separator item as it's own subsequence. Set it to
			any other non-false value and it will begin the next
			sub-sequence starting with the separator item.

			If _retain is nil or false, the separator item will be
			discarded.
			]]
		local result = {}
		local subsequence = {}

		-- Iterate over the sequence
		for _, item in ipairs(seq) do
			-- Apply the function f to the current item
			if f(item) then
				-- If f(item) returns true, add the current subsequence to the result
				-- and start a new subsequence
				if #subsequence>0 then--don't add empty subsequences.
					table.insert(result,subsequence)
				 end
				subsequence = {}
				if _retain then
					table.insert(subsequence, item)--retain the partition item.
					if _retain=="keep" then
						table.insert(result, subsequence)
						subsequence={}
					 end
				 end
			else
				-- Otherwise, add the item to the current subsequence
				table.insert(subsequence, item)
			end
		end

		-- Add the last subsequence if it exists
		if #subsequence > 0 then
			table.insert(result, subsequence)
		end

		return result
	 end
--[[Bitwise]]
	function setbit(n,b)--Set bit b of number n.
		local doc=[[Set bit b of number n.
			setbit(n,b)-->number

			bits start at 1. there is no bit zero. I say so.
			]]
		-- return n | (1 << (b-1))
		if b==0 then return n end--bits start at 1. there is no bit zero. I say so.
		return bit.bor(n,bit.lshift(1,b-1))
	 end
	function setbits(...) --create a new number with bits set.
		local doc=[[Create a new number with bits set.
			n=setbits(...)

			Pass in a list bit numbers to set.

			Bits are numbered starting at 1. So 1 to 8 for bits in a byte.
			Ex: setbits(3,1)--> 101 in binary.

			Allows non-numbers as args, they will be skipped.
			You can't use nil as a placeholder in a list. It means end
			of list. So, you can use any non-number as a placeholder.

			setting bit 0 is a no-op. There is no bit zero.

			print("bit: "..setbits(3,1))--> 5
			]]
		local args={...}
		local ss=0
		for _,v in ipairs(args) do
			if type(v)=="number" then
				ss=setbit(ss,v)
			 end
		 end
		return ss
	 end
	 assert(setbits(3,1)==5)
	function unsetbit(n,b)--unset bit b of number n
		local doc=[[Unset bit b of number n.
			unsetbit(n,b)-->number

			bits start at 1. there is no bit zero. I say so.
			]]
		-- return n & ~(1 << b)
		return bit.band(n,bit.bnot(bit.lshift(1,b-1)))
	 end
	function checkbit(n,b)--check bit b of number n
		local doc=[[Check if bit b of number n is set.
			checkbit(n,b)-->bool

			bits start at 1. there is no bit zero. I say so.
			]]
		-- return n & (1 << b) ~= 0
		assert(n~=nil and type(n)=="number")
		return bit.band(n,bit.lshift(1,b-1) )~=0
	 end
--[[Misc]]
	function circle_back(pos,size,base0)
		local doc=[[Generate indices for iterating round a list.
			circle_back(pos,size,base0)-->index

			Return incremented pos or "circle back" to beginning of an
			array of a certain size. Set base0 to use this on zero based
			arrays.

			Use this to implement circular arrays.

			Usage: pos has a different meaning if base0 is true:
				--for lua table or List:
				seq={11,22,33}
				size=#seq
				pos=1
				while 1 do
					print(seq[pos])
					pos=circle_back(pos,size)
				 end

				--for c/c++ array:
				seq=Array{3,0}--[0,0,0]
				size=seq:len()
				seq[0]=11
				seq[1]=22
				seq[2]=33
				pos=0
				while 1 do
					print(seq[pos])
					pos=circle_back(pos,size,true)
				 end
			]]
		if BOOL(base0) then--base0 (offset for c/c++ array)
			local p=pos+1
			if p >= size then
				p=0
			 end
			return p
		 else--base1 (index for lua list or table)
			local p=pos+1
			if p > size then
				p=1
			 end
			return p
		 end
	 end
	function pass()--no op
		local doc=[[It does nothing!
			pass()-->nil
			]]
		return nil
	 end
	function SSET(arrg)--Safe set, disallow assignment of blank value. Used to detect programming errors.
		local doc=[[Safe set, disallow assignment of blank value.
			SSET(arrg)-->arrg

			Used to detect programming errors and unitialized data.
			Usage: foo=SSET(val)
			Error on nil, empty string, or empty table.
			]]
		if arrg=="" or arrg==nil or ( (type(arrg)=="table" or type(arrg)=="List") and not next(arrg) ) then
			error("unset variable")
		 end
		return arrg
	 end

	dir=function(tbl)--Print keys of tbl.
		local doc=[[Print keys of tbl.
			dir(tbl)

			Useful in interactive interpreter.
			]]
		for k,v in pairs(tbl) do
			print(k)
		 end
	 end
	keys=function(tbl)--Return keys of tbl.
		local doc=[[Return keys of tbl.
			keys(tbl)->list of keys
			]]
		local ss={}
		for k,v in pairs(tbl) do
			ss[#ss+1]=k
		 end
		return ss
	 end
	values=function(tbl)--Return values of tbl.
		local doc=[[Return values of tbl.
			values(tbl)->list of values
			]]
		local ss={}
		for k,v in pairs(tbl) do
			ss[#ss+1]=v
		 end
		return ss
	 end

	-- function ERROR(msg,_code) --Exit program with error message.
	-- 	local doc=[[Exit program with error message.
	-- 		ERROR(msg)
	-- 		ERROR(msg,code)--provide optional error code.
	-- 		]]
	-- 	if msg ~="" and msg~=nil then
	-- 		io.stderr:write("ERROR: "..msg.."\n")
	-- 		io.stderr:flush()
	-- 	 end
	-- 	os.exit(_code or 1)
	--  end
	function warn(msg)--Print a warning to  stderr.
		local doc=[[Print a warning to stderr.
			warn(msg)
			]]
		if msg ~="" and msg~=nil then
			io.stderr:write("WARNING: "..msg.."\n")
			io.stderr:flush()
		 else
			warn("warn() called with \"\" or nil.")
		 end
	 end
	function shell(cmd)--Lua5.1 only
		local doc=[[Executes a shell command.
			shell(cmd)

			Super dangerous function. Security disaster.

			Uses the $SHELL environment var to determine the
			shell.

			Ex:
				shell("touch timestamp")

			If the command fails, this function will call the
			"error" function to report the error and crash your
			program.

			Don't ship code that uses this.
			]]
		local err=os.execute(cmd)
		if err~=0 then
			error("shell command failed with code %s: %s" % {err,cmd},err)
		 end
	 end
	function getext(path,_sep)--Return the file extension.
		local doc=[[Return the file extension of path if it exists.
			getext(path)-->file_ext

			Returns an empty string if no file path exists.
			Returns "." if path=="."
			]]
		local root,ext=os.path.splitext(path,_sep)
		return ext
	 end
	function basename(path,_sep)--this is shell basename
		local doc=[[Shell basename
			basename(path,_sep)

			Returns the last path component from a given path.

			The optional _sep argument can be used to set the
			path separator.

			Ex:
				base = basename("/home/user/documents/file.txt")
				print(base)-->"file.txt"
			]]
		local sep; if _sep==nil then sep=package.config:sub(1,1) else sep=_sep;end
		if path==sep then return sep;end
		local parts = {}
		for part in path:gmatch("[^%s]+" % sep) do
			table.insert(parts,part)
		 end
		return parts[#parts] or ""
	 end
	function glob(pattern,_flags)--posix glob
		local doc=[[Glob pattern matching using the posix.glob library.
			glob(pattern,_flags)

			Glob pattern matching using the posix.glob library.

			_flags is an optional integer specifying flags for the glob.
				Defaults to 0. See: posix/doc/modules/posix.glob.html

			Returns a table of filenames

			Example usage:
				matches = glob("*.*")
				for _, match in ipairs(matches) do
					print(match)
				end

			Requires the posix module.
			]]
		local  glob=require 'posix.glob'.glob
		return glob(pattern,_flags or 0)
	 end
--[[Pythonic]]
	abs=math.abs
	all=ALL
	any=ANY
	bin=function(n,_width,_unsigned)
		local doc=[[Returns binary representation of signed int n as a string.
			bin(n)

			_width: byte width parameter. Default=4
					_width 1 through 8 is allowed.

			signed ints as large as  2^53-1 can be represented.
			signed ints as small as -2^53+1 can be represented.

			unsigned ints as large as  2^52-1 can be represented.
			unsigned ints as small as -2^52+1 can be represented.

			Of course, these will also be limited by the byte width.
			]]
		assert(n<=MAXINT,"int too large for bin()")
		assert(n>=MININT,"negative int too negative for bin()")

		if _unsigned then
			assert(n<=2^52-1,"unsigned int too large for bin()")
			assert(n>=-2^52+1,"negative unsigned int too negative for bin()")
		 end

		if _width==nil then
			_width=4
		 end
		if _width<=1 then _width=1;end
		if _width>=8 then _width=8;end

		local N=8*_width
		if _unsigned then
			assert(n<= 2^(N)-1)
			assert(n>= 0      )
		else
			assert(n<= 2^(N-1)-1)
			assert(n>=-2^(N-1)+1)
		 end

		local sign=n<0
		local n=int(abs(n))
		local ss={}
		local s --the result

		if sign then n=n-1; end--for 2s compliment

		while n~=0 do
			if n % 2 == 0 then
				ss[#ss+1]="0"
			 else
				ss[#ss+1]="1"
			 end
			n=math.floor(n/2)
		 end

		local start=#ss+1
		local limit=8*_width-1
		for i=start,limit,1 do
			ss[i]="0"
		 end
		s=table.concat(ss,""):reverse()
		if sign then
			s=s:gsub("1", "x")--2s compliment
			s=s:gsub("0", "1")--2s compliment
			s=s:gsub("x", "0")--2s compliment
			s="1"..s
		 else
			s="0"..s
		 end
		return "0b"..s
	 end
	ubin=function(n,_width,_unsigned)
		local doc=[[Return a binary representation of a 32 bit unsigned integer.
			ubin(n,_width)
			]]
		return bin(n,_width,true)
	 end
	bool=BOOL
	breakpoint=trace
	callable=function(obj)
		local doc=[[Return true if obj is callable like a function.
			callable(obj)-->bool
			]]
		if type(obj)=="function" then
			return true
		elseif type(obj)=="table" or type(obj)=="List" then
			local mt=debug.getmetatable(obj)
			return (type(mt)=="table" or type(obj)=="List") and type(mt.__call)=="function"
		else
			return false
		end
	 end
	chr=function(n)--return char for number n
		local doc=[[Return char for number n
			chr(n)-->string

			chr(99)-->"c"

			Only for ASCII.
			n must be in range [0..255]

			Empty string or 0 returns null char.
			]]
		return string.char(int(n))
	 end
	classmethod=methodist
	delattr=function(obj,name)
		local doc=[[Delete attribute name from obj.
			delattr(obj,name)
			]]
		obj[name]=nil
	 end
	dir=dir--different than python version.
	enumerate=Enum
	exec=exec
	filter=FILTER
	float=float
	getattr=function(obj,name,_default)
		local doc=[[Get attribute name from obj.
			getattr(obj,name)
			]]
		local ss=obj[name]
		if ss==nil then ss=_default end
		return ss
	 end
	globals=function()
		local doc=[[Return the table of global variables.
			globals()->table
			]]
		return _G
	 end
	hasattr=function(obj,name)
		local doc=[[Check if obj has an attribute by name.
			hasattr(obj,name)
			]]
		return getattr(obj,name)~=nil
	 end
	hex=function(n)
		local doc=[[Return hex representation of int as string: '0xAF01'
			hex(n)->string
			]]
		local s=int(n)
		s=string.format("%X",n)
		return "0x"..s
	 end
	input=function(_prompt)
		local doc=[[Prompt the user for a line of input.
			input(_prompt)-->string
			]]
		if type(_prompt)=="string" then--woe unto ye who don't prompt for input.
			io.write(prompt)
			io.flush()
		 end
		local ss=io.read("*l")--read a line
		return ss
	 end
	int=int
	len=len
	list=List
	locals=function()
		local doc=[[Return a table of local variables
			locals()-->table

			Does not get upvalues,closures,captured variables.
			]]
		local vv={}
		local i=1
		while true do
			local name,val=debug.getlocal(2,i)--level:2,index:i
			if name~=nil then
				vv[name]=val
			else
				break
			 end
			i=i+1
		 end
		return vv
	 end
	map=MAP
	max=MAX
	min=MIN
	oct=function(n)
		local doc=[[Convert an int to an octal string representation.
			oct(n)-->string
			]]
		local s=int(n)
		s=string.format("%o",n)
		return "0o"..s
	 end
	open=io.open
	file=io.open--used to be pythonic
	ord=function(c)
		local doc=[[Return number for char c
			orc(c)-->int

			ASCII only.
			]]
		return string.byte(c)
	 end
	pow=function(a,b)
		local doc=[[Exponentiation: raise a to the b power.
			pow(a,b)-->number

			math.pow in lua before version 5.3
			]]
		return a^b
	 end
	print=print
	range=range
	repr=repr
	reversed=REVERSE
	round=round
	setattr=function(obj,name,value)
		local doc=[[Set attribute name of obj.
			setattr(obj,name)
			]]
		obj[name]=value
	 end
	slice=slice
	sorted=sort--return a sorted copy. Use table.sort for an in-place sort.
	str=str
	sum=SUM--add a seqence of numbers.
	type=type
	zip=ZIP
--[[os]]
	os.capture=function(cmd)--popen
		local doc=[[Run a shell command and return its output.
			os.capture(cmd)-->string

			Super dangerous function. Security disaster. Fails
			in many weird ways.

			Uses the $SHELL environment var to determine the
			shell.

			If the command fails, this function will call the
			"error" function to report the error and crash your
			program, that is, unless some other internal error
			happens first, like command not found by the shell.
			See, in a case like that, some other function will
			report an error and crash your program.

			Other fails:
				If the command never exits.
				If the subprocess stdout cannot be read.
					(It can happen!)
				If ...

			Don't ship code that uses this.
			]]
		local f,s
		
		f=io.popen(cmd,"r")
		if not f then
			error("os.capture command failed: %s" % cmd)
		 end

		s=f:read("*a")
		if not s then
			error("os.capture read failed: %s" % cmd)
		 end

		f:close()

		s=s:gsub("[\n\r]+$","")--remove trailing newline
		s=s:trim()--removes leading and trailing ws
		return s
	 end
	os.getcwd=function()
		local doc=[[Get the current working directory.
			os.getcwd()-->string

			Requires the lfs module.
			]]
		local lfs=require("lfs")
		return lfs.currentdir()
	 end
	os.detect=function(check)--Check or guess the os.
		local doc=[[Check or guess the os.
			os.detect()

			This is not a python function.

			if called with no args, it returns a guess of what
			the os may be. Some possible guesses:
				Linux
				Darwin
				Win64
				"???" --if it can't figure it out.

			Will fail if your UNIX system doesn't have:
				"uname -s"

			if called with a check arg, it returns a bool after
			fuzzy matching.

			Check matches: (case insentitive)
				l,lin,linux:			Linux
				m,mac,macos,darwin:		Darwin
				w,win,win64,windows:	Win64

			package.config is available in Lua5.1 but it is undocumented.
			package.config:sub(1,1) returns the path separator:
				'/'  on unix/linux/macos
				'\\' on windows
			]]
		local guess="???"
		if package.config:sub(1,1)=="/" then--maybe unix/linux/macos
			guess=os.capture("uname -s;")
			assert(guess~=nil and guess~="","os.detect: Borked UNIX system")
		 end
		if package.config:sub(1,1)=="\\" then--maybe windows
			guess="Win64"
		 end

		if check~=nil then
			fuzz={
				l="Linux",
				lin="Linux",
				linux="Linux",
				--
				m="Darwin",
				mac="Darwin",
				macos="Darwin",
				darwin="Darwin",
				--
				w="Win64",
				win="Win64",
				win64="Win64",
				windows="Win64",
				}
			return fuzz[check:lower()]==guess
		 end
		return guess
	 end
	os.path={}
		os.path.realpath=function(path)
			local doc=[[Resolve a real file path.
				os.path.realpath(path)-->string

				The path must exist. If it doesn't exist this function
				returns nil.
				]]
			local  posix=require("posix")
			return posix.realpath(path)
		 end
		os.path.basename=function(path,_sep)
			local doc=[[Python style basename function.
				os.path.basename(path)-->string
				os.path.basename(path,sep)-->string

				You can provide the path separator. If you don't, it
				will be auto detected.
				]]
			if path=="" then return "";end
			local sep; if _sep==nil then sep=package.config:sub(1,1) else sep=_sep;end
			local ss=path:split(sep)
			ss=ss[#ss]
			return ss or ""
		 end
		os.path.dirname=function(path,_sep)
			local doc=[[Return the directory part of a path.
				os.path.dirname(path)-->string
				os.path.dirname(path,sep)-->string

				Returns a string which may be empty if no directory
				is in path.

				The returned directory string will not end in a path
				separator char unless the directory string represents
				the root directory.
				]]
			if path=="" then return "";end
			local path,_=os.path.split(path,_sep)
			return path
		 end
		os.path.expanduser=function(path)
			local doc=[[Replace ~ and ~user in paths.
				os.path.expanduser(path)-->string

				if path starts with ~ then the home dir of the current
				user will be resolved. This information comes from an
				environment variable. It will crash your program with
				an error if HOME or USERPROFILE is unset.

				if the path starts with ~user then the hypothetical
				home dir of a user will be confabulated.

				~user expansion is only available on Linux and MacOS.
				It will crash your program with an error if you try this
				on Windows.

				Ex:
					os.path.expanduser("~/docs")-->"/home/sandy/docs"
					os.path.expanduser("~sam/docs")-->"/home/sam/docs"
				]]
			if not path:startswith("~") then return path;end
			local m=path:match("^~([_%w]+)")
			local user=nil
			if m~=nil then
				user=m
				local pat="^~"..user
				local home

				if os.detect("linux") then
					home= "/home/%s"  % user
				 elseif os.detect("macos") then
					home= "/Users/%s" % user
				 else
					error("~user expansion is only available on Linux and MacOS.")
				 end

				do return path:gsub(pat,home);end
			 end
			local ss=os.getenv("HOME") or os.getenv("USERPROFILE")
			if ss==nil or ss=="" then
				error("HOME or USERPROFILE is unset. Unable to determine home dir.")
			 end
			ss=path:gsub("^~",ss)
			return ss
		 end
		os.path.getsize=function(filename)--only works on files.
			local doc=[[Get the size of a file.
				os.path.getsize(filename)-->int

				It only works on files.

				Returns nil if called on a directory or an unreadable file.
				]]
			local ff=io.open(filename,"rb")
			if ff then
				local size=0
				size=ff:seek("end")
				ff:close()
				return size
			 else
				return nil
			 end
		 end
		os.path.isfile=function(path)
			local doc=[[Returns true if path is a filepath.
				os.path.isfile(path)-->bool

				Requires lfs module
				]]
			-- local doc=[[lua implementation:
			-- 	is file (and is readable): the best that can be
			-- 	done without lfs or luaposix.
			-- 	]]
			-- if type(path)~="string" then return false end
			-- local f=io.open(path,"r")
			-- if f~=nil then
			-- 	io.close(f)
			-- 	return true
			-- else
			-- 	return false
			 -- end
			--[[lfs implementation:]]
			if path==nil or path=="" then return false;end
			local lfs=require("lfs")
			local attributes = lfs.attributes(path)
			if attributes then
				return attributes.mode=="file"
			 end
			return false
		 end
		os.path.join=function(...)
			local doc=[[Join 2 paths together.
				os.path.join=function(...)-->string

				Auto detect the path separator (this is what you want):
					os.path.join("foo","bar","baz")->"foo/bar/baz"

				2nd arg can be a path separator if the first arg is a table:
					os.path.join({"foo","bar","baz"},"\\")->"foo\\bar\\baz"

				Use keyword arg for sep:
					os.path{"foo","bar",sep=":"}
				]]
			local ss={...}
			local sep

			if  type(ss[1])=="table"
			 or type(ss[1])=="List" then
				sep=ss[1].sep or ss[2]
				ss=ss[1]
			 else
				sep=package.config:sub(1,1)
			 end
			if sep==nil then sep=package.config:sub(1,1);end

			if ANY(MAP(function(v) return type(v)~="string";end,ss)) then
				error("Need string args");
			 end

			ss=FILTER(function(v) return v~="";end,ss)
			ss=table.concat(ss,sep)
			ss=ss:gsub("%s+" % sep,sep)
			return ss
		 end
		os.path.split=function(path,_sep)
			local doc=[[Split a path.
				os.path.split=function(path)-->head,tail
				os.path.split=function(path,sep)-->head,tail

				Returns split path components. Splits from the right side.

				The path separator is optional and will be auto-detected if
				not supplied.

				Ex:
					os.path.split("/foo/bar)-->"/foo","bar"
				]]
			local sep; if _sep==nil then sep=package.config:sub(1,1) else sep=_sep;end
			local _,head,tail
			if path=="/" then return "/","" end--[[/]]
			if path:sub(-1)==sep then return path:sub(1,-2),"" end--[[foo/]]
			_=path:reverse():split(sep,1)
			head=_[#_]:reverse()
			tail=_[1]:reverse()
			if #_==1 then return "",tail end --[[foo]]
			if #_==2 and head=="" then return "/",tail end --[[/foo]]
			do return head,tail end
		 end
		os.path.splitext=function(path,_sep)
			local doc=[[Split a file extension off of a path.
				os.path.splitext(path)-->path,ext

				Ex:
					os.path.splitext("foo.txt")-->"foo",".txt"
				]]
			local sep; if _sep==nil then sep=package.config:sub(1,1) else sep=_sep;end
			local root,ext
			local ss,last

			if path=="" then return "","";end

			ss=path:split(sep)--sep is the path separator.
			if #ss>1 then
				last=ss[#ss]
				root=slice(ss,1,#ss-1)
				root=table.concat(root,sep)
			 else
				root=nill
				last=table.concat(ss)
			 end

			if last==nil then return root,"";end

			ss=last:split(".")
			if #ss>1 then
				ext=ss[#ss]
				last=slice(ss,1,#ss-1)
				last=table.concat(last,".")
				ext='.'..ext
			 else
				ext=""
			 end
			if root==nil then return last,ext;end
			root=table.concat({root,sep,last})
			return root,ext
		 end
--[[sys]]
	sys={}
	sys.exit=function(code)
		local doc=[[Alternative name for the os.exit function.
			sys.exit(code)
			]]
		return os.exit(code)
	 end
	sys.argv=arg--[[You will have to set this in every file you
					want to use it in! arg is nil if this is not
					the main file! So no sys.argv in that case!
					]]

--[[New]]
optionator=function(argv)
	local doc=[[A rather permissive option parser.
		optionator(argv)-->dict:options,list:args

		Accepts all sorts of stuff:
			arg1 -f --foo -b:BAR --bar=bar arg2

		Options are any that start with '-', any number of '-'!

		Use ':' or '=' to provide a value to an option lest the
		option have the default value true.

		The arg must be connected:
			--foo="myfoo"   --ok
			--foo "myfoo"   --nope
			--foo = "myfoo" --won't work right.
			--foo= "myfoo"  --c'mon!
			--foo ="myfoo"  --seriously?

		Usage:
			local options,args=optionator(arg)
			if haskey(options,"h","help") then
				--example of option with no arg:
				print("Help!")
			 end
			if haskey(options,"f","foo") then
				--example of option with arg:
				--because unset option is nil, we can do this:
				FOO=options.f or options.foo
			 end
			for _,arrg in ipairs(args) do
				do_whatever(arrg)
			 end
		]]
	local options={}
	local args={}
	for _,arg in ipairs(argv) do
		if arg:sub(1,1)=="-" then
			local name,value=unpack(arg:split("[:=]",1,true))
			name=string.gsub(name,"^-+","",1)
			if value==nil then value=true end
			options[name]=value
		else
			args[#args+1]=arg
		 end
	 end
	return options,args
 end
ezpath=function(path)--Less nonsense path resolver.
	local doc=[[Less nonsense path resolver.
		ezpath(path)-->string

		Don't you hate it when your pathnames don't work?

		Do you want to use paths that you use everyday from the
		shell?

		Well it can be that easy,

		--Suppose you are me, at home:
		  ezpath("~/docs/foo.txt")     -->"/home/me/docs/foo.txt"
		  ezpath("~me/docs/foo.txt")   -->"/home/me/docs/foo.txt"
		  ezpath("./docs/foo.txt")     -->"/home/me/docs/foo.txt"
		  ezpath("./docs/y/../foo.txt")-->"/home/me/docs/foo.txt"

		It calls expanduser and realpath on the path.

		The path must exist! realpath can't resolve a path
		that doesn't exist. So, that is the nonsense.

		Returns nil if the path doesn't exist.

		It even detects MacOS and uses /Users for /home

		It probably won't work on windows.
		]]
	local ss=path
	ss=os.path.expanduser(ss)
	ss=os.path.realpath(ss)
	return ss
 end
-- function str2chars(s)--convert string s to sequence of chars
-- 	local cc={}
-- 	s:gsub(".",function(c) table.insert(cc,c);end)
-- 	return cc
--  end
function chomp(line)
	local doc=[[Remove whitespace from the start of line.
		chomp(line)-->string,string

		returns whitespace,restofline
		]]
	if line==nil or line=="" then return "","";end
	local whitespace,restofline=string.match(line,"^(%s*)(.*)")
	whitespace=whitespace or ""
	restofline=restofline or ""
	return restofline,whitespace
 end
function swap(a,b)
	local doc=[[Swap 2 values.
		swap(a,b)-->b,a
		]]
	a,b=b,a;
	return a,b;
 end
function isalpha(s)
	local doc=[[True if s is only alphabetic chars.
		isaplha(s)-->bool
		]]
	return string.match(s,"%a*")
 end
function isdigit(s)
	local doc=[[True if s is only numeric chars.
		isdigit(s)-->bool
		]]
	return string.match(s,"%d*")
 end
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
--[[Main]]
local USAGE=[[Usage: lua stdlib.lua [OPTIONS]
Lulua Standard Library.

 Options:
	-h, --help       Print this message.
	-t, --test       Run tests.
	-d, --docs       Generate docs: stdlib.docs.txt
	-i, --info       Print some system info.
	]]
if MAIN() or sys.argv~=nil and sys.argv[2]=="LOVE2D" then
	local options,args=optionator(sys.argv)
	local DOCS,TEST
	if haskey(options,"h","help")    then
		print(USAGE)
		sys.exit()
	 end
	if haskey(options,"t","test")    then TEST=true 	end
	if haskey(options,"d","docs")    then DOCS=true 	end
	if haskey(options,"i","info")    then
		print("options:",options)
		print("args:",args)
		print("os: ", os.detect())
		print("stdlib vars:")
			local vars={}
			for k,v in pairs(_G) do
				if _GLOBALS[k]==nil then
					push(vars,k)
				 end
			 end
			vars=sort(vars)
			for _,v in ipairs(vars) do
				print("    ",v)
			 end
		print("package.preload:",package.preload)
		print("package.base:",	 package.base)
		print("package.path:",	 package.path)
		print("package.cpath:",	 package.cpath)
		print("package.config:split(\"\\n\"):", package.config:split("\n"))
	 end
	if haskey(options,"f","foo") then--how to check for argumented options.
		--[[haskey can check multiple keys at once.]]
		local foo=options.f or options.foo
		print("Found option -f:'%s',--foo='%s'" % {foo,foo})
		sys.exit()
	 end

	if TEST then
		local test=import("gambiarra.lua")

		local test_ALL=function()
			test("ALL",function()
				local cases={
					--arg	 expected
					{ {1,0,1},      false },--zero is false
					{ {"nope",""},  false },--empty string is false
					{ List(),       false },--empty List is false
					{ {},           false },--empty table is false
					{ {1,2,3},      true  },
				 }
				for _,cc in ipairs(cases) do
					local resulted=ALL( cc[1] )
					local expected=cc[2]
					ok(eq(resulted,expected))--use eq when comparing tables.
				 end
			 end)
		 end
		local test_ANY=function()
			test("ANY",function()
				local cases={
					--arg	 expected
					{ List(),       false },
					{ {},           false },
					{ {0},          false },
					{ {""},         false },
					{ {0,0,1},      true  },
					{ {"yup",""},   true  },
					{ {1},          true  },
					{ {1,2,3},      true  },
				 }
				for _,cc in ipairs(cases) do
					local resulted=ANY( cc[1] )
					local expected=cc[2]
					ok(eq(resulted,expected))--use eq when comparing tables.
				 end
			 end)
		 end
		local test_APPLY=function()
			test("APPLY",function()
				local function mul(a,b) return a*b;end
				local cases={
					--arg	 expected
					{ {2,2}, 4 },
					{ {2,3}, 6 },
					{ {2,4}, 8 },
				 }
				ok(eq(APPLY(math.sqrt,16),4))
				for _,cc in ipairs(cases) do
					local resulted=APPLY(mul,unpack(cc[1]) )
					local expected=cc[2]
					ok(eq(resulted,expected))--use eq when comparing tables.
				 end
			 end)
		 end
		local test_BOOL=function()
			test("BOOL",function()
				local cases={
					--arg	 expected
					{false,      false},
					{0,          false},
					{"",         false},
					{{},         false},
					{List(),     false},
					{{false},    true },
					{List(false),true },
					{1,          true },
					{true,       true },
					{"!",        true },
				 }
				ok(eq(BOOL(nil),false))--check nil
				for _,cc in ipairs(cases) do
					local resulted=BOOL(cc[1])
					local expected=cc[2]
					ok(eq(resulted,expected))--use eq when comparing tables.
				 end
			 end)
		 end
		local test_BSIEVE=function()
			test("BSIEVE",function()
				local function isODD(n) return intmod(n,2)~=0;end
				local cases={
					--arg	 expected
					{{1,2,3} ,{{1,3},{2} } },
					{{1}     ,{{1}  ,{ } } },
					{{8}     ,{{}   ,{8} } },
					{{}      ,{{}   ,{ } } },
				 }
				for _,cc in ipairs(cases) do
					local haves,havenots=BSIEVE(isODD,cc[1])
					local resulted={haves,havenots}
					local expected=cc[2]
					ok(eq(resulted,expected))--use eq when comparing tables.
				 end
			 end)
		 end
		local test_CALL=function()
			test("CALL",function()
				local function isODD(n) return intmod(n,2)~=0;end

				local resulted=CALL("nope",{3})
				local expected=nil
				ok(eq(resulted==nil,expected==nil),"nil if first arg is not a function.")

				local resulted=pcall(CALL(isODD,{"1"}))--should produce error
				local expected=false
				ok(eq(resulted,expected),"function called, should produce intentional error")

				local resulted=CALL(isODD,{1})
				local expected=true
				ok(eq(resulted,expected),"function call: OK")

				local resulted=CALL(isODD,{2})
				local expected=false
				ok(eq(resulted,expected),"function call: OK")

			 end)
		 end
		local test_CONCAT=function()
			test("CONCAT",function()
				local resulted,expected

				resulted={}
				for k,v in CONCAT({11},{22,33}) do
					resulted[#resulted+1]=v
				 end
				expected={11,22,33}
				ok(eq(resulted,expected),"CONCAT({11},{22,33})-->{11,22,33}")

				resulted={}
				for k,v in CONCAT({},{22,33}) do
					resulted[#resulted+1]=v
				 end
				expected={22,33}
				ok(eq(resulted,expected),"CONCAT({},{22,33})-->{22,33}")

				resulted={}
				for k,v in CONCAT({},{},{}) do
					resulted[#resulted+1]=v
				 end
				expected={}
				ok(eq(resulted,expected),"CONCAT({},{},{})-->{}")

				resulted={}
				for k,v in CONCAT({11,22,33}) do
					resulted[#resulted+1]=v
				 end
				expected={11,22,33}
				ok(eq(resulted,expected),"CONCAT({11,22,33})-->{11,22,33}")

			 end)
		 end
		local test_CURRY=function()
			test("CURRY",function()
				local resulted,expected

				function add(a,b)
					return a+b
				 end

				resulted=CURRY(add)(1)(2)
				expected=3
				ok(eq(resulted,expected),"CURRY(add)(1)(2)--> 3")

				resulted=CURRY(add)
				resulted=resulted(2^5)
				resulted=resulted(1)
				expected=33
				ok(eq(resulted,expected),"CURRY, args applied over 2 calls.")

			 end)
		 end
		local test_DEPTH=function()
			test("DEPTH",function()
				local resulted,expected

				local ss={}
				local f=function(x) ss[#ss+1]=x*2;end
				DEPTH(f,{11,22,{33,{44}},55} )
				resulted=ss
				expected={22,44,66,88,110}
				ok(eq(resulted,expected),"DEPTH first traversal.")

				local ss={}
				local f=function(x) ss[#ss+1]=x*2;end
				DEPTH(f,{})
				resulted=ss
				expected={}
				ok(eq(resulted,expected),"DEPTH first traversal,empty list.")

				local ss={}
				local f=function(x) ss[#ss+1]=x*2;end
				resulted=DEPTH(f,{11,22,{33,{44}},55})
				expected={11,22,{33,{44}},55}
				ok(eq(resulted,expected),"DEPTH: returns args unchanged")

			 end)
		 end
		local test_DYNAMIC=function()
			test("DYNAMIC",function()
				local resulted,expected

				resulted=DYNAMIC("print")()-->returns the current print function.
				expected=print
				ok(eq(resulted,expected) )

			 end)
		 end
		local test_FILTER=function()
			test("FILTER",function()
				local resulted,expected

				even=function(n) return n % 2 == 0;end
				resulted=FILTER(even, {1, 2, 3, 4, 5})
				expected={2,4}
				ok(eq(resulted,expected),"filter table")

				even=function(n) return n % 2 == 0;end
				resulted=FILTER(even, List{1, 2, 3, 4, 5})
				expected=List{2,4}
				ok(eq(type(resulted)=="List",true),"result is List if arg is List.")

				even=function(n) return n % 2 == 0;end
				resulted=FILTER(even,List{1, 2, 3, 4, 5})
				expected=List{2,4}
				local function list_equal(a,b)--compare only list parts of tables
					if len(a)~=len(b) then return false;end
					for i=1,#a do
						if a[i]~=b[i] then return false;end
					 end
					return true
				 end
				ok(eq(list_equal(resulted,expected),true),"filter List.")

			 end)
		 end
		local test_FLATTEN=function()
			test("FLATTEN",function()
				local resulted,expected

				resulted={}
				for k,v in FLATTEN({1,{2},{3,{4}},5}) do
					resulted[#resulted+1]=v
				 end
				expected={1,2,3,{4},5}
				ok(eq(resulted,expected) )

				resulted={}
				for k,v in FLATTEN({}) do
					resulted[#resulted+1]=v
				 end
				expected={}
				ok(eq(resulted,expected) )

			 end)
		 end
		local test_FULLINTERLEAVE=function()
			test("FULLINTERLEAVE",function()
				local resulted,expected

				local seq1 = {1,2,3,4}
				local seq2 = {'a','b'}
				placeholder='X'
				resulted=FULLINTERLEAVE(seq1,seq2,placeholder)
				expected={1,'a',2,'b',3,'X',4,'X'}
				ok(eq(resulted,expected),"placeholders generated.")

				local seq1 = {1,2,3,4}
				local seq2 = {'a','b','c','d'}
				placeholder='X'
				resulted=FULLINTERLEAVE(seq1,seq2,placeholder)
				expected={1,'a',2,'b',3,'c',4,'d'}
				ok(eq(resulted,expected),"same length sequences.")

				local seq2 = {1,2,3,4}
				local seq1 = List{'a','b'}
				placeholder='X'
				resulted=FULLINTERLEAVE(seq1,seq2,placeholder)
				expected={'a',1,'b',2,'X',3,'X',4}
				ok(eq(type(resulted),"List"),"produces List.")

			 end)
		 end
		local test_FULLZIP=function()
			test("FULLZIP",function()
				local resulted,expected

				local seq1 = {1,2,3,4}
				local seq2 = {'a','b'}
				placeholder='X'
				resulted=FULLZIP(seq1,seq2,placeholder)
				expected={{1,'a'},{2,'b'},{3,'X'},{4,'X'}}
				ok(eq(resulted,expected),"placeholders generated.")

				local seq1 = {1,2,3,4}
				local seq2 = {'a','b','c','d'}
				placeholder='X'
				resulted=FULLZIP(seq1,seq2,placeholder)
				expected={{1,'a'},{2,'b'},{3,'c'},{4,'d'}}
				ok(eq(resulted,expected),"same length sequences.")

				local seq1 = {1,2,3,4}
				local seq2 = List{'a','b'}
				placeholder='X'
				resulted=FULLZIP(seq1,seq2,placeholder)
				expected={{1,'a'},{2,'b'},{3,'X'},{4,'X'}}
				ok(eq(type(resulted),"List"),"produces List.")

			 end)
		 end
		local test_IARRAY=function()
			test("IARRAY",function()
				local resulted,expected

				resulted={}
				for k,v in IARRAY({[0]=11,22,33,44,55}) do
					resulted[#resulted+1]=v
				 end
				expected={11,22,33,44,55}
				ok(eq(resulted,expected),"iterate over array.")

				resulted={}
				for k,v in IARRAY({}) do
					resulted[#resulted+1]=v
				 end
				expected={}
				ok(eq(resulted,expected),"iterate over empty array.")

			 end)
		 end
		local test_IF=function()
			test("IF",function()
				local resulted,expected

				resulted=IF(true,"true","false")-->"true"
				expected="true"
				ok(eq(resulted,expected),'IF(true, "true","false")-->"true"')

				resulted=IF(false,"true","false")-->"false
				expected="false"
				ok(eq(resulted,expected),'IF(false,"true","false")-->"false')

			 end)
		 end
		local test_IFF=function()
			test("IFF",function()
				local resulted,expected
				local function f1() return "f1";end
				local function f2() return "f2";end

				resulted=IFF(true,f1,f2)-->"f1"
				expected="f1"
				ok(eq(resulted,expected),'IFF(true, f1,f2)-->"f1"')

				resulted=IFF(false,f1,f2)-->"f2"
				expected="f2"
				ok(eq(resulted,expected),'IFF(false,f1,f2)-->"f2"')

			 end)
		 end
		local test_INTERLEAVE=function()
			test("INTERLEAVE",function()
				local resulted,expected

				seq1 = {1,2,3}
				seq2 = {'a','b','c'}
				resulted=INTERLEAVE(seq1,seq2)
				expected={1,'a',2,'b',3,'c'}
				ok(eq(resulted,expected),"equal length sequences.")

				seq1 = {1,2}
				seq2 = {'a','b','c'}
				resulted=INTERLEAVE(seq1,seq2)
				expected={1,'a',2,'b'}
				ok(eq(resulted,expected),"seq1 shorter.")

				seq1 = {1,2,3}
				seq2 = {'a','b'}
				resulted=INTERLEAVE(seq1,seq2)
				expected={1,'a',2,'b'}
				ok(eq(resulted,expected),"seq2 shorter.")

				seq1 = {}
				seq2 = {'a','b','c'}
				resulted=INTERLEAVE(seq1,seq2)
				expected={}
				ok(eq(resulted,expected),"seq1 empty.")

				seq1 = {1,2,3}
				seq2 = {}
				resulted=INTERLEAVE(seq1,seq2)
				expected={}
				ok(eq(resulted,expected),"seq2 empty.")

				seq1 = {}
				seq2 = {}
				resulted=INTERLEAVE(seq1,seq2)
				expected={}
				ok(eq(resulted,expected),"all empty.")

				seq1 = {1,2,3}
				seq2 = List{'a','b','c'}
				resulted=INTERLEAVE(seq1,seq2)
				ok(eq(type(resulted)=="List",true),"result is List type.")

			 end)
		 end
		local test_IPAIRS=function()
			test("IPAIRS",function()
				local resulted,expected

				resulted={}
				for k,v in IPAIRS({11,22,33}) do
					resulted[k]=v
				 end
				expected={11,22,33}
				ok(eq(resulted,expected),"ipairs iterate.")

				resulted={}
				for k,v in IPAIRS({[0]=11,22,33}) do
					resulted[k]=v
				 end
				expected={22,33}
				ok(eq(resulted,expected),"zero index is excluded.")

			 end)
		 end
		local test_IRANGE=function()
			test("IRANGE",function()
				local resulted,expected

				resulted={}
				for i in IRANGE(3) do
					resulted[#resulted+1]=i
				 end
				expected={1,2,3}
				ok(eq(resulted,expected),"IRANGE(3)")

				resulted={}
				for i in IRANGE(11,15) do
					resulted[#resulted+1]=i
				 end
				expected={11,12,13,14,15}
				ok(eq(resulted,expected),"IRANGE(11,15)")

			 end)
		 end
		local test_IRANGE0=function()
			test("IRANGE0",function()
				local resulted,expected

				resulted={}
				for i in IRANGE0(3) do
					resulted[#resulted+1]=i
				 end
				expected={0,1,2}
				ok(eq(resulted,expected),"IRANGE0(3)")

				resulted={}
				for i in IRANGE0(10,15) do
					resulted[#resulted+1]=i
				 end
				expected={10,11,12,13,14}
				ok(eq(resulted,expected),"IRANGE0(10,15)")

			 end)
		 end
		local test_MAP=function()
			test("MAP",function()
				local resulted,expected
				function double(x) return x*2;end

				-- MAP(f,args)
				resulted=MAP(double,{11,22,33})
				expected={22,44,66}
				ok(eq(resulted,expected) )

				-- MAP{f,args}
				resulted=MAP{double,{11,22,33}}
				expected={22,44,66}
				ok(eq(resulted,expected) )

				-- MAP(f,args,iter)
				resulted=MAP(double,{[0]=11,22,33,44},pairs)
				expected={[0]=22,44,66,88}
				ok(eq(resulted,expected) )

				-- MAP{f,args,iter=pairs}--alternate syntax allows named arg.
				resulted=MAP{double,{[0]=11,22,33,44},iter=pairs}
				expected={[0]=22,44,66,88}
				ok(eq(resulted,expected) )

			 end)
		 end
		local test_MAX=function()
			test("MAX",function()
				local resulted,expected

				resulted=MAX({10,20,30})
				expected=30
				ok(eq(resulted,expected) )

				resulted=MAX({10,70,30})
				expected=70
				ok(eq(resulted,expected) )

				resulted=MAX({})
				expected=nil
				ok(eq(resulted,expected) )

			 end)
		 end
		local test_MIN=function()
			test("MIN",function()
				local resulted,expected

				resulted=MIN({10,20,30})
				expected=10
				ok(eq(resulted,expected) )

				resulted=MIN({10,5,30})
				expected=5
				ok(eq(resulted,expected) )

				resulted=MIN({})
				expected=nil
				ok(eq(resulted,expected) )

			 end)
		 end
		local test_NOT=function()
			test("NOT",function()
				local cases={
					--arg	 expected
					{false,      true},
					{0,          true},
					{"",         true},
					{{},         true},
					{List(),     true},
					{{false},    false },
					{List(false),false },
					{1,          false },
					{true,       false },
					{"!",        false },
				 }
				ok(eq(NOT(nil),true))--check nil
				for _,cc in ipairs(cases) do
					local resulted=NOT(cc[1])
					local expected=cc[2]
					ok(eq(resulted,expected))
				 end
			 end)
		 end
		local test_PARTIAL=function()
			test("PARTIAL",function()
				local resulted,expected
				local function add(a,b)
					return a+b
				 end

				local addten=PARTIAL(add,10)
				resulted=addten(20)
				expected=30
				ok(eq(resulted,expected) )

				local forty=PARTIAL(addten,30)
				resulted=forty()
				expected=40
				ok(eq(resulted,expected) )

				resulted=PARTIAL(addten,-20)()
				expected=-10
				ok(eq(resulted,expected) )

			 end)
		 end
		local test_PARTITION=function()
			test("PARTITION",function()

				local resulted,expected
				local function iscolon(c) return c==":";end

				resulted=PARTITION(iscolon,{1,2,3,':',4,5,6})
				expected={{1,2,3},{4,5,6}}
				ok(eq(resulted,expected) )

				resulted=PARTITION(iscolon,{1,2,3,4,5,6})
				expected={{1,2,3,4,5,6}}
				ok(eq(resulted,expected) )

				resulted=PARTITION(iscolon,{1,2,3,':',4,5,6},"keep")
				expected={{1,2,3},{':'},{4,5,6}}
				ok(eq(resulted,expected) )

				resulted=PARTITION(iscolon,{1,2,3,':',4,5,6},true)
				expected={{1,2,3},{':',4,5,6}}
				ok(eq(resulted,expected) )

				local odd=function(n)
					return n % 2 ~= 0
				 end
				local str2chars=function(s)--convert string s to sequence of chars
					local cc = {}
					s:gsub(".",function(c) table.insert(cc,c);end)
					return cc
				 end
				local cases={
					{{odd,{1,2,3,4,5}      },{{2},{4}}},
					{{odd,{1,2,3,4,5},true },{{1,2},{3,4},{5}}},
					{{odd,{1,2,3,4,5},"keep"},{{1},{2},{3},{4},{5}}},

					{{function(v) return v==":" end,
						str2chars("foo:bar:baz"),"keep"},
						{{"f","o","o"},{":"},{"b","a","r"},{":"},{"b","a","z"}}},

					{{function(v) return v==":" end,
						str2chars("a:b:c"),"keep"},
						{{"a"},{":"},{"b"},{":"},{"c"}}},
					{{function(v) return v==":" end,
						str2chars("a:b:c"),     },
						{{"a"},{"b"},{"c"}}},

					{{function(v) return v==":" end,
						str2chars(":b:c"),true},
						{{":","b"},{":","c"}}},
					{{function(v) return v==":" end,
						str2chars("a:b:"),true},
						{{"a"},{":","b"},{":"}}},

					{{function(v) return v==":" end,
						str2chars(":b:c"),"keep"},
						{{":"},{"b"},{":"},{"c"}}},
					{{function(v) return v==":" end,
						str2chars("a:b:"),"keep"},
						{{"a"},{":"},{"b"},{":"}}},

					{{function(v) return v==":" end,
						str2chars(":b:c"),     },
						{{"b"},{"c"}}},
					{{function(v) return v==":" end,
						str2chars("a:b:"),     },
						{{"a"},{"b"}}},
				 }
				for _, cc in ipairs(cases) do
					local args,expected=unpack(cc)
					local resulted=PARTITION(table.unpack(args))
					ok(eq(resulted,expected))
				 end
			 end)
		 end
		local test_REVERSE=function()
			test("REVERSE",function()
				local resulted,expected

				resulted={}
				for k,v in REVERSE({11,22,33}) do
					resulted[#resulted+1]=v
				 end
				expected={33,22,11}
				ok(eq(resulted,expected),"reverse iterate.")

				resulted={}
				for k,v in REVERSE({11}) do
					resulted[#resulted+1]=v
				 end
				expected={11}
				ok(eq(resulted,expected),"reverse iterate.")

				resulted={}
				for k,v in REVERSE({}) do
					resulted[#resulted+1]=v
				 end
				expected={}
				ok(eq(resulted,expected),"reverse iterate.")

			 end)
		 end
		local test_REVERSEARRAY=function()
			test("REVERSEARRAY",function()
				local resulted,expected

				resulted={}
				for k,v in REVERSEARRAY({[0]=11,22,33}) do
					resulted[#resulted+1]=v
				 end
				expected={33,22,11}
				ok(eq(resulted,expected),"reverse iterate.")

				resulted={}
				for k,v in REVERSEARRAY({[0]=11}) do
					resulted[#resulted+1]=v
				 end
				expected={11}
				ok(eq(resulted,expected),"reverse iterate.")

				resulted={}
				for k,v in REVERSEARRAY({}) do
					resulted[#resulted+1]=v
				 end
				expected={}
				ok(eq(resulted,expected),"reverse iterate.")

				resulted={}
				for k,v in REVERSEARRAY({[0]=1}) do
					resulted[#resulted+1]=v
				 end
				expected={1}
				ok(eq(resulted,expected),"reverse iterate.")

			 end)
		 end
		local test_SSET=function()
			test("SSET",function()
				local resulted,expected

				local e
				local var=true
				e,resulted=pcall(SSET,var)
				expected=var
				ok(eq(resulted,expected),"ok")

				--[[If called with var equal to nil,"",{},List()
					then it should fail and crash the program.

					I have commented out these tests because the
					test program will crash if the tests are
					successful.

					If SSET function is ever changed, you should
					run these tests manually.
					]]

				-- local e
				-- local var=nil
				-- e,resulted=pcall(SSET,var)--pcall doesn't help here.
				-- expected=var
				-- ok(eq(resulted,expected),"should crash the program with 'unset variable'")

				-- local e
				-- local var=""
				-- e,resulted=pcall(SSET,var)
				-- expected=var
				-- ok(eq(resulted,expected),"should crash the program with 'unset variable'")

				-- local e
				-- local var={}
				-- e,resulted=pcall(SSET,var)
				-- expected=var
				-- ok(eq(resulted,expected),"should crash the program with 'unset variable'")

				-- local e
				-- local var=List()
				-- e,resulted=pcall(SSET,var)
				-- expected=var
				-- ok(eq(resulted,expected),"should crash the program with 'unset variable'")

			 end)
		 end
		local test_SUM=function()
			test("SUM",function()
				local cases={
					--arg	 expected
					{{1, 2, 3, 4, 5},       15},
					{{10, 20, 30, 40, 50}, 150},
					{{},                     0},
				 }
				for _,cc in ipairs(cases) do
					local resulted=SUM(cc[1])
					local expected=cc[2]
					ok(eq(resulted,expected))
				 end
			 end)
		 end
		local test_UNROLL=function()
			test("UNROLL",function()
				local resulted,expected

				resulted={}
				for k,v in UNROLL({11,22,33}) do
					resulted[#resulted+1]=v
				 end
				expected={11,22,33}
				ok(eq(resulted,expected),"un-nested.")

				resulted={}
				for k,v in UNROLL({11,22,33,{44,{{55,66},77},88},99}) do
					resulted[#resulted+1]=v
				 end
				expected={11,22,33,44,55,66,77,88,99}
				ok(eq(resulted,expected),"deeply nested.")

				resulted={}
				for k,v in UNROLL({11}) do
					resulted[#resulted+1]=v
				 end
				expected={11}
				ok(eq(resulted,expected),"one item.")

				resulted={}
				for k,v in UNROLL({}) do
					resulted[#resulted+1]=v
				 end
				expected={}
				ok(eq(resulted,expected),"no items.")

			 end)
		 end
		local test_ZIP=function()
			test("ZIP",function()
				local resulted,expected

				local seq1 = {1,2,3,4}
				local seq2 = {'a','b'}
				resulted=ZIP(seq1,seq2)
				expected={{1,'a'},{2,'b'}}
				ok(eq(resulted,expected),"placeholders generated.")

				local seq1 = {1,2,3,4}
				local seq2 = {'a','b','c','d'}
				resulted=ZIP(seq1,seq2)
				expected={{1,'a'},{2,'b'},{3,'c'},{4,'d'}}
				ok(eq(resulted,expected),"same length sequences.")

				local seq1 = {1,2,3,4}
				local seq2 = List{'a','b'}
				resulted=ZIP(seq1,seq2)
				expected={{1,'a'},{2,'b'}}
				ok(eq(type(resulted),"List"),"produces List.")

			 end)
		 end
		local test_basename=function()
			test("basename",function()--shell style basename.
				local cases={
					--arg,expected
					{"",""},
					{"foo","foo"},
					{"foo.","foo."},
					{"foo.txt","foo.txt"},
					{"/foo.txt","foo.txt"},
					{"baz/foo.txt","foo.txt"},
					{"baz/foo/","foo"},
				 }
				for _,cc in ipairs(cases) do
					local resulted=basename(cc[1])
					local expected=cc[2]
					ok(eq(resulted,expected))--use eq when comparing tables.
				 end
			 end)
		 end
		local test_bin=function()
			test("bin",function()--shell style basename.
				local cases={
					--arg,expected
					{ 5,        "0b00000000000000000000000000000101"},
					{ 1,        "0b00000000000000000000000000000001"},
					{ 0,        "0b00000000000000000000000000000000"},
					{-1,        "0b11111111111111111111111111111111"},
					{ (2^31)-1, "0b01111111111111111111111111111111"},
					{-(2^31)+1, "0b10000000000000000000000000000001"},
				 }
				for _,cc in ipairs(cases) do
					local resulted=bin(cc[1])
					local expected=cc[2]
					ok(eq(resulted,expected))
				 end

				local resulted=bin(5,2)
				local expected="0b0000000000000101"
				ok(eq(resulted,expected),"16 bit.")

				local resulted=bin(5,1)
				local expected="0b00000101"
				ok(eq(resulted,expected),"8 bit.")

				local resulted=bin(5,8)
				local expected="0b0000000000000000000000000000000000000000000000000000000000000101"
				ok(eq(resulted,expected),"64 bit.")

				local resulted=bin( (2^53)-1,8)
				local expected="0b0000000000011111111111111111111111111111111111111111111111111111"
				ok(eq(resulted,expected),"64 bit. MAXINT")

				local resulted=bin( -(2^53)+1,8)
				local expected="0b1111111111100000000000000000000000000000000000000000000000000001"
				ok(eq(resulted,expected),"64 bit. MININT")

				local resulted=bin( -1,8)
				local expected="0b1111111111111111111111111111111111111111111111111111111111111111"
				ok(eq(resulted,expected),"64 bit. -1")

				local e,resulted=pcall(bin,2^53,8)
				ok(eq(e,false),"64 bit. Fail if greater than MAXINT.")
				--
				local e,resulted=pcall(bin,-2^53,8)
				ok(eq(e,false),"64 bit. Fail if less than MININT.")

				local e,resulted=pcall(bin,2^52,8,true)
				ok(eq(e,false),"64 bit. Fail if unsigned int greater than 2^52-1.")
				--
				local e,resulted=pcall(bin,-2^52,8,true)
				ok(eq(e,false),"64 bit. Fail if unsigned int less than -2^52+1.")

			 end)
		 end
		local test_bot=function()
			test("bot",function()
				local resulted,expected

				resulted=bot({11,22,33})
				expected=11
				ok(eq(resulted,expected),"returns item at bottom of stack.")

				resulted=bot({})
				expected=nil
				ok(eq(resulted,expected),"returns nil from empty stack.")

			 end)
		 end
		local test_callable=function()
			test("callable",function()
				local resulted,expected

				resulted=callable(print)
				expected=true
				ok(eq(resulted,expected),"functions are callable.")

				resulted=callable({})
				expected=false
				ok(eq(resulted,expected),"tables are not callable.")

				ex={}
				ex_mt={}
				function ex.new(foo)
					local self={}
					self.foo=foo
					return self
				 end
				ex_mt.__call=ex.new
				setmetatable(ex,ex_mt)

				resulted=callable(ex)
				expected=true
				ok(eq(resulted,expected),"callable objects use the __call metamethod.")

			 end)
		 end
		local test_checkbit=function()
			test("checkbit",function()
				local resulted,expected

				resulted=checkbit(5,1)
				expected=true
				ok(eq(resulted,expected),"bit 1 of 5 is set.")

				resulted=checkbit(5,2)
				expected=false
				ok(eq(resulted,expected),"bit 2 of 5 is not set.")

				resulted=checkbit(5,3)
				expected=true
				ok(eq(resulted,expected),"bit 3 of 5 is set.")

			 end)
		 end
		local test_chomp=function()
			test("chomp",function()
				local resulted,expected
				local r1,r2

				r1,r2=chomp(nil)
				resulted={r1,r2}
				expected={"",""}
				ok(eq(resulted,expected),"nil value.")

				r1,r2=chomp("")
				resulted={r1,r2}
				expected={"",""}
				ok(eq(resulted,expected),"empty string")

				r1,r2=chomp("chomp")
				resulted={r1,r2}
				expected={"chomp",""}
				ok(eq(resulted,expected),"chomp")

				r1,r2=chomp(" chomp")
				resulted={r1,r2}
				expected={"chomp"," "}
				ok(eq(resulted,expected)," chomp")

				r1,r2=chomp(" 	  chomp")
				resulted={r1,r2}
				expected={"chomp"," 	  "}
				ok(eq(resulted,expected)," 	  chomp")

			 end)
		 end
		local test_chr=function()
			test("chr",function()
				local resulted,expected

				resulted=chr(65)
				expected="A"
				ok(eq(resulted,expected),"A")

				resulted=chr(0)
				expected="\000"
				ok(eq(resulted,expected),"\\000")

			 end)
		 end
		local test_circle_back=function()
			test("circle_back",function()
				local resulted,expected

				seq={11,22,33}
				resulted={}
				pos=1
				for i=1,6 do
					resulted[#resulted+1]=seq[pos]
					pos=circle_back(pos,#seq)
				 end
				expected={11,22,33,11,22,33}
				ok(eq(resulted,expected),"twice through list.")

				seq={[0]=11,22,33}
				resulted={}
				pos=0
				for i=1,6 do
					resulted[#resulted+1]=seq[pos]
					pos=circle_back(pos,#seq+1,true)
				 end
				expected={11,22,33,11,22,33}
				ok(eq(resulted,expected),"twice through array.")

			 end)
		 end
		local test_clamp=function()
			test("clamp",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ { 2, 5,10}, 5,"return lower bound when value less than lower bound." },
					{ {20, 5,10},10,"return upper bound when value greater than upper bound."},
					{ { 7, 5,10}, 7,"return n when n is in bounds."},
					{ { 7,10, 5}, 7,"return n when n is in bounds. lower,upper swapped."},
				 }
				for _,cc in ipairs(cases) do
					local resulted=clamp( unpack(cc[1]) )
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_coalesce=function()
			test("coalesce",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ { [222]=44,[100]=55, [-2]=11 }, {11,44,55},"ok."},
					{ { [222]=44,[100]=11, [-2]=11 }, {11,11,44},"duplicate values: ok."},
				 }
				for _,cc in ipairs(cases) do
					local resulted=coalesce( cc[1] )--order is not preserved,
					resulted=sort(resulted)--so it must be sorted.
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

				resulted=List{[512]=11,[1024]=22,[256]=33}:coalesce()
				resulted=sort(resulted)--order is not preserved
				expected={11,22,33}
				ok(eq(resulted,expected),"as List method.")

			 end)
		 end
		local test_cons=function()
			test("cons",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ {2,5}            ,{2,5}        ,"2,5          -->{2,5}." },
					{ {{1,2},5}        ,{1,2,5}      ,"{1,2},5      -->{1,2,5}." },
					{ {{1,2,3},{4,5}}  ,{1,2,3,4,5}  ,"{1,2,3},{4,5}-->{1,2,3,4,5}." },
					{ {nil}            ,{}           ,"nil          -->{}" },
					{ {4}              ,{4}          ,"4            -->{4}" },
				 }
				for _,cc in ipairs(cases) do
					local resulted=cons( unpack(cc[1]) )
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_copy=function()
			test("copy",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ {2,5}   ,"shallow copy"  ,"shallow copy." },
					{ {"foo"} ,"shallow copy"  ,"shallow copy." },

				 }
				for _,cc in ipairs(cases) do
					local resulted=copy( cc[1] )
					local expected=cc[1]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_deepcopy=function()
			test("deepcopy",function()
				local resulted,expected

				ex={}
				ex_mt={}
				function ex.new(foo)
					local self={}
					self.foo=foo
					self.bar=22
					return self
				 end
				ex_mt.__call=ex.new
				setmetatable(ex,ex_mt)

				local resulted=deepcopy(ex)()
				local expected=ex()
				ok(eq(resulted.new==expected.new,true),"metatable is copied.")
				ok(getmetatable(ex)~=getmetatable(deepcopy(ex)),"copied metatables are unique.")
				ok(eq(resulted.bar==expected.bar,true),"values are copied.")
				ok(eq(resulted==expected,false),"objects are different.")

			 end)
		 end
		local test_def=function()
			test("def",function()
				local resulted,expected

				resulted=def(22)--it just returns its arg.
				expected=22
				ok(eq(resulted,expected),"ok.")

			 end)
		 end
		local test_delattr=function()
			test("delattr",function()
				local resulted,expected

				resulted={}
				resulted.bar=22

				delattr(resulted,"bar")
				expected=nil
				ok(eq(resulted.bar,expected),"ok.")

			 end)
		 end
		local test_exec=function()
			test("exec",function()
				local resulted,expected

				i=1
				exec("i=i+1;")--executes into global namespace.
				resulted=i;i=nil
				expected=2
				ok(eq(resulted,expected),"ok.")

			 end)
		 end
		local test_extend=function()
			test("extend",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ { {},{2,5} }    ,{2,5}     ,"ok." },
					{ { {11},{2,5} }  ,{11,2,5}  ,"ok." },
				 }
				for _,cc in ipairs(cases) do
					local resulted=extend(unpack(cc[1]))
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_ezpath=function()
			test("ezpath",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ "~/"  ,"/home/you"  ,"path must exist." },
				 }
				for _,cc in ipairs(cases) do
					local resulted=ezpath(cc[1])
					local expected=cc[2]
					local descript=cc[3]
					ok(resulted,resulted)--
				 end

			 end)
		 end
		local test_flatten=function()
			test("flatten",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ {1,{2,3},4}    ,{1,2,3,4}    ,"{1,{2,3},4}  -->{1,2,3,4}" },
					{ {1,{2,{3}},4}  ,{1,2,{3},4}  ,"{1,{2,{3}},4}-->{1,2,{3},4}" },
				 }
				for _,cc in ipairs(cases) do
					local resulted=flatten(cc[1])
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_float=function()
			test("float",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ float() ,0    ,"float()-->0"   },
					{ 1       ,1    ,"1"   },
					{ 2.7     ,2.7  ,"2.7" },
					{ "3.14"  ,3.14 ,"3.14"},
				 }
				for _,cc in ipairs(cases) do
					local resulted=float(cc[1])
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_getattr=function()
			test("getattr",function()
				local resulted,expected

				local foo={}
				foo.bar=11
				foo.baz=22

				local cases={
					--arg	 expected
					{ {foo,"bar"}       ,11     ,"attribute 'foo'"   },
					{ {foo,"baz"}       ,22     ,"attribute 'bar'"   },
					{ {foo,"boo",false} ,false  ,"supply default value for missing atrribute."   },
				 }
				for _,cc in ipairs(cases) do
					local resulted=getattr( unpack(cc[1]) )
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_getext=function()
			test("getext",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ {"/foo/bar/baz.txt"}   ,".txt"  ,".txt"  },
					{ {"/foo/bar/baz"}       ,""      ,"no ext"  },
					{ {"foo.jpeg"}           ,".jpeg" ,".jpeg"  },
					{ {"foo."}               ,"."     ,"."  },
					{ {"C:\\Settings\\foo.txt","\\"} ,".txt",".txt"  },--path sep
					{ {"C:\\Settings\\foo.txt"} ,".txt"     ,".txt"  },--no path sep
				 }
				for _,cc in ipairs(cases) do
					local resulted=getext( unpack(cc[1]) )
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_glob=function()
			test("glob",function()
				local resulted,expected

				local cases={
					-- { {"*"}     },
					{ {"*.lua"} },
				 }
				for _,cc in ipairs(cases) do
					local resulted=glob( unpack(cc[1]) )
					local descript=str(resulted)
					ok(eq(type(resulted)=="table",true),descript)
				 end

			 end)
		 end
		local test_globals=function()
			test("globals",function()
				local resulted=globals()
				ok(eq(type(resulted)=="table",true),"returns a table: ok.")
				ok(eq(resulted,_G),"returns _G: ok.")
			 end)
		 end
		local test_has=function()
			test("has",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ {{11,22,33},22}    ,true    ,"has 22"  },
					{ {{11,22,33},88}    ,false   ,"doesn't have 88"  },
					{ {{11,22,33},22,11} ,true    ,"has 22,11"  },
					{ {{11,22,33},22,11,88} ,true ,"has 22,11,but not 88."  },
				 }
				for _,cc in ipairs(cases) do
					local resulted=has( unpack(cc[1]) )
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_hasattr=function()
			test("hasattr",function()
				local resulted,expected

				local foo={}
				foo.bar=22

				local cases={
					--arg	 expected
					{ {foo,"bar"}    ,true    ,"has bar."  },
					{ {foo,"baz"}    ,false   ,"doesn't have baz."  },
				 }
				for _,cc in ipairs(cases) do
					local resulted=hasattr( unpack(cc[1]) )
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_haskey=function()
			test("haskey",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ {{["foo"]=11,22,33},"foo"}    ,true    ,"has foo."  },
					{ {{["foo"]=11,22,33},"bar"}    ,false   ,"doesn't have bar."  },
					{ {{["foo"]=11,22,33},   88}    ,false   ,"doesn't have 88."  },
					{ {{["foo"]=11,22,33},    2}    ,true    ,"has 2."  },

				 }
				for _,cc in ipairs(cases) do
					local resulted=haskey( unpack(cc[1]) )
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_hex=function()
			test("hex",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ {15}   ,"0xF"   ,"0xF"  },
					{ {1}    ,"0x1"   ,"0x1"  },
					{ {16}   ,"0x10"  ,"0x10" },
				 }
				for _,cc in ipairs(cases) do
					local resulted=hex( unpack(cc[1]) )
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_indent=function()
			test("indent",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ {"foo",0}   ,"foo"           ,"0 levels."  },
					{ {"foo",1}   ,"    foo"       ,"1 level."   },
					{ {"foo",2}   ,"        foo"   ,"2 levels."  },
				 }
				for _,cc in ipairs(cases) do
					local resulted=indent( unpack(cc[1]) )
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_int=function()
			test("int",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ int() ,0    ,"int()-->0"   },
					{ 1       ,1    ,"1-->1"   },
					{ 2.7     ,2  ,"2.7-->2" },
					{ "3.14"  ,3 ,"'3.14'-->3"},
				 }
				for _,cc in ipairs(cases) do
					local resulted=int(cc[1])
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_intmod=function()
			test("intmod",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ {10,2} ,0    ,"{10,2} ,0"   },
					{ {10,3} ,1    ,"{10,3} ,1"   },
					{ {2 ,3} ,2    ,"{2 ,3} ,2"   },
				 }
				for _,cc in ipairs(cases) do
					local resulted=intmod( unpack(cc[1]) )
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_keys=function()
			test("keys",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ {11,22,33} ,{1,2,3}    ,"1,2,3"   },
					{ {["foo"]=11,22,33} ,{1,2,"foo"}    ,"1,2,'foo'"   },
				 }
				for _,cc in ipairs(cases) do
					local resulted=keys( cc[1] )
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_len=function()
			test("len",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ {11,22,33}             ,3  ,"3"  },
					{ {11,22,33,["four"]=44} ,4  ,"4"  },
					{ {}                     ,0  ,"0"  },
					{ {["one"]=11}           ,1  ,"1"  },
				 }
				for _,cc in ipairs(cases) do
					local resulted=len( cc[1] )
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_locals=function()
			test("locals",function()
				local resulted,expected

				local s="hello"

				local resulted=locals()
				local expected={["s"]="hello"}
				local descript="returns a table of local vars."
				ok(eq(resulted,expected),descript)

			 end)
		 end
		local test_merge=function()
			test("merge",function()
				local resulted,expected

				local src={bar=33}
				local dst={foo=22}
				local resulted=merge(src,dst)
				local expected={foo=22,bar=33}
				local descript="copy merge."
				ok(eq(resulted,expected),descript)

				local src={bar=33,foo=55}
				local dst={foo=22}
				local resulted=merge(src,dst)
				local expected={foo=55,bar=33}
				local descript="update merge."
				ok(eq(resulted,expected),descript)

			 end)
		 end
		local test_method=function()
			test("method",function()
				local resulted,expected

				local foo={}
				foo.bar=42
				foo.baz=function(self)
					return self.bar
				 end

				local resulted=method("baz",foo)
				local expected=42
				local descript="call object method"
				ok(eq(resulted,expected),descript)

				local foo={}
				foo.bar=42
				foo.baz=function(self,b)
					return self.bar+b
				 end

				local resulted=method("baz",foo,4)
				local expected=46
				local descript="call object method with additional arg"
				ok(eq(resulted,expected),descript)

			 end)
		 end
		local test_methodist=function()
			test("methodist",function()
				local resulted,expected

				local foo={}
				foo.bar=42

				local ftab={
					["baz"]=function(self)
						return self.bar
					 end
				 }

				methodist(foo,ftab)

				local resulted=foo:baz()
				local expected=42
				local descript="call object method"
				ok(eq(resulted,expected),descript)

			 end)
		 end
		local test_oct=function()
			test("oct",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ {5}   ,"0o5"   ,"0oF"  },
					{ {1}   ,"0o1"   ,"0o1"  },
					{ {8}   ,"0o10"  ,"0o10" },
				 }
				for _,cc in ipairs(cases) do
					local resulted=oct( unpack(cc[1]) )
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_ord=function()
			test("ord",function()
				local resulted,expected

				resulted=ord("A")
				expected=65
				ok(eq(resulted,expected),"A-->65")

				resulted=ord("\000")
				expected=0
				ok(eq(resulted,expected),"\\000-->0")

			 end)
		 end
		local test_pop=function()
			test("pop",function()
				local resulted,expected

				local foo={11,22,33}
				local resulted=pop(foo)
				local expected=33
				local descript="pop({11,22,33}-->33)"
				ok(eq(resulted,expected),descript)
				ok(eq(foo,{11,22}),"verify item removed.")

				local foo={}
				local resulted=pop(foo)
				local expected=nil
				local descript="pop({}-->nil)"
				ok(eq(resulted,expected),descript)

			 end)
		 end
		local test_popleft=function()
			test("popleft",function()
				local resulted,expected

				local foo={11,22,33}
				local resulted=popleft(foo)
				local expected=11
				local descript="popleft({11,22,33}-->11)"
				ok(eq(resulted,expected),descript)
				ok(eq(foo,{22,33}),"verify item removed.")

				local foo={}
				local resulted=popleft(foo)
				local expected=nil
				local descript="popleft({}-->nil)"
				ok(eq(resulted,expected),descript)

			 end)
		 end
		local test_pow=function()
			test("pow",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ {2,5} ,32   ,"2^5-->32"   },
					{ {2,1} ,2    ,"2^1-->2"   },
					{ {2,0} ,1    ,"2^0-->1"   },
				 }
				for _,cc in ipairs(cases) do
					local resulted=pow( unpack(cc[1]) )
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_push=function()
			test("push",function()
				local resulted,expected

				local foo={11,22}
				local resulted=push(foo,33)
				local expected={11,22,33}
				local descript="push value."
				ok(eq(resulted,expected),descript)

				local foo={}
				local resulted=push(foo,11)
				local expected={11}
				local descript="push value into empty table."
				ok(eq(resulted,expected),descript)

			 end)
		 end
		local test_pushleft=function()
			test("pushleft",function()
				local resulted,expected

				local foo={11,22}
				local resulted=pushleft(foo,33)
				local expected={33,11,22}
				local descript="push value."
				ok(eq(resulted,expected),descript)

				local foo={}
				local resulted=pushleft(foo,11)
				local expected={11}
				local descript="push value into empty table."
				ok(eq(resulted,expected),descript)

			 end)
		 end
		local test_range=function()
			test("range",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ {3} ,{1,2,3}    ,"1,2,3"   },
					{ {5,9} ,{5,6,7,8,9}    ,"5,6,7,8,9"   },
				 }
				for _,cc in ipairs(cases) do
					local resulted=range( unpack(cc[1]) )
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_range0=function()
			test("range0",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ {3} ,{0,1,2}    ,"0,1,2"   },
					{ {5,10} ,{5,6,7,8,9}    ,"5,6,7,8,9"   },
				 }
				for _,cc in ipairs(cases) do
					local resulted=range0( unpack(cc[1]) )
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_repr=function()
			test("repr",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ {3}       ,"3"          ,"3"  },
					{ {"foo"}   ,"\"foo\""    ,"a string."  },
					{ {{}}      ,"{}"         ,"a table"  },
				 }
				for _,cc in ipairs(cases) do
					local resulted=repr( unpack(cc[1]) )
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_round=function()
			test("round",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ {2.5} ,3,"3"  },
					{ {0.3} ,0,"0"  },
					{ {-1.5} ,-2,"-2"  },
					{ {3.14159,2} ,3.14,"3.14"  },
				 }
				for _,cc in ipairs(cases) do
					local resulted=round( unpack(cc[1]) )
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_setattr=function()
			test("setattr",function()
				local resulted,expected

				local foo={}
				foo.bar=22

				local cases={
					--arg	 expected
					{ {foo,"bar",42}    ,42    ,"set bar."  },
					{ {foo,"bar",nil}   ,nil   ,"unset bar."  },
				 }
				for _,cc in ipairs(cases) do
					setattr( unpack(cc[1]) )
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(foo.bar,expected),descript)
				 end

			 end)
		 end
		local test_setbit=function()
			test("setbit",function()
				local resulted,expected

				resulted=setbit(0,1)
				expected=1
				ok(eq(resulted,expected),"bit 1 is set.")

				resulted=setbit(1,3)
				expected=5
				ok(eq(resulted,expected),"bit 3 is set.")

				resulted=setbit(5,2)
				expected=7
				ok(eq(resulted,expected),"bit 2 is set.")

			 end)
		 end
		local test_setbits=function()
			test("setbits",function()
				local resulted,expected

				resulted=setbits(3,1)
				expected=5
				ok(eq(resulted,expected),"5")

				resulted=setbits(1,2,3)
				expected=7
				ok(eq(resulted,expected),"7")

				resulted=setbits(1,4,5,6,9,11)
				expected=1337
				ok(eq(resulted,expected),"1337")

			 end)
		 end
		local test_settype=function()
			test("settype",function()
				local resulted,expected

				local foo={}
				settype(foo,"epic_type")
				resulted=type(foo)
				expected="epic_type"
				ok(eq(resulted,expected),"make a new type.")

			 end)
		 end
		local test_slice=function()
			test("slice",function()
				local resulted,expected

				local foo={11,22,33,44,55,66}

				local cases={
					--arg	 expected
					{ {foo,1,3}  ,{11,22,33}  ,"slice."  },
					{ {foo,2,4}  ,{22,33,44}  ,"slice."  },
					{ {foo,1,5,2},{11,33,55}  ,"uses step."  },
					{ {foo,1,6,2},{11,33,55}  ,"uses step."  },
				 }
				for _,cc in ipairs(cases) do
					local resulted=slice( unpack(cc[1]) )
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_sort=function()
			test("sort",function()
				local resulted,expected

				local foo={5,3,4,6,8,1}

				local cases={
					--arg	 expected
					{ {foo}  ,{1,3,4,5,6,8}  ,"sort."  },
					{ {{3,2,1}}  ,{1,2,3}  ,"1,2,3"  },
				 }
				for _,cc in ipairs(cases) do
					local resulted=sort( unpack(cc[1]) )
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_sprintf=function()
			test("sprintf",function()
				local resulted,expected

				local foo={5,3,4,6,8,1}

				local cases={
					--arg	 expected
					{ {"%d",42}  ,"42"  ,""  },
					{ {"%i",42}  ,"42"  ,""  },
					{ {"%o",42}  ,"52"  ,""  },
					{ {"%x",42}  ,"2a"  ,""  },
					{ {"%X",42}  ,"2A"  ,""  },
				 }
				for _,cc in ipairs(cases) do
					local resulted=sprintf( unpack(cc[1]) )
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_top=function()
			test("top",function()
				local resulted,expected

				local foo={11,22,33}
				local resulted=top(foo)
				local expected=33
				local descript="top({11,22,33}-->33)"
				ok(eq(resulted,expected),descript)

			 end)
		 end
		local test_uniq=function()
			test("uniq",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ {1,1,1,2}  ,{1,2}  ,"like unix uniq."  },
					{ {1,1,1,2,1,1}  ,{1,2,1}  ,"expects sorted data."  },
				 }
				for _,cc in ipairs(cases) do
					local resulted=uniq( cc[1] )
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_unroll=function()
			test("unroll",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ {11,22,33}  ,{11,22,33}  ,"un-nested."  },
					{ {11,22,33,{44,{{55,66},77},88},99}  ,{11,22,33,44,55,66,77,88,99}  ,"deeply nested."  },
					{ {11}  ,{11}  ,"one item."  },
					{ {}  ,{}  ,"no items."  },
				 }
				for _,cc in ipairs(cases) do
					local resulted=unroll( cc[1] )
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_unsetbit=function()
			test("unsetbit",function()
				local resulted,expected

				resulted=unsetbit(1,1)
				expected=0
				ok(eq(resulted,expected),"bit 1 unset.")

				resulted=unsetbit(5,3)
				expected=1
				ok(eq(resulted,expected),"bit 3 unset.")

				resulted=unsetbit(7,2)
				expected=5
				ok(eq(resulted,expected),"bit 2 unset.")

			 end)
		 end
		local test_values=function()
			test("values",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ {11,22,33} ,{11,22,33}          ,"11,22,33"  },
					{ {["foo"]=11,22,33} ,{22,33,11}  ,"11,22,33"  },
				 }
				for _,cc in ipairs(cases) do
					local resulted=values( cc[1] )
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_os_path_basename=function()
			test("os.path.basename",function()
				local cases={
					--arg,expected
					{"",""},
					{"foo","foo"},
					{"foo.","foo."},
					{"foo.txt","foo.txt"},
					{"/foo.txt","foo.txt"},
					{"baz/foo.txt","foo.txt"},
					{"baz/foo/",""},
				 }
				for _,cc in ipairs(cases) do
					local resulted=os.path.basename(cc[1])
					local expected=cc[2]
					ok(eq(resulted,expected))--use eq when comparing tables.
				 end
			 end)
		 end
		local test_os_path_dirname=function()
			test("os.path.dirname",function()
				local cases={
					--arg,expected
					{"",""},
					{"foo",""},
					{"/foo.txt","/"},
					{"baz/foo.txt","baz"},
					{"baz/foo/","baz/foo"},
				 }
				for _,cc in ipairs(cases) do
					local resulted=os.path.dirname(cc[1])
					local expected=cc[2]
					ok(eq(resulted,expected))
				 end
			 end)
		 end
		local test_os_path_expanduser=function()
			test("os.path.expanduser",function()
				local cases={
					--arg,expected
					-- {"~susan","/home/susan","linux"},
					-- {"~/docs","/home/vic/docs","path must exist."},
				 }
				for _,cc in ipairs(cases) do
					local resulted=os.path.expanduser(cc[1])
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end
			 end)
		 end
		local test_os_path_getsize=function()
			test("os.path.getsize",function()
				local cases={
					--arg,expected,descript
					-- {"/home/vic/.bashrc",9001,"file must exist."},
				 }
				for _,cc in ipairs(cases) do
					local resulted=os.path.getsize(cc[1])
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end
			 end)
		 end
		local test_os_path_isfile=function()
			test("os.path.isfile",function()
				local cases={
					-- arg          expected
					{"./README.MD",    true},
					{"README.MD",      true},
					{"./flyingpig.txt",false},
					{"./",             false},--directory is not a file
					{"/dev/null",      false},--special file, not a regular file
				 }
				for _, cc in ipairs(cases) do
					local path, expected = unpack(cc)
					local resulted=os.path.isfile(os.path.realpath(path))
					ok(eq(resulted,expected))
				 end
			 end)
		 end
		local test_os_path_join=function()
			test("os.path.join",function()
				local cases={
					--arg		expected
					{{""},			""},
					{{"",""},		""},
					{{"","",""},	""},

					{{"","","/"},	"/"},
					{{"","/",""},	"/"},
					{{"","/","/"},	"/"},
					{{"/","",""},	"/"},
					{{"/","","/"},	"/"},
					{{"","/","/"},	"/"},
					{{"/","",""},	"/"},
					{{"/","","/"},	"/"},
					{{"/","/",""},	"/"},
					{{"/","/","/"},	"/"},

					{{"/","foo"}	,"/foo"},
					{{"/foo/","bar"},"/foo/bar"},
					{{"/foo/","bar/"},"/foo/bar/"},
					{{"/foo/","/bar/"},"/foo/bar/"},
					{{"foo/","bar"},"foo/bar"},
				 }
				for _,cc in ipairs(cases) do
					--test os.path.join({a,b})
					local resulted=os.path.join(cc[1])
					local expected=cc[2]
					ok(eq(resulted,expected))--use eq when comparing tables.

					--test os.path.join(a,b)
					local resulted=os.path.join(table.unpack(cc[1]))
					local expected=cc[2]
					ok(eq(resulted,expected))--use eq when comparing tables.
				 end
			 end)
		 end
		local test_os_path_split=function()
			test("os.path.split",function()
				local cases={
					--arg	 expected
					{"/"	,{"/"	,""		}},
					{"foo"	,{""	,"foo"	}},
					{"foo/"	,{"foo"	,""		}},
					{"/foo"	,{"/"	,"foo"	}},
				 }
				for _,cc in ipairs(cases) do
					--Putting your resulted,expected into
					--variables makes sense and is easy to read.
					--this syntax works:
					local resulted=table.pack(os.path.split(cc[1]))
					local expected=cc[2]
					ok(eq(resulted,expected))--use eq when comparing tables.
				 end
			 end)
		 end
		local test_os_path_splitext=function()
			test("os.path.splitext",function()
				local cases={
					--arg			expected
					{""				,{""			,""}},
					{"foo"			,{"foo"			,""}},
					{"foo.txt"	,	{"foo"			,".txt"}},
					{"foo.tar.gz"	,{"foo.tar"		,".gz"}},
					{"foo.bar/baz"	,{"foo.bar/baz"	,""}},
					{"foo/bar/baz"	,{"foo/bar/baz"	,""}},
					{"foo/ba.r/baz"	,{"foo/ba.r/baz",""}},
					{"foo/bar/b.az"	,{"foo/bar/b"	,".az"}},
					{"/foo/bar/baz"	,{"/foo/bar/baz",""}},
					{"foo/bar/baz"	,{"foo/bar/baz"	,""}},
					{"foo/bar/baz."	,{"foo/bar/baz"	,"."}},
					{"/"			,{"/"			,""}},
					{"."			,{""			,"."}},
				 }
				for _,cc in ipairs(cases) do
					local resulted=table.pack(os.path.splitext(cc[1]))
					local expected=cc[2]
					ok(eq(resulted,expected))--use eq when comparing tables.
				 end
			 end)
		 end
		local test_table_slice=function()
			test("table.slice",function()
			-- function slice(tbl,first,last,step)--pythonic slice
				local tbl={11,22,33,44,55}
				local cases={ --not zero based, because lua.
					{ {tbl,1,1 }, {11}    },
					{ {tbl,2,1 }, {nil}   },
					{ {tbl,2,2 }, {22}    },
					{ {tbl,2,3 }, {22,33} },
					{ {tbl,1, },  tbl     },
				 }
				for _,cc in ipairs(cases) do
					local args,expected=unpack(cc)
					local resulted=table.slice(table.unpack(args))
					ok(eq(resulted,expected))
				 end
			 end)
		 end
		local test_table_is_empty=function()
			test("table.is_empty",function()
				local foo={}
				local resulted=table.is_empty(foo)
				ok(eq(resulted,true))

				local foo={["bar"]=22}
				local resulted=table.is_empty(foo)
				ok(eq(resulted,false))
			 end)
		 end
		local test_table_is_blank=function()
			test("table.is_blank",function()
				local foo={}
				local resulted=table.is_blank(foo)
				ok(eq(resulted,true))

				local foo={""," ","	"}
				local resulted=table.is_blank(foo)
				ok(eq(resulted,true))

				local foo={["bar"]=22}
				local resulted=table.is_blank(foo)
				ok(eq(resulted,false))

				local foo={["bar"]=" "}
				local resulted=table.is_blank(foo)
				ok(eq(resulted,true))
			 end)
		 end
		local test_string_trim=function()
			test("string.trim",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ "	foo " ,"foo" ,"trim leading and trailing ws."  },
					{ "	foo \n" ,"foo" ,"trim leading and trailing ws."  },
				 }
				for _,cc in ipairs(cases) do
					local resulted=cc[1]:trim()
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_string_ltrim=function()
			test("string.ltrim",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ "	foo " ,"foo " ,"trim leading ws."  },
					{ "	foo \n" ,"foo \n" ,"trim leading ws."  },
				 }
				for _,cc in ipairs(cases) do
					local resulted=cc[1]:ltrim()
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_string_rtrim=function()
			test("string.rtrim",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ "	foo " ,"	foo" ,"trim trailing ws."  },
					{ "	foo \n" ,"	foo" ,"trim trailing ws."  },
				 }
				for _,cc in ipairs(cases) do
					local resulted=cc[1]:rtrim()
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_string_trimall=function()
			test("string.trimall",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ "	f o o " ,"foo" ,"trim all ws."  },
					{ "	f oo \n" ,"foo" ,"trim all ws."  },
				 }
				for _,cc in ipairs(cases) do
					local resulted=cc[1]:trimall()
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_string_split=function()
			test("string.split",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ {"foo bar"} ,{"foo","bar"} ,"split"  },
					{ {"foo/bar","/"} ,{"foo","bar"} ,"split"  },
				 }
				for _,cc in ipairs(cases) do
					local resulted=cc[1][1]:split(cc[1][2])
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_string_join=function()
			test("string.join",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ {"/",{"foo","bar"} } ,"foo/bar" ,"join"  },
					{ {".",{"foo","bar"} } ,"foo.bar" ,"join"  },
				 }
				for _,cc in ipairs(cases) do
					local resulted=cc[1][1]:join(cc[1][2])
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_string_slice=function()
			test("string.slice",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ {"foobar",1,3 } ,"foo" ,"slice" },
					{ {"foobar",4,7 } ,"bar" ,"slice" },
				 }
				for _,cc in ipairs(cases) do
					local resulted=cc[1][1]:slice(cc[1][2],cc[1][3])
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_string_startswith=function()
			test("string.startswith",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ {"foobar","f"}    ,true  ,"startswith f" },
					{ {"foobar","foo" } ,true  ,"startswith foo" },
					{ {"foobar","bar" } ,false ,"doesn't start with bar." },
				 }
				for _,cc in ipairs(cases) do
					local resulted=cc[1][1]:startswith(cc[1][2])
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_swap=function()
			test("swap",function()
				local a=1
				local b=2
				local a,b=swap(a,b)
				local expected={2,1}
				ok(eq({a,b},expected),"a,b-->b,a")
			 end)
		 end
		local test_Enum=function()
			test("Enum",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ {"foo","bar"} ,{["foo"]=1,["bar"]=2} ,"a simple enum."},
					{ {} ,{} ,"empty enum, which is allowed, but doesn't make sense." },
				 }
				for _,cc in ipairs(cases) do
					local resulted=Enum(unpack(cc[1]))
					local expected=cc[2]
					local descript=cc[3]
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_List=function()
			test("List",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ { {42,s=3} } ,List{42,42,42} ,"List from {} args."},
					{ { 11,22,33 } ,{11,22,33} ,"List from args."},
				 }
				for _,cc in ipairs(cases) do
					local resulted=List(unpack(cc[1]))
					local expected=cc[2]
					local descript=cc[3]

					--convert to tables for comparision.
					resulted=clone(resulted)
					expected=clone(expected)

					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		local test_Array=function()
			test("Array",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{  3              ,{[0]=0,0,0}    ,"Array from args."},
					{ {3}             ,{[0]=0,0,0}    ,"Array from {args}."},
					{ {s=3}           ,{[0]=0,0,0}    ,"Array from {args}."},
					{ {size=3}        ,{[0]=0,0,0}    ,"Array from {args}."},
					{ {3,default=42 } ,{[0]=42,42,42} ,"Array from {args}."},
					{ {3,1}           ,{[0]=1,1,1}    ,"Array from {args}."},
				 }
				for _,cc in ipairs(cases) do
					local resulted=Array( cc[1] )
					local expected=cc[2]
					local descript=cc[3]
					--convert to table for comparision:
					resulted=cloneiter(resulted:iter())
					ok(eq(resulted,expected),descript)
				 end

				--test multiple args directly:
				local resulted=Array(3,1)
				local expected={[0]=1,1,1}
				resulted=cloneiter(resulted:iter())
				ok(eq(resulted,expected),"Array from multiple args.")

			 end)
		 end
		local test_Deque=function()
			test("Deque",function()
				local resulted,expected

				local cases={
					--arg	 expected
					{ {33,22,11}  ,{[0]=33,22,11}    ,"Deque from args."},
					{ {44}        ,{[0]=44}          ,"Deque from args."},
				 }
				for _,cc in ipairs(cases) do
					local resulted=Deque(cc[1] )
					local expected=cc[2]
					local descript=cc[3]
					--convert to table for comparision:
					resulted=cloneiter(resulted:iter())
					ok(eq(resulted,expected),descript)
				 end

			 end)
		 end
		--
		local tests={
			test_ALL,
			test_ANY,
			test_APPLY,
			test_BOOL,
			test_BSIEVE,
			test_CALL,
			test_CONCAT,
			test_CURRY,
			test_DEPTH,
			test_DYNAMIC,
			test_FILTER,
			test_FLATTEN,
			test_FULLINTERLEAVE,
			test_FULLZIP,
			test_IARRAY,
			test_IF,
			test_IFF,
			test_INTERLEAVE,
			test_IPAIRS,
			test_IRANGE,
			test_IRANGE0,
			test_MAP,
			test_MAX,
			test_MIN,
			test_NOT,
			test_PARTIAL,
			test_PARTITION,
			test_REVERSE,
			test_REVERSEARRAY,
			test_SSET,
			test_SUM,
			test_UNROLL,
			test_ZIP,
			test_basename,
			test_bin,
			test_bot,
			test_callable,
			test_checkbit,
			test_chomp,
			test_chr,
			test_circle_back,
			test_clamp,
			test_coalesce,
			test_cons,
			test_copy,
			test_deepcopy,
			test_def,
			test_delattr,
			test_exec,
			test_extend,
			test_ezpath,
			test_flatten,
			test_float,
			test_getattr,
			test_getext,
			test_glob,
			test_globals,
			test_has,
			test_hasattr,
			test_haskey,
			test_hex,
			test_indent,
			test_int,
			test_intmod,
			test_keys,
			test_len,
			test_locals,
			test_merge,
			test_method,
			test_methodist,
			test_oct,
			test_ord,
			test_pop,
			test_popleft,
			test_pow,
			test_push,
			test_pushleft,
			test_range,
			test_range0,
			test_repr,
			test_round,
			test_setattr,
			test_setbit,
			test_setbits,
			test_settype,
			test_slice,
			test_sort,
			test_sprintf,
			test_top,
			test_uniq,
			test_unroll,
			test_unsetbit,
			test_values,
			test_os_path_basename,
			test_os_path_dirname,
			test_os_path_expanduser,
			test_os_path_getsize,
			test_os_path_isfile,
			test_os_path_join,
			test_os_path_split,
			test_os_path_splitext,
			test_table_slice,
			test_table_is_empty,
			test_table_is_blank,
			test_string_trim,
			test_string_ltrim,
			test_string_rtrim,
			test_string_trimall,
			test_string_split,
			test_string_join,
			test_string_slice,
			test_string_startswith,
			test_swap,
			test_Enum,
			test_List,
			test_Array,
			test_Deque,
		 }
		for _,runtest in ipairs(tests) do runtest();end
		test:report()
	 end--TEST

	if DOCS then
		--This might not be pretty...I expect this to be temporary.
		--Nope, nothing last longer than a temporary fix.
		local DOCS ={}    --The result will be stored in this var.
		local LINES={}    --The lines of stdlib.lua
		local FUNCTIONS={}--A list of function names.
		local VARS={}     --A list of global variable names.
		local gbvars_doc={--Documentation for global objects.
			DBG_SUPPRESS=[[A table used to suppress messages dbg messages.
				When you call dbg, you should use the syntax:
					dbg{msg,s="message_type"}

				Ex:
					dbg{"So, whats for lunch?",s="blabber"}

				If the message type name is a key in DBG_SUPPRESS, then the
				message will not be output.

				To set:
					DBG_SUPPRESS["blabber"]=true

				To unset:
					DBG_SUPPRESS["blabber"]=nil
				]],
			F=[[Function to create python f-strings in lua.
				See fstring/README.md
				]],
			LULUA_VERSION="The Lulua version number. Currently: %s\n" % LULUA_VERSION,
			MAXINT="The largest int. Also defined as \"math.maxinteger\".\n",
			MININT="The most negative int. Also defined as \"math.mininteger\".\n",
			bit="Bit manipulation lib for Lua5.1 .\n",
			breakpoint="Function that sets a breakpoint.\n",
			f=[[Function to create python f-strings in lua.
				See fstring/README.md
				]],
			lfs=[[Lua filesystem module.
				See lfs/doc/us/manual.html
				]],
			penlight=[[Penlight module
				See penlight/docs/index.html
				]],
			sys=[[Module that contains sys.exit() .]],
			trace="Function that sets a breakpoint.\n",
			["type"]=[[Return the type of an object.

					Ex:
						settype(myobj,"myobj_type")
						type(myobj)-->"myobj_type"
						type("hello")-->"string" --works on build in types too.

					Yes you can add new types.
					Stores the type name as a string in the __type field that
					Lua5.1 wasn't using.
					]],
			["settype"]=[[Yes you can add new types.

					Ex:
						settype(obj,typename)

					Uses the secret __type field that Lua5.1 wasn't using.
					]],
			}
		local do_not_doc={--Dont document these:
			"_G",       --Built-in globals table. Part of standard lua.
			"_GLOBALS", --stdlib.lua internal var.
			-- "_MAP",  --Backup of MAP() because I seem to use MAP as a var.
			"_PRINT",   --Backup of the standard lua print() function because I redefine it.
			"_TYPE",    --Backup of the standard lua type()  function because I redefine it.
			"_VERSION", --Built-in version string.Part of standard lua.
			"arg",      --Built-in argv variable. Part of standard lua.
			"coroutine",--Built-in coroutine module. Part of standard lua.
			"debug",    --Built-in debug module. Part of standard lua.
			"io",       --Built-in io module. Part of standard lua.
			"math",     --Built-in math module. Part of standard lua.
			"package",  --I only added package.base, will document in prose.
			"_TYPE",--
			}
		local submod_doc={--Submodule functions that need docs too.
			["os"]={--New functions that I put into lua:
				"os.path.realpath",
				"os.path.basename",
				"os.path.dirname",
				"os.path.expanduser",
				"os.path.getsize",
				"os.path.isfile",
				"os.path.join",
				"os.path.split",
				"os.path.splitext",
				},
			["sys"]={
				"sys.exit",
				},
			["string"]={
				"string.trim",
				"string.ltrim",
				"string.rtrim",
				"string.trimall",
				"string.split",
				"string.join",
				"string.slice",
				"string.startswith",
				},
			["table"]={
				"table.is_empty",
				"table.is_blank",
				},
			}

		local function get_function_line(f)--get the line on which a function is defined.
			local info = debug.getinfo(f)
			return info.linedefined
		 end
		local function resolve_module_var(s)--look for vars in modules: Ex:"os.path.realpath"-->function.
			local chain=_G
			local ss=s:split(".")
			for k,v in ipairs(ss) do
				chain=chain[v]
			 end
			assert(type(chain)=="function")
			return chain
		 end
		local function expand_tabs(s)--convert tabs to spaces in string s
			if s==nil or s=="" then return "";end
			return string.gsub(s,"\t","    ") or s
		 end
		local function detect_indent(lines)--return min number of spaces that lines are indented by.
			local indentation=80
			local rr,ws,wc
			for _,line in ipairs(lines) do
				rr,ws=chomp(line)
				if rr~="" then--if not blank line:
					wc=expand_tabs(ws)
					if #wc < indentation then indentation=#wc;end
				 end
			 end
			return indentation
		 end
		local function indent(n,line)--indent line by n spaces.
			if n   ==nil then n=0;end
			if line==nil then line="";end
			return string.rep(" ",n)..line
		 end
		local function unindent(n,line)--remove at most n spaces from the start of line.
			--convert leading tabs to 4 spaces:
			local rr,ws=chomp(line)
			ws=expand_tabs(ws)
			line=ws..rr

			local leadingSpaces=string.match(line,"^%s*") or ""
			local minSpacesToRemove=math.min(#leadingSpaces,n)
			local result=string.sub(line,minSpacesToRemove+1)
			return result
		 end
		local function indent_block(n,lines)--indent every line in lines by n spaces.
			--if lines is string,return string
			--if lines is table, return table
			local tt="block"
			if type(lines)=="string" then
				tt="string"
				lines=lines:split("\n")
			 end
			if n==nil then n=0;end
			if lines==nil or lines=={} then return {};end
			local ss={}
			for _,line in ipairs(lines) do
				ss[#ss+1]=indent(n,line)
			 end
			if tt=="string" then return table.concat(ss,"\n");end
			return ss
		 end
		local function unindent_block(n,lines)
			--if lines is string,return string
			--if lines is table, return table
			local tt="block"
			if type(lines)=="string" then
				tt="string"
				lines=lines:split("\n")
			 end
			if n==nil then n=0;end
			if lines==nil or lines=={} then return {};end
			local ss={}
			for _,line in ipairs(lines) do
				s=unindent(n,line)
				ss[#ss+1]=s
			 end
			if tt=="string" then return table.concat(ss,"\n");end
			return ss
		 end
		local function extract_docstring(s)--get the docstring from this file.
			local pstart= "doc%s*=%s*%[%["
			local pend  = "%]%]"
			local s1,e1,s2,e2
			s1,e1=string.find(s,pstart)
			if s1 and e1 then
				if s1>160 then return nil;end--dont search too far ahead
				local r=string.sub(s,e1+1)
				s2,e2=string.find(r,pend)
				s=string.sub(s,e1+1,e1+s2-1)
				return s
			 end
			return nil
		 end
		local function format_docstring(docstring)
			local ss=docstring:split("\n")
			local first=ss[1] or "";first=first:ltrim()
			local rest=table.slice(ss,2)
			local indentation=detect_indent(rest)
			local pp=PARTIAL(unindent,indentation)
			rest=MAP(pp,rest)
			rest=indent_block(2,rest)--indent by 2 chars.
			first="  "..first--indent the first line by 2 chars.
			return table.concat({first,unpack(rest)},"\n")
		 end

		local function get_stdlib_lines()
			local f=io.open(package.base.."stdlib.lua")
			local stdlib_src=f:read("*all");f:close();
			local stdlib_lines=stdlib_src:split("\n")
			return stdlib_lines
		 end
		LINES=get_stdlib_lines()

		local function init_DOCS(DOCS,stdlib_lines)
			local section="stdlib"
			local spat="^%-%-%[%[(%w+)%]%]"
			for i,line in ipairs(stdlib_lines) do
				if line:match(spat) then
					if section~=line:match(spat) then
						DOCS[section]={}
						section=line:match(spat)
					 end
				 end
			 end
			--DOCS now has all sections except globals:
			DOCS["Globals"]={}
			return DOCS
		 end
		DOCS=init_DOCS(DOCS,LINES)

		local function get_section_line_ranges(stdlib_lines)
			local sections={}
			local section="stdlib"
			local sstart=0
			local send=0
			local spat="^%-%-%[%[(%w+)%]%]"
			for i,line in ipairs(stdlib_lines) do
				if line:match(spat) then
					if section~=line:match(spat) then
						send=i-1
						sections[section]={sstart,send}
						DOCS[section]={}
						section=line:match(spat)
						sstart=i
					 end
				 end
			 end
			return sections
		 end
		local sections=get_section_line_ranges(LINES)
		local function section_search(sections,line_number)
			for section_name,section in pairs(sections) do
				local sstart=section[1]
				local send  =section[2]
				if sstart < line_number and line_number < send then
					return section_name
				 end
			 end
			assert(false,"No doc section for line %s" % line_number)
		 end
		section_search=PARTIAL(section_search,sections)
		sections=nil

		--Separate functions, vars:
		local isf=function(v) return type(_G[v])=="function";end
		local FUNCTIONS,VARS=BSIEVE(isf,sorted(keys(_G)))

		local fdoc=function(stdlib_lines,v)--function docs
			if table.has(do_not_doc,v) then return nil;end
			local fline=get_function_line(_G[v])
			if fline>0 then--built-ins have line number of -1, it seems.
				local ss=table.slice(stdlib_lines,fline,#stdlib_lines)
				local s=table.concat(ss,"\n")--the text to search starting at the line the function is declared.
				local docstring=extract_docstring(s)
				if docstring~=nil then
					docstring=format_docstring(docstring)
					local section=section_search(fline)
					-- print(v)
					-- print("%s, section: %s"%{v,section})
					-- print("%s: %s" % {v,docstring});
					DOCS[section][v]=docstring
				else
					print("!!%s: no docstring" % v);
				 end
			 end
		 end
		fdoc=PARTIAL(fdoc,LINES)
		MAP(fdoc,FUNCTIONS)
		local sdoc=function(stdlib_lines,v)--submodule docs
			for _,vv in ipairs(v) do
				local f=resolve_module_var(vv)
				local fline=get_function_line(f)
				if fline>0 then--built-ins have line number of -1, it seems.
					local ss=table.slice(stdlib_lines,fline,#stdlib_lines)
					local s=table.concat(ss,"\n")--the text to search starting at the line the function is declared.
					local docstring=extract_docstring(s)
					if docstring~=nil then
						docstring=format_docstring(docstring)
						local section=section_search(fline)
						-- print(vv)
						-- print("%s, section: %s"%{vv,section})
						-- print("%s: %s" % {vv,docstring});
						DOCS[section][vv]=docstring
					else
						print("!!%s: no docstring" % vv);
					 end
				 end
			 end
		 end
		sdoc=PARTIAL(sdoc,LINES)
		local vdoc=function(stdlib_lines,v)--variable docs
			if table.has(do_not_doc,v) then return nil;end
			if table.haskey(submod_doc,v) then
				-- print("!! submodule %s" % v)
				sdoc(submod_doc[v])
				return nil
			 end
			if gbvars_doc[v] then
				local docstring=format_docstring(gbvars_doc[v])
				-- print(v)
				-- print("%s, section: %s"%{v,section})
				-- print("%s: %s" % {v,docstring});
				DOCS["Globals"][v]=docstring
			 else
				print("!!%s global variable" % v)
			 end
		 end
		vdoc=PARTIAL(vdoc,LINES)
		MAP(vdoc,VARS)
		-- Done with vars:
		LINES=nil
		FUNCTIONS=nil
		VARS=nil
		gbvars_doc=nil
		do_not_doc=nil
		submod_doc=nil

		-- print(keys(DOCS));sys.exit()
		--now DOCS contains lulua documentation organized by section!
		local s
		local i=12
		local function print_section(section)
			-- print("")--print a blank line.
			-- print(section)
			-- print("----------\n")
			for _,fname in ipairs(sorted(keys(DOCS[section]))) do
				print(fname)
				print(DOCS[section][fname])
			 end
		 end
		local function print_section_name(section)
			print("")--print a blank line.
			print(section)
			print("----------\n")
		 end
		s=[[Lulua Standard Library %s
			============================

			Lua needs more functions. So here they are.

			============================

			The most important variable in all of lulua:

				package.base

			package.base holds pathname of the directory where the lulua lua
			interpreter is. It ends in a path separator char.

			Use package.base to find all the lua files for your app.

			Usage:
			  --Use it to set package.path,package.cpath
			  package.path =package.path ..package.base.."lpeg/?.lua;"
			  package.cpath=package.cpath..package.base.."lpeg/?.so;"
			  --Can your lua do this?
			  dofile(package.base.."myfile.lua")

			============================

			Lulua is based on Lua version 5.1 . It provides these additional
			functions and variables:
			]] % LULUA_VERSION
		s=unindent_block(i,s)
		print(s)

		section="New"
		print_section_name(section)
		print_section(section)

		section="Globals"
		print_section_name(section)
		print_section(section)

		section="Setup"
		print_section_name(section)
		print_section(section)

		section="Import"
		print_section_name(section)
		print_section(section)

		section="Copy"
		print_section_name(section)
		print_section(section)

		section="Math"
		print_section_name(section)
		print_section(section)

		section="Datatypes"
		print_section_name(section)
		print_section(section)

		section="Structures"
		print_section_name(section)
		print_section(section)

		section="Functions"
		print_section_name(section)
		print_section(section)

		section="Iterators"
		print_section_name(section)
		print_section(section)

		section="Table"
		print_section_name(section)
		print_section(section)

		section="Strings"
		print_section_name(section)
		print_section(section)

		section="Functional"
		print_section_name(section)
		print_section(section)

		section="Bitwise"
		print_section_name(section)
		print_section(section)

		section="Misc"
		print_section_name(section)
		print_section(section)

		section="Pythonic"
		print_section_name(section)
		print_section(section)

		section="os"
		print_section(section)

		section="sys"
		print_section(section)
		s=[[sys.argv
			  If you want to use sys.argv then you will have to set it in
			  every file you want to use it in! arg is nil if this is not
			  the main file! So no sys.argv in that case!

			  Ex:
				sys.argv=arg
			]]
		s=unindent_block(i,s)
		print(s)

		section="Modules"
		print_section_name(section)
		s=[[Lulua also has the following preconfigured modules available:

			base64:    base64 encoder/decoder
			bit:       bit manipulation lib for Lua5.1, already enabled.
			curses:    Full screen terminal character control.
			debug:     interactive debugger, already enabled call trace() or
					   breakpoint() in your code to trigger.
			fstring:   python style f-strings, already enabled use functions
					   f"..." or F"..."
			gambiarra: a very simple testing framework.
			int64:     64 bit integers.
			lfs:       lua filesystem, file and directory functions.
			linenoise: a "readline" alternative that actually compiles.
			lpeg:      parsing expression grammars for lua.
			lrandom    Mersenne Twister random number generator.
			luaglut:   old-school openGL.
			lunit:     a very complicated testing framework.
			nativefs:  for love2d, gets rid of filesystem restrictions.
			penlight:  another standard library for lua, already enabled
					   imported as "penlight".
			posix:     lua posix, 
			sdl:       simple direct media layer.
			signal:    raise and catch system signals.
			sqlite:    sql database.
			utf8:      utf8 functions from the compat53 module.
			zlib:      file compression functions.
			]]
		s=unindent_block(i,s)
		print(s)

	 end--DOCS

 end--MAIN

--clean up
_GLOBALS=nil
