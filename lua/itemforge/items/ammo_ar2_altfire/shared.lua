--[[
ammo_ar2_altfire
SHARED

This is secondary ammo for the HL2 AR2, also known as the Overwatch Pulse Rifle.
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name				= "Combine Ball";
ITEM.Description		= "A container for some type of odd energy grenade.\n\nThe Overwatch Pulse rifle can make use of these.\nAdditionally, the grenade can be released by breaking or opening the container.";
ITEM.Base				= "base_ammo";
ITEM.Size				= 9;
ITEM.Weight				= 10;					--The type of metal alloy the combine use is a mystery.
ITEM.StartAmount		= 1;

ITEM.WorldModel			= "models/Items/combine_rifle_ammo01.mdl";

ITEM.SWEPHoldType		= "normal";

if CLIENT then

ITEM.Icon				= Material( "itemforge/items/ammo_ar2_altfire" );
ITEM.WorldModelNudge	= Vector( 0, 0, 0 );
ITEM.WorldModelRotate	= Angle( 0, 0, 0 );

end