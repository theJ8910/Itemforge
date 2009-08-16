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

if SERVER then




--Locks the footlocker
function ITEM:Lock()
	self.Inventory:Lock();
end

--Unlocks the footlocker
function ITEM:Unlock()
	self.Inventory:Unlock();
end

--Toggles between locked/unlocked
function ITEM:ToggleLock()
	if self.Inventory.Locked then
		self:Unlock();
	else
		self:Lock();
	end
end

--Runs when a player chooses "Lock"/"Unlock" from the right-click menu
function ITEM:PlayerToggleLock(pl)
	if !self:Event("CanPlayerInteract",false,pl) then return false end
	self:ToggleLock();
end

IF.Items:CreateNWCommand(ITEM,"PlayerToggleLock",function(self,pl) self:PlayerToggleLock(pl) end);




else




--We don't show the inventory if it's locked
function ITEM:ShowInventory()
	if self.Inventory && self.Inventory.Locked then return false end
	return self["base_container"].ShowInventory(self) 
end

--We have a "Lock"/"Unlock" option
function ITEM:OnPopulateMenu(pMenu)
	self["base_container"].OnPopulateMenu(self,pMenu);
	
	if !self.Inventory then return false end
	pMenu:AddOption( ((self.Inventory.Locked && "Unlock") || "Lock"), function(panel) return self:SendNWCommand("PlayerToggleLock"); end);
end

IF.Items:CreateNWCommand(ITEM,"PlayerToggleLock");




end