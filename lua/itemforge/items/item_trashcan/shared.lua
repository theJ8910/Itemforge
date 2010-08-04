--[[
item_trashcan
SHARED

The trashcan periodically removes it's contents.
]]--

include("inv_trashcan.lua");

if SERVER then
	AddCSLuaFile("shared.lua");
	AddCSLuaFile("inv_trashcan.lua");
end

ITEM.Name="Trashcan";
ITEM.Description="A modern solution to unwanted refuse.\nOccasionally removes any unwanted items placed inside.";
ITEM.Base="base_container";
ITEM.Weight=30000;
ITEM.Size=38;
ITEM.WorldModel="models/props_trainstation/trashcan_indoor001a.mdl";

if SERVER then
	ITEM.GibEffect = "metal";
end

ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

--Overridden Base Container stuff
ITEM.InvTemplate="inv_trashcan";

if SERVER then

ITEM.ThinkRate=30;

function ITEM:OnInit()
	if !self:BaseEvent("OnInit",false) then return false end
	self:StartThink();
end

function ITEM:OnThink()
	for k,v in pairs(self.Inventory:GetItems()) do
		v:Remove();
	end
end




end
