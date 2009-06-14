--[[
base_ammo
SHARED

base_ammo is a base. That means that other items borrow code from this so they can be created easier.
Any item that inherits from this has everything this item has, and can override anything this item has.

The base_ammo item's purpose is to create some basic stuff that all ammo has in common.
Additionally, you can tell if something is ammunition by seeing if it's based off of this item.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Base Ammunition";
ITEM.Description="This item is the base ammunition.\nAll ammunition inherits from this.\n\n This is not supposed to be spawned.";
ITEM.Base="item";

ITEM.MaxAmount=0;		-- ./~ Stack that ammo to the ska-aay ./~

--We don't want players spawning it.
ITEM.Spawnable=false;
ITEM.AdminSpawnable=false;

--[[
I noticed players will press [USE] on ammo when they want to load their guns with it.
If a player uses this ammo while holding an item based off of base_ranged, we'll try to load his gun with it.
If the ammo is used clientside, we won't actually load the gun, we'll just return true to indiciate we want the server to load the gun.
]]--
function ITEM:OnUse(pl)
	local wep=pl:GetActiveWeapon();
	if wep:IsValid() then
		local item=IF.Items:GetWeaponItem(wep);
		if item && item:InheritsFrom("base_ranged") && (CLIENT || item:Load(self) ) then
			return true;
		end
	end
	
	--We couldn't load whatever the player was carrying, so just do the default OnUse
	return self["item"].OnUse(self,pl);
end

