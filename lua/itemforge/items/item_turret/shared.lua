--[[
item_turret
SHARED

A friendly combine floor turret.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name			= "Floor Turret";
ITEM.Description	= "An automated sentry turret that can be deployed.";
ITEM.Base			= "base_npc_spawner";
ITEM.Size			= 42;
ITEM.Weight			= 75000;	--75 kg

ITEM.Spawnable		= true;
ITEM.AdminSpawnable	= true;

ITEM.WorldModel		= "models/Combine_turrets/Floor_turret.mdl";

if SERVER then
	ITEM.GibEffect = "metal";
end

--Overridden Base NPC Spawner stuff
ITEM.NPCType = "npc_turret_floor";