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

--Itemforge Class metatable
local _CLASSmt={};

--Base Itemforge Object class
local _BASE={};





--Initilize base module
function MODULE:Initialize()
	self:RegisterClass(_BASE,BaseClassName);
end

--[[
Cleanup base module
]]--
function MODULE:Cleanup()
end

function MODULE:RegisterClass(tClass,sName)
	if !tClass then ErrorNoHalt("Itemforge Base: Couldn't register class. Class table wasn't given."); return false; end
	if !sName then ErrorNoHalt("Itemforge Base: Couldn't register class. The name of the class was not given."); return false; end
	
	tClass.Type=sName;
	
	--If this item type is already loaded just empty out the existing table; that way existing items of this type are instantly updated with the new contents.
	if _CLASSES[sName] then
		table.CopyFromTo(tClass,_CLASSES[sName]);
		return true;
	end
	
	_CLASSES[sName]=tClass;
end

function MODULE:DoInheritance()
	for k,v in pairs(_CLASSES) do
		if v.Type!=BaseClassName then
			if v.Base then
				v.Base=string.lower(v.Base);
				
				if v.Base!=v.type then
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
			
			--We'll also do something like C++ does with "myObject::InheritedClass" here.
			--[[
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
		end
	end
end

function MODULE:CreateObject(sClass)
	if !sClass then ErrorNoHalt("Itemforge Base: Could not create object. Class wasn't given."); return false; end
	local t=_CLASSES[sClass]
	if !t then ErrorNoHalt("Itemforge Base: Could not create object. \""..sClass.."\" is not a registered class.\n"); return false end
	
	local r={};		--Reference
	
	local o={};		--Object
	o.Class=t;
	
	--Table of functions created specifically for this reference (lookup from table is faster than a strcmp)
	local f={
		--Returns true if the reference is valid
		IsValid		=	function() return (o!=nil); end,
		
		--Invalidates the object (basically deletes it)
		Invalidate	=	function() o=nil; end,
		
		--Returns a copy of everything in the object, so long as it's valid
		GetTable	=	function()
								if !o then ErrorNoHalt("Itemforge Base: Couldn't grab object table from removed object.\n"); return false; end
								local tC={};
								for k,v in pairs(o) do tC[k]=v; end
								return tC;
						end
	};
	
	local mt={};
	
	--Objects draw their functions/data from three sources (checked in first to last order as listed here):
	--1. (f) References have their own set of functions which are linked to here.
	--2. (o) is the object itself. Anything unique to that individual object is stored here.
	--3. (t) is the class (or type) of object. Anything in t or any inherited class is stored here.
	function mt:__index(k)
		if f[k] then		return f[k];
		elseif o!=nil then
			if o[k] then		return o[k];
			else				return t[k];	end
		else				ErrorNoHalt("Itemforge Base: Couldn't reference \""..tostring(k).."\" on removed object.\n");
		end
	end
	
	--We want to forward writes to the object, so long as it's valid
	function mt:__newindex(k,v)
		if o!=nil then
			if f[k] then ErrorNoHalt("Itemforge Base: WARNING! "..tostring(self).." tried to override \""..tostring(k).."\", a protected object reference function.\n"); return false end
			--[[
			if IF.Items:IsProtectedKey(k) then
				ErrorNoHalt("Itemforge Items: WARNING! "..tostring(self).." tried to override \""..tostring(k).."\", a protected function or value in the base item-type.\n");
				return false;
			end
			]]--
			
			o[k]=v;
		else
			ErrorNoHalt("Itemforge Base: Couldn't set \""..tostring(k).."\" to \""..tostring(v).."\" on removed object.\n");
			return false;
		end
	end
	
	--[[
	When tostring() is performed on an object reference, it returns a string containing some information about the item.
	Format: "Item ID [ITEM_TYPE]xAMT" 
	Ex:		"Item 5 [item_crowbar]" (Item 5, a single crowbar)
	Ex:		"Item 3 [item_rock]x53" (Item 3, a stack of 53 item_rocks)
	Ex:		"Object [invalid]" (used to be some kind of object, invalid/has been removed/no longer exists)
	Ex:		"Inventory 2" (Is inventory 2)
	]]--
	function mt:__tostring()
		if o!=nil then
			if o.ToString then
				local s,r=pcall(o.ToString,o);
				if s then return r
				else	  return "(ToString error: "..r..")"; end
			else
				return "Object";
			end
		else
			return "Object [invalid]";
		end
	end
	
	setmetatable(r,mt);
	
	return r;
end


function _CLASSmt:__index(k)
	return self.BaseClass[k];
end

function _CLASSmt:__newindex(k,v)
	ErrorNoHalt("WARNING! Override blocked on class \""..self.Type.."\": Tried to set \""..k.."\" to \""..v.."\".\n");
end




--[[
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
	if !f then self:Error("Itemforge Base: "..sEventName.." ("..tostring(self)..") failed: This event does not exist."); return vDefaultReturn,false end
		
	local s,r=pcall(f,self,...);
	if !s then self:Error("Itemforge Base: "..sEventName.." ("..tostring(self)..") failed: "..r); return vDefaultReturn,false end
	
	return r,true;
end

--[[
Returns true if this object inherits from the given class, false if it doesn't.
]]--
function _BASE:InheritsFrom(sClass)
	return false;
end

--[[
Generates a non-halting error message.
sErrorMsg is the message to display.
Always returns false.
]]--
function _BASE:Error(sErrorMsg)
	ErrorNoHalt("("..tostring(self)..")  "..sErrorMsg.."\n");
	return false;
end

function _BASE:ToString()
	return "Object";
end