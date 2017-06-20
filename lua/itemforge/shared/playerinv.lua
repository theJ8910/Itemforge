--[[
Itemforge Player Inventory module
SERVER

This module begrudgingly gives players inventories.
]]--

MODULE.Name		= "PlayerInv";									--Our module will be stored at IF.PlayerInv
MODULE.Disabled = false;										--Our module will be loaded

if SERVER then

MODULE.Give		= true;											--Should inventories automatically be given to players when they join?
MODULE.InvType	= nil;											--This is the type of inventory we'll give to players. If this is nil, gives a generic inventory.

end

--[[
* SHARED

Initilize player inventory module
]]--
function MODULE:Initialize()
	if SERVER && IF.Inv then
		hook.Add( "PlayerSpawn", "itemforge_playerinv_give", function(pl) timer.Simple( 5, IF.PlayerInv.GivePlayerInventory, IF.PlayerInv, pl ) end )
	end
end

--[[
* SHARED

Cleanup player inventory module
]]--
function MODULE:Cleanup()
	if SERVER then
		hook.Remove( "PlayerSpawn", "itemforge_playerinv_give" )
	end
end

--[[
* SHARED

This is more or less the example function from base_ranged/findammo.lua used for locating items in player inventories
]]--
list.Add( "Itemforge_BaseRanged_FindAmmo", function( self, fnCallback )
	local plOwner = self:GetWOwner();
	if !plOwner then return false end

	local inv = IF.PlayerInv:GetPlayerInventory( plOwner );
	if !inv then return false end
	
	for k, v in pairs( inv:GetItems() ) do
		if fnCallback( self, v ) then
			return v;
		end
	end
	
	return nil;
end )

if SERVER then



--[[
* SERVER

Gives the given player an inventory
]]--
function MODULE:GivePlayerInventory( pl )
	if !self.Give then return end
	if !pl || !pl:IsValid() then return false end
	if pl.ItemforgeInventory then return false end
	
	local inv = IF.Inv:Create( self.InvType );
	inv.RemovalAction = IFINV_RMVACT_REMOVEITEMS;
	inv:ConnectEntity( pl );
	pl.ItemforgeInventory = inv;
	pl:SetNWInt( "itemforge_inventory_id", inv:GetID() );
	
	return true;
end

--[[
* SERVER

Sets whether or not inventories are given to joining players
]]--
function MODULE:SetGiven( bGive )
	self.Give = bGive;
end

--[[
* SERVER

Returns true if inventories are given to players, false otherwise
]]--
function MODULE:GetGiven()
	return self.Give;
end

--[[
* SERVER

Sets the type of inventory given to players.

strType should be the inventory type's name.
]]--
function MODULE:SetType( strType )
	self.InvType = strType;
end

--[[
* SERVER

Returns the type of inventory given to players.
]]--
function MODULE:GetType()
	return self.InvType;
end

--[[
* SERVER

Returns the inventory assigned to the given player
]]--
function MODULE:Get( pl )
	if !pl || !pl:IsValid() then return nil end
	if pl.ItemforgeInventory && !pl.ItemforgeInventory:IsValid() then pl.ItemforgeInventory = nil end
	return pl.ItemforgeInventory;
end




else



--[[
* CLIENT

Returns the inventory assigned to the given player
]]--
function MODULE:Get( pl )
	if !pl || !pl:IsValid() then return nil end
	
	if pl.ItemforgeInventory && pl.ItemforgeInventory:IsValid() then
		return pl.ItemforgeInventory;
	else
		local id = pl:GetNWInt( "itemforge_inventory_id" )
		if id == 0 then return nil end
		
		local inv = IF.Inv:Get( id );
		if !inv || !inv:IsValid() then return nil end
		
		pl.ItemforgeInventory = inv;
	end
	return inv;
end

--[[
* CLIENT

Creates an inventory window and displays the local player's inventory
]]--
function MODULE:ShowLocalPlayerInventory()
	local pl = LocalPlayer();
	local inv = self:GetPlayerInventory( pl );
	if !inv then return false end
	
	pl.InventoryPanel = vgui.Create( "ItemforgeInventory" );
	pl.InventoryPanel:SetInventory( inv );
	
	return true;
end

concommand.Add( "show_inventory", function( pl, command, args ) return IF.PlayerInv:ShowLocalPlayerInventory() end );




end