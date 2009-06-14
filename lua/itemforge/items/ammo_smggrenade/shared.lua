--[[
SMG Grenade Ammo
SHARED

This is ammunition for the SMG's grenade launcher.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="SMG Grenade";
ITEM.Description="Explosive grenades, fitted for an SMG grenade launcher.";
ITEM.Base="base_ammo";
ITEM.StartAmount=1;

ITEM.WorldModel="models/Items/AR2_Grenade.mdl";