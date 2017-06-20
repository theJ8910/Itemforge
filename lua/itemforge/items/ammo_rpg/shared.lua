--[[
ammo_rpg
SHARED

This is ammunition for the Rocket-Propelled Grenade Launcher.
These are Rocket Propelled Grenades.
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name				= "RPG Round";
ITEM.Description		= "A mid-range explosive known as a rocket propelled grenade, commonly abbreviated as RPG.\nThese rounds must be fired from an RPG Launcher of some type.\nHandle carefully - highly explosive!";
ITEM.Base				= "base_ammo_explosive";
ITEM.Size				= 16;
ITEM.Weight				= 1800;		--Based on http://science.howstuffworks.com/rpg2.htm
ITEM.StartAmount		= 1;
ITEM.MaxAmount			= 5;

ITEM.WorldModel			= "models/weapons/W_missile_closed.mdl";

ITEM.SWEPHoldType		= "slam";

if CLIENT then

ITEM.Icon				= Material( "itemforge/items/ammo_rpg" );
ITEM.WorldModelNudge	= Vector( 1, 0, 5 );
ITEM.WorldModelRotate	= Angle( 80, 0, 0 );

end

--Overridden Base Explosive Ammo stuff
ITEM.ExplodeDamage		= 50;
ITEM.ExplodeRadius		= 128;
