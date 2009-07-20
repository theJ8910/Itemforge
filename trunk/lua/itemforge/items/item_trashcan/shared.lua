--[[
item_trashcan
SHARED

The trashcan periodically removes it's contents.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Trashcan";
ITEM.Description="A modern solution to unwanted refuse.\nOccasionally removes any unwanted items placed inside.";
ITEM.Base="base_container";
ITEM.WorldModel="models/props_trainstation/trashcan_indoor001a.mdl";

ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

if SERVER then

ITEM.ThinkRate=30;

function ITEM:OnInit()
	if !self["base_container"].OnInit(self) then return false end
	self.Inventory.RemovalAction=IFINV_RMVACT_REMOVEITEMS;
	self:StartThink();
end

function ITEM:OnThink()
	for k,v in pairs(self.Inventory:GetItems()) do
		v:Remove();
	end
end




else




function ITEM:OnConnectInventory(inv,conslot)
	if !self["base_container"].OnConnectInventory(self,inv,conslot) then return false end
	inv.RemovalAction=IFINV_RMVACT_REMOVEITEMS;
end




end
