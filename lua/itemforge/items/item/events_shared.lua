--[[
events_shared
SHARED

item is the default item. All items except item inherit from this item-type.
NOTE: The item type is the name of the folder it is in (this is item/shared_events.lua, so this item's type is "item")

This specific file deals with events that are present on both the client and server.
]]--

--[[
ITEM EVENTS
]]--

--[[
Returns the name of the item.
]]--
function ITEM:GetName()
	return self.Name;
end

--[[
Returns the item's description.
]]--
function ITEM:GetDescription()
	return self.Description;
end

--[[
This hook is called whenever a player tries to do something with an item (use it, hold it, etc).
Itemforge uses this in some places, but you can use this hook to check if a player can interact with something youself. EX:
	if !self:CanPlayerInteract(PLAYER) then return false end
If this hook returns true, then you're allowing the player to interact with an item in some way.
If this hook returns false, then the player can't interact with an item in some way.

This hook is --VERY IMPORTANT--
Players can do all sorts of things with items - dragdrop them to world/an inventory, use them, load guns with them, etc.
This function double checks that the player is ALLOWED to do this at the moment.
Otherwise, the player could load ammo half-way across the map, or use items in a locked inventory.
]]--
function ITEM:CanPlayerInteract(pl)
	--The player can't interact with private items he doesn't own
	if SERVER && !self:CanSendItemData(pl) then return false end
	
	--And the player must be nearby the item in order to interact with it
	local pos=self:GetPos();
	local postype=type(pos);
	if postype=="Vector" then
		if pos:Distance(pl:GetPos())<=256 then return true end
	elseif postype=="table" then
		for k,v in pairs(pos) do
			if v:Distance(pl:GetPos())<=256 then return true end
		end
	end
	
	return false;
end

--This event is called after an inventory has been connected to the item.
function ITEM:OnConnectInventory(inv,conslot)
end

--This event is called after an inventory has been severed from the item.
function ITEM:OnSeverInventory(inv)
end