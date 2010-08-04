--[[
Itemforge Base Module
SERVER

This module creates a base class that contains functionality used by both items and inventories.
]]--

MODULE.Name="Base";										--Our module will be stored at IF.Base
MODULE.Disabled=false;									--Our module will be loaded
MODULE.PostLoad=false;									--Have all the classes been loaded and registered yet?

local BaseClassName="base";								--The name of the base for all Itemforge objects

local _CLASSES={};				--Cached class tables sorted by name are stored here.
local _ORIGINALCLASSES={};		--For every class there is an original class table. This contains everything unique to that class, is recorded when you register the class, and is used during a reload of that class.
local _DERIVED={};				--For every class there is a list of classes that derive from (are based off of) it. These are stored here sorted by name. The values are the class tables themselves.
local _FUNCTOCLASS={};			--A table that ties class methods to the classes they're defined in

local _CACHEmt={};				--If a class hasn't had cached any data from its base classes, it has this metatable. The first time you index something from this class the data is cached and it's metatable swaps over to _CLASSmt.
local _CLASSmt={};				--Itemforge class metatable; protects keys in the class.

local _BASE={};					--Base Itemforge Object class

--[[
Rather than making a copy of these strings every time an object is created,
we just store them here and reference as needed.
]]--
--On new index event
local IFB_ONI = "OnNewIndex";
--If an object is invalid this is what is displayed
local IFB_TSI="Object [invalid]";
--Error with get table
local IFB_EGT = "Itemforge Base: Couldn't grab object table from removed object.\n";
--Error with index
local IFB_EI = {
	"Itemforge Base: Couldn't reference \"",
	"\" on removed object.\n",
};
--Error with new index
local IFB_ENI = {
	"WARNING! \"",
	"\" tried to override \"",
	"\", a protected function or value in the \"",
	"\" class.\n",
	
	"Itemforge Base: Couldn't set \"",
	"\" to \"",
	"\" on removed object.\n",
};
--Error with To String
local IFB_ETS="ToString error: ";

--[[
* SHARED

Initilize base module
]]--
function MODULE:Initialize()
	self:RegisterClass(_BASE,BaseClassName);
end

--[[
* SHARED

Cleanup base module
]]--
function MODULE:Cleanup()
end

--[[
* SHARED

Creates a new cache table; basically new table + _CACHEmt metatable applied.
]]--
local function CacheTable()
	local t={};
	setmetatable(t,_CACHEmt);
	return t;
end

--[[
* SHARED

Used after the cache has been built.
Turns off future cache builds on the cached class table by changing the metatable to _CLASSmt
]]--
local function NoCache(tClass)
	setmetatable(tClass,_CLASSmt);
end

--[[
* SHARED

Clears the given cache table and sets it's metatable back to _CACHEmt to indicate
the cache needs to be rebuilt
]]--
local function ClearCache(tClass)
	for k,v in pairs(tClass) do rawset(tClass,k,nil) end
	setmetatable(tClass,_CACHEmt);
end

--[[
* SHARED

Builds the cache for the given cached class table.
]]--
local function CacheBuild(tClass)
	--To build the cache we at least need to be inherited first
	local bc=rawget(tClass,"BaseClass");
	if !bc then return end
	
	--[[
	Copy everything from the baseclasses that this class doesn't have.
	
	We don't recursively cache baseclasses because a lot of them don't even spawn objects.
	If we did, this would increase the time to cache a class by a significant amount,
	depending on how many classes in it's inheritence chain that hadn't been cached there were.
	]]--
	repeat
		for k,v in pairs(bc) do if rawget(tClass,k)==nil then rawset(tClass,k,v); end end
		--[[
		In the case that we inherited everything from a cached base-class (which would happen if someone had already spawned an object of the base class),
		we can just end the loop because we know we have everything at that point.
		]]--
		if bc._NeedsCache!=true then break end
		bc=bc.BaseClass;
	until bc==nil
	
	--Inheritence complete; turn off cache-related functions
	NoCache(tClass);
end

--[[
* SHARED

Wraps a class method in a function that allows for multiple-inheritence event calls
(e.g. calling OnDraw on each of five BaseClasses using only self.BaseClass)

t should be the cached class table this event is in.
f should be the method that you're wrapping.

Returns a function that should replace the given function.
]]--
--[[
local function WrapMethod(t,f)
	return function(o,...)
		if type(o)=="table" then
			local tO=rawget(o,"BaseClass");
			rawset(o,"BaseClass",rawget(t,"BaseClass"));
			
			local r={f(o,...)};
			
			rawset(o,"BaseClass",tO);
			return unpack(r);
		else
			return f(o,...);
		end
	end	
end
]]--

--[[
* SHARED

Registers a class. Class registration should be performed at initialization.
Classes are templates that are used to create objects.
	When objects are made, they start off as copies of the class they were made from.
		The nice thing about this is that you can easily create objects with one or two lines of code,
		rather than creating blank objects and then writing code that sets them up manually every time.

After a class has been registered, you can instantiate objects of that class by using IF.Base:CreateObject(strName).

You can also create classes that are based off of other classes. This is called "inheritence".
	If a class is based off of another class, this means that the first class has everything it's base does,
	plus whatever it has.
		For example, item-types and inventory templates are just classes based off of base_item and base_inv.

To register a class, you need to pass this function two arguments:

tClass is a table containing everything unique to that class.
	If tClass contains the member ".Base", then that class will be based off of
	(i.e. inherit everything from) another class that has registered with this function.
		If ".Base" is nil, then the class will inherit from BaseClassName (the base for all objects;
		for it's actual name see the top of the file).

strName is the name you wish to give to this class. This name will be used for two things:
	Making objects of this class.
	Allowing one class to inherit from another.

If a class with the given name has already been registered, the new class overrides it.
	Any objects using the old class will automatically take advantage of the new class.
	Any classes based off of the old class will automatically re-inherit from this class.

A cached class table is returned if the class was successfully registered.
nil is returned if tClass wasn't a table/wasn't given, or if strName wasn't given / wasn't a string.

NOTE:
The returned class table is not tClass. It's a cached class table, which has everything you specified in tClass,
and after inheritence is performed, will have everything it's base class has.
]]--
function MODULE:RegisterClass(tClass,strName)
	if !IF.Util:IsTable(tClass)		then ErrorNoHalt("Itemforge Base: Couldn't register class. Given class table was invalid.\n"); return nil; end
	if !IF.Util:IsString(strName)	then ErrorNoHalt("Itemforge Base: Couldn't register class. The given class name was invalid.\n"); return nil; end
	strName=string.lower(strName);
	
	tClass.ClassName=strName;
	tClass.Classname=strName;
	
	local t=_CLASSES[strName];
	local bOverride = (t!=nil);
	if bOverride then
		
		--Since we're overriding an existing class, The old functions are no longer valid.
		for k,v in pairs(_ORIGINALCLASSES[strName]) do _FUNCTOCLASS[v]=nil end
		
		--There's a good chance the new class doesn't inherit from the old one's base
		local strOldBase=t.Base;
		if strOldBase then _DERIVED[strOldBase][t]=nil end
		
		--We empty out the existing cached class table so existing objects of this class can
		--take advantage of the new contents.
		ClearCache(t);
	else
		--Otherwise, we create a new cached class table for this class.
		t=CacheTable();
	end
	
	--[[
	A reference to this class (by name) is stored in the class.
	The effect of this is, if you have an object called "myObj", and it's class is "item_crowbar",
	you can access it's class by doing myObj["item_crowbar"].
	
	Additionally, because of how inheritence works, you can access any of item_crowbar's base classes
	from an object of that type (e.g. myObj["base_melee"]) or from any class
	the item_crowbar class itself (e.g. myObj["item_crowbar"]["base_melee"]).
	]]--
	rawset(t,strName,t);
	
	--The cached class table starts out with everything the given table has,
	--and afterwords will cache things from it's base classes as necessary.
	for k,v in pairs(tClass) do
		rawset(t,k,v);
		if IF.Util:IsFunction(v) then _FUNCTOCLASS[v]=t end
	end
	
	--Register class offically
	_CLASSES[strName] = t;
	_ORIGINALCLASSES[strName]=tClass;
	
	--If the class has a post-register function set up we run it here
	local fClassReg=t.OnClassRegister;
	if IF.Util:IsFunction(fClassReg) then
		local s,r=pcall(fClassReg,t);
		if !s then ErrorNoHalt("Itemforge Base: OnClassRegister event for class \""..strName.."\" failed: "..r.."\n") end
	end
	
	--If this was an override any derived classes are reloaded.
	--Otherwise we create a blank DERIVED table to record future derived classes.
	if bOverride then
		for k,v in pairs(_DERIVED[strName]) do
			local strDCName=k.ClassName;
			self:RegisterClass(_ORIGINALCLASSES[strDCName],strDCName);
		end
	else
		_DERIVED[strName]={};
	end
	
	--If this class was created after initialization (all classes loaded then inherited) we can just perform the inheritence now
	if self.PostLoad==true then
		self:Inherit(t);
	end
	
	return t;
end

--[[
* SHARED

This is done automatically. There should be no reason for a scripter to call this.
Makes the given class inherit from it's base.
Returns true if the class has fully inherited from it's base.
]]--
function MODULE:Inherit(tClass)
	--If we've already inherited we're done
	if tClass.BaseClass != nil then return true end
	
	--The absolute base class does not inherit from anything, therefore it has no need to cache or inherit
	local ClassName=tClass.ClassName;
	if ClassName==BaseClassName then NoCache(tClass); return true end
	
	--Locate the class's requested base class
	local strRequestedBase=tClass.Base;
	if IF.Util:IsString(strRequestedBase) then
		strRequestedBase=string.lower(strRequestedBase);
		
		--Make sure we're not trying to inherit from ourselves
		if strRequestedBase!=ClassName then
			--Direct reference to class's base-class
			local tBaseClass=_CLASSES[strRequestedBase];
			
			if tBaseClass!=nil then
				rawset(tClass,"Base",strRequestedBase);
				rawset(tClass,"BaseClass",tBaseClass);
			
			--Couldn't find the base-class (note that all classes are loaded before bases are set,
			--so the only reason this would happen is if the requested base-class isn't loaded or couldn't be loaded)
			else
				ErrorNoHalt("Itemforge Base: Class \""..ClassName.."\" could not inherit from class \""..strRequestedBase.."\". \""..strRequestedBase.."\" could not be found.\n");
			end
		else
			ErrorNoHalt("Itemforge Base: Class \""..ClassName.."\" was based off of itself; classes cannot inherit from themselves.\n");
		end
	end
	
	--If BaseClass still hasn't been set, then we'll set it's base to the absolute base class
	if tClass.BaseClass==nil then
		rawset(tClass,"Base",BaseClassName);
		rawset(tClass,"BaseClass",_CLASSES[BaseClassName]);
	end
	
	--Make sure this class's base class is fully inherited; this will recursively inherit the entire chain
	self:Inherit(tClass.BaseClass);
	
	--Make sure that this class isn't overriding anything protected in the base classes.
	for k,v in pairs(tClass) do
		local pc=IF.Base:IsProtectedKey(tClass.BaseClass,k);
		if pc then ErrorNoHalt("Itemforge Base: WARNING! "..ClassName.." tried to override \""..tostring(k).."\", a protected function or value in the \""..pc.ClassName.."\" class.\n");
			rawset(tClass,k,nil);
			
			--We also clear from the original class so if we reload the error isn't unnecessarily repeated
			_ORIGINALCLASSES[ClassName][k]=nil;
		end
	end
	
	--Following a successful inherit we mark this as an inherited class of the base class
	_DERIVED[tClass.Base][tClass]=true;
	
	--Then we run the post inherit event for this class
	local fOnClassInherit = IF.Base:InheritedLookup(tClass,"OnClassInherited");
	local s,r=pcall(fOnClassInherit,tClass);
	if !s then ErrorNoHalt("Itemforge Base: OnClassInherited event for class \""..ClassName.."\" failed: "..r.."\n") end
	
	return true;
end

--[[
* SHARED

This is handled automatically, there's no need for a scripter to call this function.

This function performs the inheritence for every class and should typically
be done after all classes are loaded, but before any class has been inherited.
]]--
function MODULE:DoInheritance()
	for k,v in pairs(_CLASSES) do
		self:Inherit(v);
	end
	self.PostLoad = true;
end

--[[
* SHARED

Returns true if a class with the given name is registered.
]]--
function MODULE:ClassExists(sName)
	return (_CLASSES[string.lower(sName)]!=nil);
end

--[[
* SHARED

Given a class table and a key, this function will check to see if the key is protected and
therefore can't (more like shouldn't) be overriden.

tClass should be a class table.
k should be the key you want to check.

If the key is protected, the cached class table of the class protecting the key is returned.
nil is returned otherwise.
]]--
function MODULE:IsProtectedKey(tClass,k)
	local pk;
	while tClass!=nil do
		--[[
		We use rawget because inheritance would sometimes make us look at the same _ProtectedKeys more than once.
		e.g: Lets say this is the inheritance of weapon_smg:
		base < base_nw < base_item < base_weapon < base_ranged < base_firearm < weapon_smg
		
		base_item has protected keys but weapon_smg, base_firearm, base_ranged, base_weapon don't.
		That means we would be looking at base_item's protected keys a total of 5 times.
		
		Besides that, rawget doesn't trigger the cache build in unbuilt classes.
		]]--
		pk=rawget(tClass,"_ProtectedKeys");
		if pk && pk[k] then return tClass end
		
		tClass=tClass.BaseClass;
	end
	return nil;
end

--[[
* SHARED

Does an inherited lookup for a key on the given cached class table,
but without building the cache.

Building a cache may take a while, and you may not want to to trigger that on accident
because it will cause a short load spike. If you want to avoid that, use this function.

After the cache is built, however, it's actually faster to just look it up directly rather
than use this function. That being said there are only a few occasions where this makes sense to use:
	* Interally in itemforge by me
	* In the OnClassInherited event

tClass should be a cached class table.
k should be the key to look up.

If a value is found in the given class or a class it inherits from, that value is returned.
If the value can't be found, nil is returned.
Additionally, if tClass is nil, nil is returned.
]]--
function MODULE:InheritedLookup(tClass,k)
	while tClass!=nil do
		local v=rawget(tClass,k);
		if v then return v end
		
		tClass=tClass.BaseClass;
	end
	return nil;
end

--[[
* SHARED

Creates an object (an instance of a class).
Generates an error message and returns nil if the object cannot be created.

This function returns a reference to the newly created object.
Calling ref:Invalidate() or garbage-collecting the reference will delete the actual object it points to.
]]--
function MODULE:CreateObject(strClass)
	if !IF.Util:IsString(strClass) then ErrorNoHalt("Itemforge Base: Could not create object. Class given wasn't valid.\n"); return nil; end
	strClass=string.lower(strClass);
	local t=_CLASSES[strClass];
	
	--[[
	Make sure the class we want is valid (has loaded succesfully)
	If it's not, a few things could be causing this.
	    Parsing errors serverside or clientside may be at work (meaning there's probably a typo in your script)
	    If the object can be created serverside with no trouble, but can't be created clientside...
	        Make sure that all the necessary files are being sent (included with AddCSLuaFile).
			Check the server console. Lua files are compiled before they are sent to the clients.
				If there are parsing errors dealing with clientside files, this may be what is wrong.
	]]--
	if !t then
		if SERVER then	ErrorNoHalt("Itemforge Base: Could not create object, \""..strClass.."\" is not a valid class. Check for parsing errors in console or mis-spelled class name.\n");
		else			ErrorNoHalt("Itemforge Base: Could not create object, \""..strClass.."\" is not a valid class. Check for scripts not being sent!\n");
		end
		return nil;
	end
	
	--Object
	local o={};
	
	--Table of functions created specifically for this reference (lookup from table is faster than a string comparison)
	local f={
		--Returns true if the reference is valid (the object it points to hasn't been deleted)
		["IsValid"]			=	function() return (o!=nil); end,
		
		--Invalidates the object (basically deletes it)
		["Invalidate"]		=	function() o=nil; end,
		
		--Returns a copy of everything unique to the object, so long as it's valid
		["GetTable"]		=	function()
									if !o then ErrorNoHalt(IFB_EGT); return nil; end
									local tC={};
									for k,v in pairs(o) do tC[k]=v; end
									return tC;
								end,
	};
	
	local mt={};
	
	--[[
	Objects draw their functions/data from three sources (checked in first to last order as listed here):
	  1. (f) References have their own set of functions which are linked to here.
	  2. (o) is the object itself. Anything unique to that individual object is stored here.
	  3. (t) is the object's cached class table. This is the last stop; lookups are cached here for speed.
	]]--
	function mt:__index(k)
		if f[k] then		return f[k];
		elseif o then
			if o[k] then return o[k];
			else		 return t[k];
			end
		else				ErrorNoHalt(IFB_EI[1]..tostring(k)..IFB_EI[2]);
		end
	end
	
	--We want to forward writes to the object, so long as it's valid
	function mt:__newindex(k,v)
		if o then
			--Is the key protected? If so, on what class?
			local pc=IF.Base:IsProtectedKey(t,k);
			if pc then return self:Error(IFB_ENI[1]..tostring(self)..IFB_ENI[2]..tostring(k)..IFB_ENI[3]..pc.ClassName..IFB_ENI[4]); end
			
			if self:Event(IFB_ONI,true,k,v)==true then o[k]=v; end
		else
			ErrorNoHalt(IFB_ENI[5]..tostring(k)..IFB_ENI[6]..tostring(v)..IFB_ENI[7]);
			return false;
		end
	end
	
	--Objects' tostring function get to decide what happens
	function mt:__tostring()
		if o!=nil then
			local s,r=pcall(self.ToString,self);
			if s then return r
			else	  return IFB_ETS..r..")"; end
		else
			return IFB_TSI;
		end
	end
	
	local r={};		--Reference
	setmetatable(r,mt);
	
	return r;
end



--These vars can be accessed through an uncached cache table
local _CACHEmtlookups={
	["_NeedsCache"]=true
};

--[[
* SHARED

The first time we index a cached class table, we want to build the cache so future lookups are speedy.
This may generate a slight load spike (which takes longer depending on how many keys need to be cached),
but it's worth the effort for faster lookups.
]]--
function _CACHEmt:__index(k)
	if _CACHEmtlookups[k] then return _CACHEmtlookups[k] end
	CacheBuild(self);
	
	return rawget(self,k);
end

--[[
* SHARED

After a class is loaded, it shouldn't be modified by a scripter accidentilly. This can be bypassed, but it's here as a safeguard.
If a class is accidentally modified, a warning message will be generated and no changes will occur.
]]--
function _CACHEmt:__newindex(k,v)
	ErrorNoHalt("Itemforge Base: WARNING! Override blocked on class \""..self.ClassName.."\": Tried to set \""..tostring(k).."\" to \""..tostring(v).."\".\n");
end

--[[
* SHARED
This metatable is the same as _CACHEmt except it doesn't rebuild the cache when it can't find a key.
]]--
_CLASSmt.__newindex = _CACHEmt.__newindex;








--[[
* SHARED
* Different for each Class

Setting the base to the name of another class will make this class inherit the functions and values from that class.
You needn't use everything from the base-class. If both your class and it's base class have a function/value by the same name,
the function/value in your class overrides the base class's function (unless the function/value is protected, in which case you'll get an error message at startup.)
Individual objects may also override any function/value from their class.

If base is nil or not given, the class inherits from the absolute base class (this class).
]]--
_BASE.Base=nil;

--[[
* SHARED
* Different for each Class

Protected keys cannot be overridden by objects or classes that are based off this class.
Every class can have it's own set of protected keys.
To protect a key, first, make sure your class has a protected keys table:
	CLASS._ProtectedKeys={}
Then for every key you want to protect, do:
	CLASS._ProtectedKeys["NameOfKeyToProtect"]=true;

Where CLASS is the name of your class table, of course.
]]--
_BASE._ProtectedKeys={};

--[[
* SHARED
* Default defined in this Class
* Different for each Class

ClassName is the name of this class. It's set automatically when you register the class.
It is always lowercase, even if you give uppercase characters when registering the class.

Classname is an alias of ClassName.
]]--
_BASE.ClassName="";
_BASE.Classname="";

--[[
* SHARED
* Protected

Generates a non-halting error message.
sErrorMsg is the message to display.
Always returns false.
]]--
function _BASE:Error(sErrorMsg)
	ErrorNoHalt(tostring(self)..": "..sErrorMsg.."\n");
	return false;
end
_BASE._ProtectedKeys["Error"]=true;

--[[
* SHARED
* Protected

This function can determine if this object inherits from the given class or not.
This includes if the item _IS_ what you're checking to see if it's based off of.
	For example, If an item is an item_egg, then item:InheritsFrom("item_egg") will return true.
	
	Another example: lets say we want to determine if a given object is an item or an inventory.
		The base item is base_item, so we can do:
			if object:InheritsFrom("base_item")	then ... end
		The base inventory is base_inv, so we can do:
			if object:InheritsFrom("base_inv")	then ... end
	
	Another example, lets say we have three item types:
		base_weapon, base_melee, and item_sword.
	
		Inheritence is set up like so (right inherits from left):
		base_weapon < base_melee < item_sword
	
		Lets say we have a weapons salesman who will only buy weapons.
		We could check that the item we're trying to sell him is a weapon by doing:
		item:InheritsFrom("base_weapon")
		It would return true, because a sword is a melee weapon, and a melee weapon is a weapon.

sClass is the name of the class ("base_item", "base_container", "base_nw", etc.)
This function returns true if the item inherits from this item type, or false if it doesn't.
]]--
function _BASE:InheritsFrom(sClass)
	return self[string.lower(sClass)]!=nil;
end
_BASE._ProtectedKeys["InheritsFrom"]=true;

--[[
* SHARED
* Protected

Calls an event on the object.
If there is an error calling the event, a non-halting error message is generated and a default value is returned.

strEventName is a string which should be the name of the event to call (EX: "OnDraw2D", "OnThink", etc)
vDefaultReturn is what will be returned in case of errors calling the hook.
... - You can pass arguments to the event here. There's no need to pass "self", since it's automatically the first argument.

This function returns several values: vReturn,bSuccess,vReturn2,vReturn3,...
	vReturn will be what the event returned, or if there were errors, then it will be vDefaultReturn.
	bSuccess will be true if the event was called successfully, or false if there were errors.
	vReturn2, vReturn3, ... will be any other values returned by the event.
	
Example: I want to call this object's CanEnterWorld event:
	self:Event("CanEnterWorld",false,vPos,aAng);
	This runs an object's CanEnterWorld and gives it vPos and aAng as arguments.
	If there's a problem running the event, we want false to be returned.
]]--
function _BASE:Event(strEventName,vDefaultReturn,...)
	local f=self[strEventName];
	if !f then			self:Error("\""..strEventName.."\" failed: This event does not exist."); return vDefaultReturn,false end
	
	local OldContext = self._ClassContext;
	rawset(self,"_ClassContext",_FUNCTOCLASS[f]);
	
	local s,r=pcall(f,self,...);
	if s==false then	self:Error("\""..strEventName.."\" failed: "..r); r = vDefaultReturn; end
	
	rawset(self,"_ClassContext",OldContext);
	
	return r,s;
end
_BASE._ProtectedKeys["Event"]=true;

--[[
* SHARED
* Protected

Calls an event on the object's base class.
This is useful if you want an overrided event to do everything it's base class does,
plus something else.

strEventName is a string which should be the name of the event to call (EX: "OnDraw2D", "OnThink", etc)
vDefaultReturn is what will be returned in case of errors calling the hook.
... - You can pass arguments to the event here. There's no need to pass "self", since it's automatically the first argument.

This function returns several values: vReturn,bSuccess,vReturn2,vReturn3,...
	vReturn will be what the event returned, or if there were errors, then it will be vDefaultReturn.
	bSuccess will be true if the event was called successfully, or false if there were errors.
	vReturn2, vReturn3, ... will be any other values returned by the event.
	
Example:
	Lets pretend we have a class of items called item_food, based off of base_item.
	
	base_item's OnUse makes us pick up an item in the world.
	If we pick it up, then base_item's OnUse returns true to show that we successfully used it.
	
	However, if we try to use it after it's been picked up, base_item's OnUse returns false,
	because it doesn't know what to do with the item.
	
	So, for item_food, what we want to do is pick it up when it's used in the world, and eat
	it when it's used anywhere else.
	
	Luckily, we can use BaseEvent for this.
	
	Here's how I'd design item_food's OnUse:
	
	function ITEM:OnUse(pl)
		if self:BaseEvent("OnUse",false,pl) then return true end
		
		if SERVER then self:Eat(pl) end
		return true;
	end
	
	In this example we call base_item's OnUse event first, passing the player that was received by
	item_food's OnUse event.
	
	base_item's OnUse will make the player pick up the item up if it's in the world.
	If the item was picked up, base_item's OnUse returns true, signaling that base_item
	has handled it. Then, the "if" in item_food's OnUse sees that it has been handled and
	returns true because it doesn't have to do anything else.
	
	But if false is returned, that means base_item couldn't figure out what to do with the item.
	If there was an error in base_item's OnUse, we have it set up so the default return value
	is "false". So in either case, error or just couldn't figure it out, item_food takes over
	and tells the item to be eaten.
	
	We return true to indicate that the event has been handled.
]]--
function _BASE:BaseEvent(strEventName,vDefaultReturn,...)
	if !self._ClassContext then			self:Error("\""..strEventName.."\" failed: BaseEvent cannot be called directly. Use :Event() or :InheritedEvent() instead."); return vDefaultReturn,false end
	local p=self._ClassContext.BaseClass;
	
	local f=p[strEventName];
	if !f then			self:Error("\""..strEventName.."\" from base \""..p.ClassName.."\" failed: This event does not exist."); return vDefaultReturn,false end
	
	local OldContext = self._ClassContext;
	rawset(self,"_ClassContext",_FUNCTOCLASS[f]);
	
	local s,r=pcall(f,self,...);
	if s==false then self:Error("\""..strEventName.."\" from base \""..p.ClassName.."\" failed: "..r); r = vDefaultReturn; end
	
	rawset(self,"_ClassContext",OldContext);
	
	return r,s;
end
_BASE._ProtectedKeys["BaseEvent"]=true;

--[[
* SHARED
* Protected

Calls an event that was inherited from a specific baseclass of the object.
This is best used when you want to do everything a grandparent's event does
plus something else you specify, and need to sidestep the parent entirely.

strEventName is a string which should be the name of the event to call (EX: "OnDraw2D", "OnThink", etc)
strParentName is a string indicating which parent to take the event from.
	Don't use self.Base for this, or for that matter self.ANY_VARIABLE.
	It will cause an infinite loop.
	If this happens lua will likely report the error as "stack overflow" or "infinite loop detected".
	
	If you were going to use self.Base as an argument in this function,
	a better function to use would be to use self:BaseEvent above.
	
	Use the name of a class in quotes.
	Example of valid values: "base_melee", "base_item", "base_inv", etc.
	
vDefaultReturn is what will be returned in case of errors calling the hook.
... - You can pass arguments to the event here. There's no need to pass "self", since it's automatically the first argument.

This function returns several values: vReturn,bSuccess,vReturn2,vReturn3,...
	vReturn will be what the event returned, or if there were errors, then it will be vDefaultReturn.
	bSuccess will be true if the event was called successfully, or false if there were errors.
	vReturn2, vReturn3, ... will be any other values returned by the event.
]]--
function _BASE:InheritedEvent(strEventName,strParentName,vDefaultReturn,...)
	strParentName = string.lower(strParentName);
	local p=self[strParentName]
	if !p then self:Error("\""..strEventName.."\" from base \""..strParentName.."\" failed: \""..self.ClassName.."\" is not based off of \""..strParentName.."\"."); return vDefaultReturn,false end
	
	local f=p[strEventName];
	if !f then self:Error("\""..strEventName.."\" from base \""..strParentName.."\" failed: This event does not exist on base class \""..strParentName.."\"."); return vDefaultReturn,false end
	
	local OldContext = self._ClassContext;
	rawset(self,"_ClassContext",_FUNCTOCLASS[f]);
	
	local s,r=pcall(f,self,...);
	if s==false then self:Error("\""..strEventName.."\" from base \""..strParentName.."\" failed: "..r); r=vDefaultReturn; end
	
	rawset(self,"_ClassContext",OldContext);
	
	return r,s;
end
_BASE._ProtectedKeys["InheritedEvent"]=true;




--[[
CLASS/OBJECT EVENTS
]]--




--[[
* SHARED
* Class
* Event

This function runs after registering a class, but before inheriting from it's base.
Since this is before inheritence, the OnClassRegister event only calls if it's present in the
class you're registering. That is, each class you want this to run on should have it's own
OnClassRegister.
]]--
function _BASE:OnClassRegister()
end

--[[
* SHARED
* Class
* Event

This runs after this class has inherited from it's base class.

Since this is after inheritence, it runs on any class based off the base class (all classes basically),
unless someone overrides it on purpose.
]]--
function _BASE:OnClassInherited()
end

--[[
* SHARED
* Event

This function runs when a value has been set in this object.
Returning true allows the change, and returning false stops the change from occuring.
]]--
function _BASE:OnNewIndex(k,v)
	return true;
end

--[[
* SHARED
* Event

When tostring() is performed on an object reference, it returns a string containing some information about the object.
]]--
function _BASE:ToString()
	return "Object ["..self.ClassName.."]";
end