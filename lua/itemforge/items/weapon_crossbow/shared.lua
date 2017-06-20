--[[
weapon_crossbow
SHARED

The Itemforge version of the Half-Life 2 Crossbow.
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name					= "Crossbow";
ITEM.Description			= "An unconvential, experimental weapon developed by the Resistance.\nA scope and industrial-sized battery is attached.\nRumor has it the weapon heats and launches bolts made of steel rebar.";
ITEM.Base					= "base_ranged";
ITEM.Weight					= 7000;				--Arbitrary.
ITEM.Size					= 30;

ITEM.Spawnable				= true;
ITEM.AdminSpawnable			= true;

ITEM.WorldModel				= "models/weapons/W_crossbow.mdl";
ITEM.ViewModel				= "models/weapons/v_crossbow.mdl";

if SERVER then




ITEM.GibEffect				= "metal";




end

ITEM.SWEPHoldType			= "crossbow";

--Overridden Base Weapon stuff
ITEM.HasPrimary				= true;
ITEM.PrimaryDelay			= 0.1;
ITEM.PrimarySounds			= Sound( "Weapon_Crossbow.Single" );

--Overridden Base Ranged Weapon stuff
ITEM.Clips					= {};
ITEM.Clips[1]				= { Type = "ammo_crossbow", Size = 1 };

ITEM.PrimaryClip			= 1;
ITEM.PrimaryFiresUnderwater	= true;


ITEM.ReloadDelay			= 1.8333333730698;
ITEM.ReloadSounds			= {
	Sound( "Weapon_Crossbow.Reload" ),
	--Weapon_Crossbow.BoltElectrify
	--Weapon_Crossbow.BoltFly
	--Weapon_Crossbow.BoltHitBody
	--Weapon_Crossbow.BoltHitWorld
	--Weapon_Crossbow.BoltSkewer
}

--[[
* SHARED
* Event

TODO fire crossbow bolts
]]--
function ITEM:OnPrimaryAttack()
end

--[[
* SHARED
* Event

TODO Secondary attack toggles scope zoom
]]--
function ITEM:OnSecondaryAttack()
end

--[[
* SHARED
* Event

This is a big weapon size-wise. Items of size 30 or greater can't be held, so we make an exception here.
]]--
function ITEM:CanHold( pl )
	return true;
end