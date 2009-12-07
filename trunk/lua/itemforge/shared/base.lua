--[[
Itemforge Base Module
SERVER

This module creates a base class that contains functionality used by both items and inventories.
]]--

MODULE.Name="Base";												--Our module will be stored at IF.Base
MODULE.Disabled=false;											--Our module will be loaded

--Base Itemforge Object class
local _BASEmt={};
local _BASE={}
_BASE.Module="Itemforge Base";									--The name of the module associated with this object (IE, "Itemforge Items", "Itemforge Inventory", etc).

--Initilize base module
function MODULE:Initialize()
end

--[[
Cleanup base module
]]--
function MODULE:Cleanup()
end

--[[
The given class (table) will inherit from the Itemforge Base
tClass is expected to be a class table. A class table is something like an Item-Type, Inventory Template, the Base Networked Class etc.
]]--
function MODULE:Derive(tClass)
	setmetatable(tClass,_BASEmt);
	return tO;
end

function _BASEmt:__index(k)
	return _BASE[k];
end

function _BASEmt:__newindex(k,v)
	self:Error("WARNING! Override blocked: Tried to set \""..k.."\" to \""..v.."\".\n");
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
	if !f then self:Error(sEventName.." ("..tostring(self)..") failed: This event does not exist."); return vDefaultReturn,false end
		
	local s,r=pcall(f,self,...);
	if !s then ErrorNoHalt(sEventName.." ("..tostring(self)..") failed: "..r); return vDefaultReturn,false end
	
	return r,true;
end

--[[
Generates a non-halting error message.
sErrorMsg is the message to display.
Always returns false.
]]--
function _BASE:Error(sErrorMsg)
	ErrorNoHalt(self.Module..": "..sErrorMsg.."\n");
	return false;
end

--[[
Stops the given key from being changed
]]--
function _BASE:Protect(key)

end