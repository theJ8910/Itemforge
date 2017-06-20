--[[
item_healthpack
SHARED

Heals 30 hp
Coded By Kill CoDer
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name				= "Health Pack";
ITEM.Description		= "Heals 30 HP.";
ITEM.Size				= 12;
ITEM.Weight				= 2500;
ITEM.WorldModel			= "models/Items/HealthKit.mdl";
ITEM.MaxHealth			= 30;
ITEM.MaxAmount			= 10;

ITEM.SWEPHoldType		= "slam";

if CLIENT then




ITEM.WorldModelNudge	= Vector( 0, -7, 10 );
ITEM.WorldModelRotate	= Angle( -90, 180, 180 );




end

if SERVER then




--[[
* SERVER
* Event

Heals the player (to a max of 130 health).
]]--
function ITEM:OnUse( pl )
	if ( pl:Health() > 129 ) then
		pl:PrintMessage( 3, "You cannot be healed any futher!" );
		return false;
	end

	pl:SetHealth( math.Clamp( pl:Health() + 30, 0, 130 ) );
	self:SetAmount( self:GetAmount() - 1 );
	
	return true;
end




end  