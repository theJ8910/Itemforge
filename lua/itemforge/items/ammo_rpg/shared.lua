--[[
ammo_rpg
SHARED

This is ammunition for the Rocket-Propelled Grenade Launcher.
These are Rocket Propelled Grenades.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="RPG Round";
ITEM.Description="A mid-range explosive known as a rocket propelled grenade, commonly abbreviated as RPG.\nThese rounds must be fired from an RPG Launcher of some type.";
ITEM.Base="base_ammo";
ITEM.Size=16;
ITEM.Weight=1800;		--Based on http://science.howstuffworks.com/rpg2.htm
ITEM.StartAmount=1;

ITEM.WorldModel="models/weapons/W_missile_closed.mdl";

ITEM.HoldType="normal";

if CLIENT then

ITEM.WorldModelNudge=Vector(0,0,0);
ITEM.WorldModelRotate=Angle(0,0,0);

end