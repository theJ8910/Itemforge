--[[
item_trashcan
SHARED

The trashcan periodically removes it's contents.
]]--

include( "inv_trashcan.lua" );

if SERVER then
	AddCSLuaFile( "shared.lua" );
	AddCSLuaFile( "inv_trashcan.lua" );
end

ITEM.Name			= "Trashcan";
ITEM.Description	= "A modern solution to unwanted refuse.\nOccasionally removes any unwanted items placed inside.";
ITEM.Base			= "base_container";
ITEM.Weight			= 30000;
ITEM.Size			= 38;
ITEM.WorldModel		= "models/props_trainstation/trashcan_indoor001a.mdl";

ITEM.Spawnable = true;
ITEM.AdminSpawnable = true;

if SERVER then




ITEM.GibEffect = "metal";




end



--Overridden Base Container stuff
ITEM.InvType = "inv_trashcan";

if SERVER then




--[[
* SERVER
* Event

The trashcan starts it's think as soon as it's created.
]]--
function ITEM:OnInit()
	if !self:BaseEvent( "OnInit", false ) then return false end
	self:StartThink();
end

--[[
* SERVER
* Event

Every 30 seconds the trashcan removes the items in it's inventory.
]]--
function ITEM:OnThink()
	for k, v in pairs( self.Inventory:GetItems() ) do
		v:Remove();
	end
	self:SetNextThink( CurTime() + 30 );
end




end
