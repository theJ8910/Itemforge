--[[
ammo_357
SHARED

This is ammunition for the HL2 .357 Revolver.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name=".357 Ammo";
ITEM.Description="This is .357 caliber revolver ammunition.";
ITEM.Base="base_ammo";
ITEM.StartAmount=6;

ITEM.WorldModel="models/Items/357ammo.mdl";