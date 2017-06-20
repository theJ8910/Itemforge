--[[ 
item_healthvial 
SHARED 

Heals 10 hp
Coded By Kill CoDer
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name				= "Health Vial";
ITEM.Description		= "Heals 10 HP.";
ITEM.Size				= 6;
ITEM.Weight				= 500;
ITEM.WorldModel			= "models/healthvial.mdl";
ITEM.MaxHealth			= 30;
ITEM.MaxAmount			= 10;

ITEM.SWEPHoldType		= "normal";

if CLIENT then




ITEM.WorldModelNudge	= Vector( 0, 0, -5 );
ITEM.WorldModelRotate	= Angle( 0, 0, 0 );




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
	pl:SetHealth( math.Clamp( pl:Health() + 10, 0, 130 ) );
	self:SetAmount( self:GetAmount() - 1 );
	return true;
end




end