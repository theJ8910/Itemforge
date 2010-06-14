--[[
Itemforge Base Module
SERVER

This module creates a base class that contains functionality used by both items and inventories.
]]--

MODULE.Name="Base";												--Our module will be stored at IF.Base
MODULE.Disabled=false;											--Our module will be loaded

local BaseClassName="base";										--The name of the base for all Itemforge objects

--List of all available classes (sorted by keyname)
local _CLASSES={};

--Itemforge Base Class metatable (same as _CLASSmt but has no inheritence)
local _BASECLASSmt={};

--Itemforge Class metatable
local _CLASSmt={};

--Base Itemforge Object class
local _BASE={};

--Rather than making a copy of these strings every time an object is created, we just store them here and reference as needed.

--Error with get table
local IFB_EGT = "Itemforge Base: Couldn't grab object table from removed object.\n";

--Error with index
local IFB_EI = {
	"Itemforge Base: Couldn't reference \"",
	"\" on removed object.\n",
};

--Error with new index
local IFB_ENI = {
	"WARNING! This object tried to override \"",
	"\", a protected function or value in the \"",
	"\" class.\n",
	
	"Itemforge Base: Couldn't set \"",
	"\" to \"",
	"\" on removed object.\n",
};

--Error with To String
local IFB_ETS="ToString error: ";

--On new index event
local IFB_ONI = "OnNewIndex";

--Tostring says this is an invalid object
local IFB_TSI="Object [invalid]";


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

Registers a class. Class registration should be performed at initialization.
Classes are templates that can be used to create objects. Item-types and inventory templates are two examples of this.
After a class has been registered, you can instantiate objects of that class by using IF.Base:CreateObject(sName).

tClass is a class table.
	If tClass contains the member ".Base", then that class will inherit everything from (be based off of) another class registered with this function.
	If ".Base" is nil, then the class will inherit from BaseClassName (see top of file).

sName is the name you wish to give to this class. This name will be used for two things:
	Making objects from this class.
	Allowing one class to inherit from another.
	
The class table is returned if the template was successfully registered,
and nil is returned otherwise.

NOTE:
The returned class table is not necessarily the same table you gave to the function, tClass.
If a class with this name has already been registered, we copy the contents of tClass to the
existing table, and then return that table instead.
]]--
function MODULE:RegisterClass(tClass,sName)
	if !tClass then ErrorNoHalt("Itemforge Base: Couldn't register class. Class table wasn't given."); return nil; end
	if !sName then ErrorNoHalt("Itemforge Base: Couldn't register class. The name of the class was not given."); return nil; end
	sName=string.lower(sName);
	
	tClass.ClassName=sName;
	tClass.Classname=sName;
	
	--If this item type is already loaded just empty out the existing table; that way existing items of this type are instantly updated with the new contents.
	local tExt=_CLASSES[sName];
	if tExt then
		setmetatable(tExt,nil);
		for k,v in pairs(tExt) do
			tExt[k]=nil;
		end
		for k,v in pairs(tClass) do
			tExt[k]=v;
		end
		tClass = tExt;
	else
		_CLASSES[sName]=tClass;
	end
	
	--If the class has a post-register function set up we run it here
	if type(tClass.OnClassRegister)=="function" then
		local s,r=pcall(tClass.OnClassRegister,tClass);
		if !s then ErrorNoHalt("Itemforge Base: OnClassRegister event for class \""..sName.."\" failed: "..r.."\n") end
	end
	
	return tClass;
end

--[[
* SHARED

This is handled automatically, there's no need for a scripter to call this function.

This function carries out the inheritence between classes.
It will look at each registered class and attempt to inherit each class from it's respective .Base.
]]--
function MODULE:DoInheritance()
	for k,v in pairs(_CLASSES) do
		if v.ClassName!=BaseClassName then
			if v.Base then
				v.Base=string.lower(v.Base);
				
				if v.Base!=v.ClassName then
					--Set class's base-class to another class
					v.BaseClass=_CLASSES[v.Base];
					
					if v.BaseClass==nil then	--Couldn't find the base-class (note that all classes are loaded before bases are set - so the only reason this would happen is if the requested base-class isn't loaded or couldn't be loaded)
						ErrorNoHalt("Itemforge Base: Class \""..k.."\" could not inherit from class \""..v.Base.."\". \""..v.Base.."\"  could not be found.\n");
					end
				else
					ErrorNoHalt("Itemforge Base: Class \""..k.."\" cannot inherit from itself. This would cause an infinite loop.\n");
				end
			end
			
			--If BaseClass still hasn't been set, then we'll set the base to the base for all classes (except for itself of course)
			if v.BaseClass==nil then
				v.Base=BaseClassName;
				v.BaseClass=_CLASSES[BaseClassName];
			end
			
			--[[
			We'll also do something like C++ does with "myObject::InheritedClass" here.
			Lets say you have items that inherit like this (top inherits from bottom):
			item_crowbar
			base_melee
			base_weapon
			item
			
			You spawn an item_crowbar called "myItem".
			You can do myItem.BaseClass or myItem.base_melee to access base_melee's stuff.
			Likewise, if you want myItem to access base_weapon's stuff, you can do myItem.base_weapon.
			]]--
			v[v.Base]=v.BaseClass;
			
			setmetatable(v,_CLASSmt);
		else
			setmetatable(v,_BASECLASSmt);
		end
	end
	
	--After the inheritence is finalized, make sure that no child classes are
	--overriding protected keys in their parent, grandparent, etc. 
	local pc;
	for k,v in pairs(_CLASSES) do
		if v.ClassName!=BaseClassName then
			for a,b in pairs(v) do
				pc=IF.Base:IsProtectedKey(v.BaseClass,a);
				if pc then ErrorNoHalt("Itemforge Base: WARNING! "..tostring(k).." tried to override \""..tostring(a).."\", a protected function or value in the \""..pc.ClassName.."\" class.\n"); v[a]=nil; end
			end
		end
		
		--Run the post inherit function for this class
		local s,r=pcall(v.OnClassInherited,v);
		if !s then ErrorNoHalt("Itemforge Base: OnClassInherited event for class \""..k.."\" failed: "..r.."\n") end
	end
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
k should be the key you want to check to see if protected.

If the key is protected, the class who is protecting the key's table is returned.
nil is returned otherwise.
]]--
function MODULE:IsProtectedKey(tClass,k)
	local pk;
	while tClass!=nil do
		--[[
		We use rawget because inheritance would sometimes make us look at the same _ProtectedKeys more than once.
		e.g: Lets say this is the inheritance of weapon_smg:
		base < base_nw < base_item < base_weapon < base_ranged < base_firearm < weapon_smg
		base_item has protected keys but weapon_smg, base_firearm, base_ranged, base_weapon don't. That means we would be looking at base_item's protected keys a total of 5 times.
		]]--
		pk=rawget(tClass,"_ProtectedKeys");
		if pk && pk[k] then return tClass end
		
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
function MODULE:CreateObject(sClass)
	if !sClass then ErrorNoHalt("Itemforge Base: Could not create object. Class wasn't given."); return nil; end
	sClass=string.lower(sClass);
	local t=_CLASSES[sClass];
	
	--[[
	Make sure the class we want is valid (has loaded succesfully)
	If it's not, a few things could be causing this.
	    Parsing errors serverside or clientside may be at work (meaning there's probably a typo in your script)
	    If the item can be created serverside with no trouble, but can't be created clientside...
	        Make sure that all the necessary files are being sent (included with AddCSLuaFile). You can check this with the "dumptables" console command.
	        Check the server console. Apparently, lua files are compiled before they are sent to the clients. If there are parsing errors dealing with clientside files, this may be to blame.
	]]--
	if !t then
		if SERVER then	ErrorNoHalt("Itemforge Base: Could not create object, \""..sClass.."\" is not a valid class. Check for parsing errors in console or mis-spelled class name.\n"); 
		else			ErrorNoHalt("Itemforge Base: Could not create object, \""..sClass.."\" is not a valid class. Check for scripts not being sent!\n");
		end
		return nil;
	end
	
	
	local o={};		--Object
	o.Class=t;
	
	--Table of functions created specifically for this reference (lookup from table is faster than a strcmp)
	local f={
		--Returns true if the reference is valid
		IsValid		=	function() return (o!=nil); end,
		
		--Invalidates the object (basically deletes it)
		Invalidate	=	function() o=nil; end,
		
		--Returns a copy of everything unique to the object, so long as it's valid
		GetTable	=	function()
								if !o then ErrorNoHalt(IFB_EGT); return nil; end
								local tC={};
								for k,v in pairs(o) do tC[k]=v; end
								return tC;
						end
	};
	
	local mt={};
	
	--[[
	Objects draw their functions/data from three sources (checked in first to last order as listed here):
	  1. (f) References have their own set of functions which are linked to here.
	  2. (o) is the object itself. Anything unique to that individual object is stored here.
	  3. (t) is the class (or type) of the object. Anything in t or any inherited class is stored here.
	]]--
	function mt:__index(k)
		if f[k] then		return f[k];
		elseif o!=nil then
			if o[k] then		return o[k];
			else				return t[k];	end
		else				ErrorNoHalt(IFB_EI[1]..tostring(k)..IFB_EI[2]);
		end
	end
	
	--We want to forward writes to the object, so long as it's valid
	function mt:__newindex(k,v)
		if o!=nil then
			--Is the key protected? If so, on what class?
			local pc=IF.Base:IsProtectedKey(t,k);
			if pc then return self:Error(IFB_ENI[1]..tostring(k)..IFB_ENI[2]..pc.ClassName..IFB_ENI[3]); end
			
			if self:Event(IFB_ONI,true,k,v)==true then o[k]=v; end
		else
			ErrorNoHalt(IFB_ENI[4]..tostring(k)..IFB_ENI[5]..tostring(v)..IFB_ENI[6]);
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





--[[
* SHARED

This metatable protects the base class.
The base class has no inheritence.
See comments below for more information on class protection.
]]--
function _BASECLASSmt:__newindex(k,v)
	ErrorNoHalt("Itemforge Base: WARNING! Override blocked on class \""..self.ClassName.."\": Tried to set \""..tostring(k).."\" to \""..tostring(v).."\".\n");
	debug.Trace();
	Msg("\n");
end

--[[
* SHARED

This metatable handles class protection and inheritence.
Inheritence means the class can use everything from the class it's based off of (it's base-class).
If both the class and the base-class don't have it, nil is returned.

As for class protection, after a class is loaded, it shouldn't be modified. This can be bypassed, but it's here as a safeguard.
If a class is accidentally modified, a warning message will be generated and no changes will occur.
]]--
function _CLASSmt:__index(k)
	return self.BaseClass[k];
end

_CLASSmt.__newindex=_BASECLASSmt.__newindex;








--[[
* SHARED
* Different for each Class

Setting the base to the name of another class will make this class inherit the functions and values from that class.
You needn't use everything from the base-class. If both your class and it's base class have a function/value by the same name, the function/value in your class overrides the base class's function (unless the function/value is protected, in which case you'll get an error message at startup.)
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
* Different for each Object

When you create an object, it's Class is set to the class table of the class you created it from.
]]--
_BASE.Class=nil;

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
This includes if the item _IS_ what you're checking to see if it's based off of. If an item is an item_egg, then item:InheritsFrom("item_egg") will return true.
	
	Another example: lets say we want to determine if a given object is an item or an inventory.
		The base item is base_item, so we can do:
			if object:InheritsFrom("base_item")	then ... end
		The base inventory is base_inv, so we can do:
			if object:InheritsFrom("base_inv")	then ... end
	
	Another example, lets say we have three item types:
		base_weapon, base_melee, and item_sword.
	
		Inheritence is set up like so (right inherits from left:
		base_weapon < base_melee < item_sword
	
		Lets say we have a weapons salesman who will only buy weapons.
		We could check that the item we're trying to sell him is a weapon by doing:
		item:InheritsFrom("base_weapon")
		It would return true, because a sword is a melee weapon, and a melee weapon is a weapon.

sClass is the name of the class ("base_item", "base_container", "base_nw", etc.)
This function returns true if the item inherits from this item type, or false if it doesn't.
]]--
function _BASE:InheritsFrom(sClass)
	tClass=_CLASSES[string.lower(sClass)];
	if tClass==nil then return self:Error("Can't determine if this item is based off of \""..sClass.."\", this item-type could not be found.") end
	
	if self.Class==tClass then return true end
	
	while self!=nil do
		self=self.BaseClass;
		if self==tClass then return true end
	end
	return false;
end
_BASE._ProtectedKeys["InheritsFrom"]=true;

--[[
* SHARED
* Protected

Calls an event on the object.
If there is an error calling the event, a non-halting error message is generated and a default value is returned.

sEventName is a string which should be the name of the event to call (EX: "OnDraw2D", "OnThink", etc)
vDefaultReturn is what will be returned in case of errors calling the hook.
... - You can pass arguments to the hook here

This function returns two values: vReturn,bSuccess
	vReturn will be what the event returned, or if there were errors, then it will be vDefaultReturn.
	bSuccess will be true if the event was called successfully, or false if there were errors.

Example: I want to call this object's CanEnterWorld event:
	self:Event("CanEnterWorld",false,vPos,aAng);
	This runs an object's CanEnterWorld and gives it vPos and aAng as arguments.
	If there's a problem running the event, we want false to be returned.
]]--
function _BASE:Event(sEventName,vDefaultReturn,...)
	local f=self[sEventName];
	if !f then self:Error("\""..sEventName.."\" failed: This event does not exist."); return vDefaultReturn,false end
		
	local s,r=pcall(f,self,...);
	if !s then self:Error("\""..sEventName.."\" failed: "..r); return vDefaultReturn,false end
	
	return r,true;
end
_BASE._ProtectedKeys["Event"]=true;

--[[
* SHARED
* Protected

Calls an event that was inherited from one of the object's parent classes.

If you want to override an event so that it does everything it's parent does, plus something
extra, this is the event for you.

Example: I want to draw a health bar on all items, but on bottled water I want to draw
a water bar as well.

If there is an error calling the event, a non-halting error message is generated and a default value is returned.

strEventName is a string which should be the name of the event to call (EX: "OnDraw2D", "OnThink", etc)
strParentName is a string indicating which parent to take the event from.
	IMPORTANT: DO NOT GIVE self.BaseClass. Use "name_of_class" like this.
	
	Because of the way inheritence works in Itemforge, passing self.BaseClass will sometimes
	cause an infinite loop (Lua should report the error as "Stack overflow" or
	"infinite loop detected").
	
	Example of valid values: "base_melee", "base_item", "base_inv", etc.
	
vDefaultReturn is what will be returned in case of errors calling the hook.
... - You can pass arguments to the hook here

This function returns two values: vReturn,bSuccess
	vReturn will be what the event returned, or if there were errors, then it will be vDefaultReturn.
	bSuccess will be true if the event was called successfully, or false if there were errors.

Example:
	I want to make an OnUse event that does everything it's parent does plus what I want:
	function ITEM:OnUse(pl)
		if !self:InheritedEvent("OnUse","base_item",true,pl) then return true end
		
		if SERVER then self:Eat(pl) end
		return true;
	end
	
	Lets pretend this item is item_food, and it's based off of base_item.
	In this example we call base_item's OnUse event, passing the player we got.
	If a problem occurs when running the event, we want true to be returned.
	
	base_item's OnUse will make the player pick up the item up if it's in the world.
	In that case, true is returned and we return true in item_food's OnUse.
	
	But if false is returned, that means base_item couldn't figure out what to do when
	the item was used. So that's where we take over and tell the item to be eaten.
	We return true to indicate that we've handled the event.
]]--
function _BASE:InheritedEvent(strEventName,strParentName,vDefaultReturn,...)
	strParentName = string.lower(strParentName);
	local p=self[strParentName]
	if !p then self:Error("\""..strEventName.."\" from base \""..strParentName.."\" failed: \""..self.Classname.."\" is not based off of \""..strParentName.."\"."); return vDefaultReturn,false end
	
	local f=p[strEventName];
	if !f then self:Error("\""..strEventName.."\" from base \""..strParentName.."\" failed: This event does not exist on base class \""..strParentName.."\"."); return vDefaultReturn,false end
		
	local s,r=pcall(f,self,...);
	if !s then self:Error("\""..strEventName.."\" from base \""..strParentName.."\" failed: "..r); return vDefaultReturn,false end
	
	return r, true;
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