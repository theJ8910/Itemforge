--[[
item_turnlock
SHARED

This is a simple lock. Attach it to doors or containers, then use it to lock or unlock.
This is best used to secure the inside of buildings.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Turn Lock";
ITEM.Description="A basic deadbolt.\nAttach it to something, then turn it to lock/unlock it.\n\nThis is best when used inside.";
ITEM.Base="base_lock";
ITEM.Size=4;
ITEM.Weight=350;
ITEM.MaxHealth=300;
ITEM.WorldModel="models/props_citizen_tech/Firetrap_button01a.mdl";

ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

--Turn Lock
ITEM.TurnSound=Sound("buttons/lever7.wav");

function ITEM:LockAttachment()
	if !self:BaseEvent("LockAttachment",false) then return false end
	self:EmitSound(self.TurnSound);
end

function ITEM:UnlockAttachment()
	if !self:BaseEvent("UnlockAttachment",false) then return false end
	self:EmitSound(self.TurnSound);
end