--[[
ammo_smg
SHARED

Submachine Gun ammo.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="SMG Ammo";
ITEM.Description="A bucket of 4.6x30mm rounds; brass-jacketed, steel core.";
ITEM.Base="base_ammo";
ITEM.StartAmount=45;

ITEM.WorldModel="models/Items/BoxMRounds.mdl";