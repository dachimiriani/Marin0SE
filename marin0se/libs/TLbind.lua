--- TLbind v1.3, a simple system for creating professional control schemes
-- @author Taehl (SelfMadeSpirit@gmail.com), with contributions from smrq


local update
--- Gives a new instance of TLbind settings and control.
-- Good for OOP, multi-player split-screen with their own controls, etc.
-- Use: P1.bind, P1.control = TLbind.giveInstance( aTableOfBinds )
-- @param binds table specifies inputs, controls, and settings
-- @return b, a fresh new control instance (for changing settings)
-- @return b.control, the table to check if a control is being used
-- @return b.control.tap, where controls are only true for one frame when first used
-- @return b.control.release, where controls are only true for one frame when released
local function giveInstance( binds )
	--- The binds table specifies inputs, controls, and settings
	-- @class table
	-- @name binds
	-- @field useKeyboard if true, process keyboard input
	-- @field useMouse if true, process mouse input
	-- @field useJoystick if true, process joystick input
	-- @field deadzone clip analogue deadzoneAxes pairs to 0 when under this number (must be >= 0 and < 1)
	-- @field pairedAxes [joystick#][index#] = {axis#1, axis#2}
	-- @field deadzoneAxes [index#] = {"analogue 1", "analogue 2"} (note: pairs will also be normalized, which fixes the common "running diagonally is faster" bug)
	-- @field keys [KeyConstant] = "control"
	-- @field mouseAxes {"x control", "y control"}
	-- @field mouseBtns [MouseConstant] = "control"
	-- @field joyAxes [joystick#][axis#] = "control"
	-- @field joyBtns [joystick#][button#] = "control"
	-- @field joyBalls [joystick#][ball#] = {"x control", "y control"}
	-- @field joyHats [joystick#][hat#] = {"l control", "r control", "u control", "d control"}
	-- @field maps [analogue] = {"negative digital", "positive digital"}
	local b = {
		useKeyboard = true, useMouse = false, useJoystick = true, 
		deadzone = 0.1, keys = {}, mouseAxes = {}, mouseBtns = {}, 
		joyAxes = {}, joyBtns = {}, joyBalls = {}, joyHats = {}, 
		deadzoneAxes = {}, maps = {}, pairedAxes = {}
	}
	
	if binds then		-- use supplied binds, if given (safer to copy than directly reference!)
		local function tableCombine( a, b )
			local t = {}
			for k, v in pairs(a) do if type(v)=="table" then t[k]=tableCombine(v) else t[k]=v end end
			if b then for k, v in pairs(b) do if type(v)=="table" then t[k]=tableCombine(v) else t[k]=v end end end
			return t
		end
		b = tableCombine(b, binds)
	end
	b.update = update
	b.control = {tap={},release={}}
	
	-- The callbacks are .controlPressed and .controlReleased (they work just like Love's callbacks)
	-- Use: function TLbind.controlPressed(control) if control=="jump" then doJump() end end
	return b, b.control, b.control.tap, b.control.release
end


--- In love.update(), :update() on each bind instance.
-- You'll probably want to add TLbind:update() to your love.update().
-- @param b table a control instance, such as the default TLbind
update = function(b)
	local control, tap, release = b.control, b.control.tap, b.control.release
	-- Reset controls
	for k,v in pairs(control) do if type(v)~="table" then control[k] = false end end
	
	-- Check key inputs (if enabled)
	if b.useKeyboard then
		assert(love.keyboard, "TLbind was told to use keyboard input, but love.keyboard isn't available! (Check conf.lua)")
		for k,v in pairs(b.keys) do
			local t={}
			if type(v)=="table" then
				t=v
			else
				t={v}
			end
			for k2,v2 in pairs(t) do
				control[v2] = control[v2] or love.keyboard.isDown(k)
			end
		end
	end
	
	-- Check joystick inputs (if enabled)
	if b.useJoystick then
		assert(love.joystick, "TLbind was told to use joystick input, but love.joystick isn't available! (Check conf.lua)")
		local lj = love.joystick
		local js = lj.getJoysticks()
		for j,binds in pairs(b.joyAxes) do 
			for k,v in pairs(binds) do
				local t={}
				if type(v)=="table" then
					t=v
				else
					t={v}
				end
				for k2,v2 in pairs(t) do
					control[v2] = control[v2] or js[j]:getAxis(k)
				end
			end
		end
		for j,binds in pairs(b.joyBtns) do
			for k,v in pairs(binds) do
				local t={}
				if type(v)=="table" then
					t=v
				else
					t={v}
				end
				for k2,v2 in pairs(t) do
					if js[j] then
						--[[@TODO: 
							Refactor this later, we're doing this check so that when someone
							launches the game without a joystick plugged in it doesn't crash
							because controls are defined for a joystick.
						]]
						control[v2] = control[v2] or js[j]:isDown(k)
					end
				end
			end
		end
		-- balls are missing in love0.9.1, goodbye balls
		--for j,binds in pairs(b.joyBalls) do
		--	for k,v in pairs(binds) do
		--		control[v[1]], control[v[2]] = js[j]:getBall(k)
		--	end
		--end
		for j,binds in pairs(b.joyHats) do
			for k,v in pairs(binds) do
				local t={}
				if type(v)=="table" then
					t=v
				else
					t={v}
				end
				local z = js[j]:getHat(k)
				for k2,v2 in pairs(t) do
					if string.sub(z,1,1)=="l" then 
						control[v2[1]]=true
					elseif string.sub(z,1,1)=="r" then
						control[v2[2]]=true 
					end
					if string.sub(z,-1)=="u" then
						control[v2[3]]=true
					elseif string.sub(z,-1)=="d" then
						control[v2[4]]=true
					end
				end
			end
		end
	end
	
	-- Check mouse inputs (if enabled)
	if b.useMouse then
		assert(love.mouse, "TLbind was told to use mouse input, but love.mouse isn't available! (Check conf.lua)")
		for k,v in pairs(b.mouseBtns) do
			local t={}
			if type(v)=="table" then
				t=v
			else
				t={v}
			end
			for k2,v2 in pairs(t) do
				control[v2] = control[v2] or love.mouse.isDown(k)
			end
		end
		
		-- Get screen metrics, to convert pixel coordinates into normals (treating the center of the screen as (0,0) )
		local w, h = love.graphics.getWidth(), love.graphics.getHeight()
		local ws, hs = w*.5, h*.5
		local wt, ht = ws, w*.5-(w-h)*.5
		-- Set mouse axes if they haven't already gotten input
		local mA1, mA2 = control[b.mouseAxes[1]], control[b.mouseAxes[2]]
		if b.mouseAxes[1]~=nil or b.mouseAxes[2]~=nil then
			if (mA1==0 and mA2==0) then
				control[b.mouseAxes[1]], control[b.mouseAxes[2]] = (love.mouse.getX()-wt)/hs, (love.mouse.getY()-ht)/hs
			end
		end
	end
	
	-- Apply scaled radial deadzone on desired axis pairs (requires normalizing them too)
	
	--[[for j,binds in pairs(b.deadzoneAxes) do 
		for k,v in pairs(binds) do
			local t={}
			if type(v)=="table" then
				t=v
			else
				t={v}
			end
			for k2,v2 in pairs(t) do
				control[v2] = control[v2] or js[j]:getAxis(k)
			end
		end
	end]]
	
	local lj = love.joystick
	local js = lj.getJoysticks()
	for j,index in pairs(b.pairedAxes) do
		-- j is the controller number
		-- index is the pair doesn't mean much
		for k,tpairs in pairs(index) do
			-- k isn't important
			-- tpairs is the data
			if js[j] then
				--@TODO: See above todo.
				local x, y = js[j]:getAxis(tpairs[1]), js[j]:getAxis(tpairs[2])
				if x and y then
					local l = (x*x+y*y)^.5
					if l > 1 then x,y,l = x/l, y/l, 1 end
					if l<b.deadzone then
						control[b.deadzoneAxes[j][tpairs[1]]], control[b.deadzoneAxes[j][tpairs[2]]] = 0, 0
					else
						local n = ((l-b.deadzone)/(1-b.deadzone))
						control[b.deadzoneAxes[j][tpairs[1]]], control[b.deadzoneAxes[j][tpairs[2]]] = x*n, y*n
					end
				end
			end
		end
	end
	
	-- Impose digital controls onto analogue controls and vice versa (binding first if needed)
	for a,d in pairs(b.maps) do
		if type(controls[a])=="boolean" then 
			if controls[a] then
				controls[a]=1
			else 
				controls[a]=0
			end
		elseif type(controls[a])=="nil" then 
			controls[a]=0 
		end
		--print("tier1", a, d)
		for h,o in pairs(d) do
			--print("tier2", h, o)
			--for k,v in pairs(o) do
				local t={}
				if type(o)=="table" then
					t=o
				else
					t={o}
				end
				if control[a]~= nil then
					for k2,v2 in pairs(t) do
						--print("tier3", k2, v2)
						-- I think this is how maps?!
						--if control[d[1]]--[[ then control[a]=-1 elseif control[d[2]]--[[ then control[a]=1 end
						if h==1 and control[a]<-b.deadzone then
							--print("valueneg", control[a], v2)
							control[v2]=true 
						elseif h==2 and control[a]>b.deadzone then
							--print("valuepos", control[a], v2)
							control[v2]=true
						end
					end
				end
			--end
		end
		--if control[d[1]]--[[ then control[a]=-1 elseif control[d[2]]--[[ then control[a]=1 end
		--if control[a]<0 then control[d[1]]--[[=true elseif control[a]>0 then control[d[2]]--[[=true end]]
	end
	
	-- Detect controls being tapped and released
	for k,v in pairs(control) do
		if v then
			release[k] = false
			if tap[k]==false then 
				tap[k]=true
				if b.controlPressed then
					b.controlPressed(k)
				end
			elseif tap[k]==true then
				tap[k]=nil
			end
		else
			tap[k] = false
			if release[k]==false then
				release[k]=true 
				if b.controlReleased then
					b.controlReleased(k)
				end
			elseif release[k]==true then
				release[k]=nil
			end
		end
	end
end


--- Default binds are assigned to global var TLbind
-- Example: Open a menu when escape is pressed
-- function love.load() TLbind.keys.escape = "menu" end
-- function love.update() if TLcontrol.tap.menu then openMenu() end end
TLbind = giveInstance({giveInstance=giveInstance})
return TLbind, TLbind.control, TLbind.control.tap, TLbind.control.release