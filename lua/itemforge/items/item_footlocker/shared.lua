--[[
item_footlocker
SHARED

A lockable container.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Footlocker";
ITEM.Description="A wooden box with a lock to secure possessions.";
ITEM.Base="base_container";
ITEM.WorldModel="models/props/CS_militia/footlocker01_closed.mdl";

ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

ITEM.LockSound=Sound("doors/handle_pushbar_locked1.wav");
ITEM.UnlockSound=Sound("doors/latchunlocked1.wav");
ITEM.CantOpenSound=Sound("doors/latchlocked2.wav");

--[[
Runs when a player chooses "Lock"/"Unlock" from the right-click menu
If this is running on the server we actually lock/unlock the container
If this is running on the client we ask the server to unlock it
]]--
function ITEM:PlayerToggleLock(pl)
	if !self:Event("CanPlayerInteract",false,pl) then return false end
	if SERVER then
		self:ToggleLock();
	else
		self:SendNWCommand("PlayerToggleLock");
	end
end

--We don't show the inventory if it's locked
function ITEM:ShowInventory()
	if self.Inventory && self.Inventory:IsLocked() then
		self:EmitSound(self.CantOpenSound);
		return false;
	end
	return self["base_container"].ShowInventory(self);
end

if SERVER then




--Locks the footlocker
function ITEM:Lock()
	self:EmitSound(self.LockSound);
	self.Inventory:Lock();
end

--Unlocks the footlocker
function ITEM:Unlock()
	self:EmitSound(self.UnlockSound);
	self.Inventory:Unlock();
end

--Toggles between locked/unlocked
function ITEM:ToggleLock()
	if self.Inventory:IsLocked() then
		self:Unlock();
	else
		self:Lock();
	end
end

IF.Items:CreateNWCommand(ITEM,"PlayerToggleLock",function(self,...) self:PlayerToggleLock(...) end);




else




--We have a "Lock"/"Unlock" option
function ITEM:OnPopulateMenu(pMenu)
	self["base_container"].OnPopulateMenu(self,pMenu);
	
	if !self.Inventory then return false end
	pMenu:AddOption( ((self.Inventory:IsLocked() && "Unlock") || "Lock"), function(panel) self:PlayerToggleLock(LocalPlayer()) end);
end

IF.Items:CreateNWCommand(ITEM,"PlayerToggleLock");




end