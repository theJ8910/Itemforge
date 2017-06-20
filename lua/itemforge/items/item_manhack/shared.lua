--[[
item_manhack
SHARED

A friendly manhack.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name			= "Manhack";
ITEM.Description	= "Swarming, autonomous miniature helicopters with razor sharp blades.\nAct as lightweight scouts, exploring and clearing areas ahead of combine manpower.\nRather useless by themselves, but effective in large swarms.";
ITEM.Base			= "base_npc_spawner";
ITEM.Size			= 12;
ITEM.Weight			= 3694;	--23 kg

ITEM.Spawnable		= true;
ITEM.AdminSpawnable	= true;

ITEM.WorldModel		= "models/manhack.mdl";

if SERVER then
	ITEM.GibEffect = "metal";
end

--Overridden Base NPC Spawner stuff
ITEM.NPCType = "npc_manhack";