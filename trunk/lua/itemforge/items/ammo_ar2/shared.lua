--[[
ammo_ar2
SHARED

This is ammunition for the AR2, also known as the Overwatch Standard-Issue Pulse Rifle.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Pulse Ammunition";
ITEM.Description="An advanced high-energy pulse ammunition created and employed by the Combine.\nThis ammunition is employed by various combine forces including the Overwatch Pulse Rifle, Sentry Turrets, and Mounted Turrets.";
ITEM.Base="base_ammo";
ITEM.Size=9;
ITEM.Weight=10;			--The type of metal alloy the combine use is a mystery.
ITEM.StartAmount=20;

ITEM.WorldModel="models/Items/combine_rifle_cartridge01.mdl";

ITEM.HoldType="normal";

if CLIENT then

ITEM.WorldModelNudge=Vector(0,0,0);
ITEM.WorldModelRotate=Angle(0,0,0);

end