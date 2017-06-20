--[[
base_npc_spawner
SHARED

base_npc_spawner is a base. That means that other items borrow code from this so they can be created easier.
Any item that inherits from this has everything this item has, and can override anything this item has.

The base_npc_spawner item's purpose is to provide basic functions for items that create NPCs (such as rollermines, manhacks, and turrets).
Additionally, you can tell if something spawns an NPC by seeing if it's based off of this item.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name			= "Base NPC Spawner";
ITEM.Description	= "This item is the base NPC spawner.\nAll NPC spawning items inherit from this.\n\nThis is not supposed to be spawned.";

--We don't want players spawning it.
ITEM.Spawnable		= false;
ITEM.AdminSpawnable	= false;

--Base NPC Spawner
ITEM.NPCType = "npc_rollermine";				--This type of entity is created whenever the item is used.
ITEM.ForceAngry = {								--The spawned NPC will be forced to hate every type of NPC in this table.
	"npc_metropolice",
	"npc_cscanner",
	"npc_metropolice",
	"npc_combine_s",
	"npc_hunter",
	"npc_rollermine",
	"npc_manhack",
	"npc_turret_floor",
	"npc_breen",
};

function ITEM:OnUse( pl )
	if SERVER then
		local vPos = self:GetPos();
		local eEntity = self:GetEntity();

		local eSpawned = ents.Create( self.NPCType );
		eSpawned:SetPos( vPos );
		if eEntity then		eSpawned:SetAngles( eEntity:GetAngles() ) end
		eSpawned:Spawn();

		--Force the NPC to hate NPCs that it would otherwise be friendly with, and make it like the player who activated it.
		for k,v in pairs( self.ForceAngry ) do
			if v != self.NPCType then eSpawned:AddRelationship( v.." D_HT 99" ) end
		end
		eSpawned:AddEntityRelationship( pl, D_LI, 999 );

		self:Remove();
	end

	return true;
end