--[[
weapon_rpg
SHARED

The Itemforge version of the Half-Life 2 RPG Launcher.
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name					= "MBT LAW";
ITEM.Description			= "This is a Rocket Propelled Grenade launcher.\n This particular model is known as the Main Battle Tank and Light Armour Weapon, abbreviated MBT LAW.\nThis Swedish weapon was developed by Saab Bofors Dynamics.\nThis device has an optional targeting laser that can guide laser-guided RPGs.";
ITEM.Base					= "base_ranged";
ITEM.Weight					= 1160;				--Based upon http://www.army-technology.com/projects/mbt_law/
ITEM.Size					= 27;

ITEM.WorldModel				= "models/weapons/w_rocket_launcher.mdl";
ITEM.ViewModel				= "models/weapons/v_RPG.mdl";

if SERVER then




ITEM.GibEffect				= "metal";




end

ITEM.SWEPHoldType			= "rpg";

ITEM.Spawnable				= true;
ITEM.AdminSpawnable			= true;

--Overridden Base Weapon stuff
ITEM.HasPrimary				= true;
ITEM.PrimaryDelay			= 2;						--Taken directly from the modcode.
ITEM.PrimarySounds			= Sound( "weapons/357/357_fire2.wav" );

--Overridden Base Ranged Weapon stuff
ITEM.Clips					= {};
ITEM.Clips[1]				= { Type = "ammo_rpg", Size = 1 };

ITEM.PrimaryClip			= 1;
ITEM.PrimaryFiresUnderwater	= false;


ITEM.ReloadDelay			= 3.6666667461395;
ITEM.ReloadSounds			= nil;

ITEM.DryFireDelay			= 0.2;

--[[
* SHARED
* Event

TODO: Primary Attack
]]--
function ITEM:OnPrimaryAttack()
end

--[[
* SHARED
* Event

TODO: Secondary Attack

This toggles the LAW's laser sight.
If the laser sight is off the missiles will simply move in a straight line.
]]--
function ITEM:OnSecondaryAttack()
	--Secondary attack swaps firemode
	self:SetNWVar( "LaserSight", !self:GetNWVar( "LaserSight" ) );
end

IF.Items:CreateNWVar( ITEM, "LaserSight", "bool", true, nil );