--[[
ammo_flechette
SHARED

This is ammunition for the Flechette Gun.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Flechette";
ITEM.Description="Explosive, dagger-like hunter flechettes.";
ITEM.Base="base_ammo";
ITEM.Weight=20;			--The flechettes are pretty big, eh? Seems appropriate.
ITEM.Size=11;
ITEM.StartAmount=30;

ITEM.WorldModel="models/weapons/hunter_flechette.mdl";

if SERVER then
	ITEM.HoldType="melee";
else
	ITEM.WorldModelNudge=Vector(3,0,7);
	ITEM.WorldModelRotate=Angle(90,0,0);
end