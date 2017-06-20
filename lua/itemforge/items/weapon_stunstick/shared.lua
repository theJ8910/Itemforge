--[[
weapon_stunstick
SHARED

Pick up that can
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name			= "Stunstick";
ITEM.Description	= "An electrical stun baton similiar to a cattle prod.\nCombine Civil Protection often employ these batons when dealing with uncooperative citizens.";
ITEM.Base			= "base_melee";
ITEM.Size			= 12;
ITEM.Weight			= 1300;

ITEM.Spawnable		= true;
ITEM.AdminSpawnable	= true;

ITEM.WorldModel		= "models/weapons/W_stunbaton.mdl";
ITEM.ViewModel		= "models/weapons/v_stunstick.mdl";

if SERVER then




ITEM.GibEffect	= "metal";




end

--Overridden Base Weapon stuff
ITEM.HasPrimary		= true;
ITEM.PrimaryDelay	= 0.9;
ITEM.ViewKickMin	= Angle( 1.0, -2.0, 0 );
ITEM.ViewKickMax	= Angle( 2.0, -1.0, 0 );

--Overridden Base Melee stuff
ITEM.HitRange		= 75;
ITEM.HitForce		= 2;
ITEM.HitDamage		= 40;

ITEM.HitSounds = {
	Sound( "Weapon_StunStick.Melee_Hit" )
}

ITEM.MissSounds = {
	Sound( "Weapon_StunStick.Melee_Miss" )
}

--Stunstick
ITEM.DeploySounds = {
	Sound( "Weapon_StunStick.Activate" )
}

ITEM.HolsterSounds = {
	Sound( "Weapon_StunStick.Deactivate" )
}

--[[
* SHARED
* Event

The stunstick sparks on whne it's deployed
]]--
function ITEM:OnSWEPDeploy()
	if !self:BaseEvent( "OnSWEPDeploy", false ) then return false end
	self:EmitSound( self.DeploySounds, true );
	
	return true;
end

--[[
* SHARED
* Event

The stunstick sparks off when it's holstered
]]--
function ITEM:OnSWEPHolster()
	if !self:BaseEvent( "OnSWEPHolster", false ) then return false end
	self:EmitSound( self.HolsterSounds, true );
	
	return true;
end