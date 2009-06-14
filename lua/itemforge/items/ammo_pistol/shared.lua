--[[
ammo_pistol
SHARED

This is ammunition for the HL2 pistol.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Pistol Ammo";
ITEM.Description="This is 9mm caliber ammunition.";
ITEM.Base="base_ammo";
ITEM.StartAmount=20;

ITEM.WorldModel="models/Items/BoxSRounds.mdl";