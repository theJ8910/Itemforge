--[[
item_rollermine
SHARED

A friendly rollermine.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name			= "Rollermine";
ITEM.Description	= "Spherical, heavily armored robots.\nAttacks with powerful electric shocks.\nAdditionally, they can latch onto and disable vehicles.";
ITEM.Base			= "base_npc_spawner";
ITEM.Size			= 21;
ITEM.Weight			= 23000;	--23 kg

ITEM.Spawnable		= true;
ITEM.AdminSpawnable	= true;

ITEM.WorldModel		= "models/Roller.mdl";

if SERVER then
	ITEM.GibEffect = "metal";
end

--Overridden Base NPC Spawner stuff
ITEM.NPCType = "npc_rollermine";