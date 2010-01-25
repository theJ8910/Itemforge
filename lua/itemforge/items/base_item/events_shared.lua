--[[
events_shared
SHARED

base_item is the default item. All items except base_item inherit from this item-type.
NOTE: The item type is the name of the folder it is in (this is base_item/shared_events.lua, so this item's type is "base_item")

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
* SHARED

When tostring() is performed on an item reference, it returns a string containing some information about the item.
Format: "Item ID [ITEM_TYPE]xAMT"
Ex:		"Item 5 [item_crowbar]" (Item 5, a single crowbar)
Ex:		"Item 3 [item_rock]x53" (Item 3, a stack of 53 item_rocks)
Ex:		"Object [invalid]" (used to be some kind of object, invalid/has been removed/no longer exists)
Ex:		"Inventory 2" (Is inventory 2)
]]--
function ITEM:ToString()
	if self:GetMaxAmount()!=1 then	return "Item "..self:GetID().." ["..self:GetType().." x "..self:GetAmount().."]";
	else							return "Item "..self:GetID().." ["..self:GetType().."]"; end
end

--[[
If an item is in the void, this hook can be used to return it's position in the world.
This hook can return nil, a vector, or a table of vectors.
]]--
function ITEM:GetVoidPos()
end

--[[
This hook is called whenever a player tries to do something with an item (use it, hold it, drag it to world, merge it with something, etc).
Itemforge uses this in some places, but you can use this hook to check if a player can interact with something youself. EX:
	if !self:Event("CanPlayerInteract",false,PLAYER) then return false end
If this hook returns true, then you're allowing the player to interact with an item in some way.
If this hook returns false, then the player can't interact with an item in some way.

This hook is --VERY IMPORTANT--
Players can do all sorts of things with items - dragdrop them to world/an inventory, use them, load guns with them, etc.
This function double checks that the player is ALLOWED to do this at the moment.
Otherwise, the player could load ammo half-way across the map, or use items in a locked inventory.
]]--
function ITEM:CanPlayerInteract(pl)
	--The player has to be alive to interact with anything
	if !pl:Alive() then return false end
	
	--Clientside, we make sure the local player is interacting with items and not some other player (IE, if this client is controlling Player 1, only Player 1 can interact with an item on this client)
	if CLIENT && pl!=LocalPlayer() then	return false end
	
	--If the item is in an inventory, will the inventory let the players interact with it?
	local c=self:GetContainer();
	if c && !c:Event("CanPlayerInteract",false,pl,self) then return false end
	
	--If the item is held, only the player holding it can interact with it.
	if self:IsHeld() && self:GetWOwner()!=pl then
		return true;
	--Otherwise, the player must be nearby the item in order to interact with it
	else
		local pos=self:GetPos();
		local postype=type(pos);
		if postype=="Vector" then
			if pos:Distance(pl:GetPos())<=256 then return true end
			
		--If we're in several locations we have to be nearby at least one (this happens when an item is in an inventory connected to several objects)
		elseif postype=="table" then
			for k,v in pairs(pos) do
				if v:Distance(pl:GetPos())<=256 then return true end
			end
		else
			return false;
		end
	end
end

--[[
Can the item move to an inventory at the given slot?
This is run when the item wants to:
	Enter an inventory
	Move from one inventory to another
	Change slots in an inventory
	Leave an inventory

The purpose of this event is to give the item a chance to choose where it can and can't go.
Serverside, if this function returns false it stops the item from moving to/from/within an inventory. Returning true allows it to move.

If the item isn't in an inventory but is being moved to one:
	OldInv and OldSlot will be nil.
	NewInv and NewSlot will be the inventory and slot it's moving to.
If the item is being removed from an inventory but isn't going to one:
	OldInv and OldSlot will be the inventory and slot it was in.
	NewInv and NewSlot will be nil.
If the item is being moved from one inventory to a different inventory(ex: moving an item from a player's inventory to a crate): 
	OldInv and OldSlot will be the inventory and slot it was in.
	NewInv and NewSlot will be the inventory and slot it's going to.
If the item is moving from one slot to another in the same inventory:
	OldInv and NewInv will be the same inventory.
	OldSlot will be where the item is moving from.
	NewSlot is where the item wants to move to.

Returning true will allow the item to be placed in and/or removed from an inventory with the given slot.
Returning false will stop the item from moving from inventory to inventory / slot to slot.

TODO this event needs to be called in more places, and PROPERLY for that matter
]]--
function ITEM:CanMove(OldInv,OldSlot,NewInv,NewSlot)
	return true;
end

--[[
This is run when the item is moved from one inventory to another (or from one slot in an inventory to another).
The purpose of this event is to give the item a chance to allow it to choose where it can and can't go.

If the item is being moved from one inventory to a different inventory(ex: moving an item from a player's inventory to a crate): 
	OldInv and OldSlot will be the inventory and slot it was in.
	NewInv and NewSlot will be the inventory and slot it's going to.
If the item is moving from one slot to another in the same inventory:
	OldInv and NewInv will be the same inventory.
	OldSlot will be where the item is moving from.
	NewSlot is where the item wants to move to.
If the item isn't in an inventory but is being moved to one:
	OldInv and OldSlot will be nil.
	NewInv and NewSlot will be the inventory and slot it's moving to.
If the item is being removed from an inventory but isn't going to one:
	OldInv and OldSlot will be the inventory and slot it was in.
	NewInv and NewSlot will be nil.


If forced is true (usually due to forced removal from an inventory because the item is being removed), then returning false will not stop the item from being moved.
TODO this event needs to be called in more places, and PROPERLY for that matter
]]--
function ITEM:OnMove(OldInv,OldSlot,NewInv,NewSlot,forced)
	--If we're moving the item to an inventory
	if NewInv then return true end
	
	return true;
end

--[[
Can the item be placed in the world at the given position and angles?

Serverside, if this returns false, attempts to place the item in the world will fail.
Clientside, the function returning true/false is only good for prediction purposes.

vPos is a Vector(), the position it's trying to enter at.
aAng is an Angle(), describing the orientation it's trying to enter at.
bTeleport is a true/false. If this is true, the item is already in the world - it just wants to teleport to the given position/angles.

Return false to stop the item from entering the world, or return true to allow it to enter the world.
]]--
function ITEM:CanEnterWorld(vPos,aAng,bTeleport)
	return true;
end

--[[
This event is called after the item has entered the world.
This runs any time item:ToWorld() was called successfully, including when the item was already in the world and was teleported.

eEnt is the item's world entity. It should be the same thing as item:GetEntity().
vPos is the position it's trying to be inserted at.
aAng is the angle it's trying to be inserted at.
bTeleport will be true if the item was already in the world and was just teleported to the given position instead. If this is false, it means that a new entity was created for the item.
]]--
function ITEM:OnEnterWorld(eEnt,vPos,aAng,bTeleport)
	--DEBUG
	Msg("Entered world: "..tostring(eEnt).." at "..tostring(vPos)..", "..tostring(aAng).." - Teleported? "..tostring(bTeleport).."\n");
end

--[[
Can the item leave the world?

This event gets called any time the item is in the world and is non-forcefully being taken out of it.
By "non-forcefully" I mean that the item doesn't HAVE to leave - IE, it's not being removed.
Serverside, if this returns false it stops the item from leaving the world. Returning true allows it to leave.
Clientside, the function returning true/false is only good for prediction purposes.

ent is the item's current world entity. It should be the same as self:GetEntity().
]]--
function ITEM:CanExitWorld(ent)
	return !ent:IsConstrained();
end

--[[
This event is called after an item leaves the world.

forced is true if the removal of the item from the world was forced (with good reason usually, such as the item itself being removed).
]]--
function ITEM:OnExitWorld(forced)

end

--[[
Can the item be held as a weapon?

Serverside, if this returns false, attempts to hold the item as a weapon will fail.
Clientside, the function returning true/false is only good for prediction purposes.

By default, items cannot be held if they are too large (30 or more).
You can override this in your items.

pl is the player who will be holding the weapon.
]]--
function ITEM:CanHold(pl)
	return self:GetSize()<30;
end

--This is the default slot drop function for a held weapon's item slot
--Self is this slot, panel is the panel this was dropped on
local SlotDrop=function(self,droppedPanel)
	local item=self:GetItem();
	if !item then return false end
	
	--Can the dropped panel hold an item?
	if !droppedPanel.GetItem then return false end

	--Does the dropped panel have an item set, and is it different from this panel's item?
	local s,r=pcall(droppedPanel.GetItem,droppedPanel);
	if !s then	ErrorNoHalt(r.."\n"); return false;
	elseif !r || r==item then return false end
	
	--Call the dragdrop events.
	if item:Event("OnDragDropHere",true,r) then
		r:Event("OnDragDropToItem",nil,item);
	end
end

--[[
This event is called after an item is successfully held by a player.

pl is the player who is holding the item as a weapon.
weapon is the weapon entity.
]]--
function ITEM:OnHold(pl,weapon)
	--DEBUG
	Msg("Held: By "..tostring(pl)..", weapon: "..tostring(weapon).."\n");
	
	if SERVER then return end
	
	--If the weapon isn't out when OnHold gets called, we need to hide the world model and item slot
	local bNotOut=(pl:GetActiveWeapon()!=weapon);
	
	--Create world model
	if !self.WMAttach then
		--First we create the gear, attached to the holding player
		self.WMAttach=IF.GearAttach:Create(self:GetWOwner(),self:GetWorldModel());
		if self.WMAttach then
			self.WMAttach:SetOffset(self.WorldModelNudge);
			self.WMAttach:SetOffsetAngles(self.WorldModelRotate);
			self.WMAttach:SetDrawFunction(function(ent) return self:Event("OnDraw3D",nil,ent,false) end);
			
			--Hide if we're not out
			if bNotOut then self.WMAttach:Hide() end
			
			--We try to bone-merge first and if that fails we try to attach to the right-hand attachment point instead
			if !self.WMAttach:BoneMerge("ValveBiped.Bip01_R_Hand") && !self.WMAttach:ToAP("anim_attachment_RH") then
				--Otherwise we need to remove it since it can't be attached to anything
				self.WMAttach:Remove();
				self.WMAttach=nil;
			end
		else
			self.WMAttach=nil;
		end
	end
	
	--Create item slot
	if !self.ItemSlot && pl==LocalPlayer() then
		local slot=vgui.Create("ItemforgeItemSlot");
		
		slot:SetSize(64,64);
		slot:SetPos(2,2);
		slot:SetDraggable(true);
		slot:SetDroppable(true);
		slot:SetItem(self);
		slot.OnDragDropHere=SlotDrop;
		
		if bNotOut then slot:SetVisible(false); end
		
		self.ItemSlot=slot;
	end
end

--[[
Can a player lose hold of this item?
This event gets called any time the item is being held (as a weapon) by a player and is being released (taken out of his weapon menu) non-forcefully.
By "non-forcefully" I mean that the item doesn't HAVE to be released - IE, it's not being removed, the player didn't just die, etc.
Serverside, if this returns false it stops the item from being released. Returning true allows it to be released.
Clientside, the function returning true/false is only good for prediction purposes.

pl is the player who is currently holding the item. It should be the same thing as self:GetWOwner().
]]--
function ITEM:CanRelease(pl)
	return true;
end

--[[
This is run if this item was being held (as a weapon) by a player who lost hold of it.

pl is the player who is currently holding the item.
forced is true if the release of the item was forceful (the item is being removed, the player died, etc)
]]--
function ITEM:OnRelease(pl,forced)
	if CLIENT then
		if self.WMAttach then
			self.WMAttach:Remove();
			self.WMAttach=nil;
		end
		
		if self.ItemSlot then
			if self.ItemSlot:IsValid() then self.ItemSlot:Remove(); end
			self.ItemSlot=nil;
		end
	end
end

--[[
This is called when the player wants to split a stack of items into two or more stacks.
You may find this useful for certain kinds of items that have amounts but aren't really loose stacks of items, such as batteries, ropes, etc.

This event can decide whether or not this item can be split directly by a player (probably via the Split menu action).
Note that if CanSplit returns false, it stops all splits, including player splits.

pl is the player who wants to split the stack.

Return true to allow the player to split this stack.
Return false to prevent the player from splitting the stack.
]]--
function ITEM:CanPlayerSplit(pl)
	return true;
end

--[[
This is called when the player wants to merge two stacks of items in to a single stack.
You may find this useful for certain kinds of items that have amounts but aren't really loose stacks of items, such as batteries, wires, etc.

This event can decide whether or not this item can be merged directly by a player (probably via a drag & drop).
Note that if CanMerge returns false, it stops all merges, including player merges.

pl is the player who wants to merge the two stacks.
otherItem is the other stack of items that this stack is merging with.

TODO determine where this needs to be called (what qualifies as a player initiated merge?) and implement
]]--
function ITEM:CanPlayerMerge(pl,otherItem)
	return true;
end

--[[
This is called when two items of the same type bump into each other in the world.
If this item is in the world (as an ent), and another item of the same type bumps into it, should the two items merge into a stack?
	Ex: You have a sheet of paper. Another sheet of paper falls on top of it.
	Should the two sheets of paper remain seperate, or should they form a stack of 2 papers?

This event can decide whether or not this item can be merged with other items in the world.
Note that if CanMerge returns false, it stops all merges.

otherItem is the other item that this item is attempting to merge with.

Return true to allow the item to merge together as a single stack with another item,
or false to keep the item seperate from the other item.
]]--
function ITEM:CanWorldMerge(otherItem)
	return true;
end

--[[
This is called when an item is inserted into an inventory with an item of the same type.
If this item is in an inventory, and an item of the same type is placed in the inventory, should the two items merge?
	Ex: You have 30 grapes in a barrel. You put in 56 grapes.
	Should they merge into one stack of 86 grapes, or should the two stacks remain seperate (a stack of 30 grapes and a seperate stack of 56 grapes)?
This hook can decide whether or not this item can be merged with other items in inventories.
Note that if CanMerge returns false, it stops all merges.

otherItem is the other item that this item is attempting to merge with.
inventory is the inventory that this item is being inserted into.

Return true to allow the item to merge together as a single stack with another item,
or false to keep the item stacks seperate from each other.
]]--
function ITEM:CanInventoryMerge(otherItem,inventory)
	return true;
end

--[[
This is called when an item tries to be picked up, but an item of the same type is being held as a weapon.
Should the item you're trying to pick up be merged with the item you're holding?
	Ex: You're holding 5 rocks. You see a rock on the ground and want to pick it up, giving you 6 rocks. Can you?
This hook can decide whether or not this item can be merged with the item currently being held as a weapon.
Note that if CanMerge returns false, it stops all merges.

otherItem is the other item that this item is attempting to merge with.
player is the player currently holding an item that is going to be merged.

Return true to allow the item to merge together as a single stack held by the player,
or false to keep the items stacks seperate (which means the player will pick up the item as a seperate stack, or if he's holding the max number of items already, stops the item from being held)
]]--
function ITEM:CanHoldMerge(otherItem,player)
	return true;
end

--[[
Can this stack of items merge with another stack?
This event gets called any time the item wants to merge with another item.
Serverside, if this returns false, it stops the merge from happening. Returning true allows a merge to occur.
Clientside, this function returning true/false is only good for prediction purposes.

otherItem is a stack of items that is the same type as this stack.
bToHere will be true/false.
	If this is true, that indicates that otherItem is moving to this stack.
	If this is false, that indicates that this stack is moving to otherItem.

By default, two stacks can't merge if one of them is constrained in some way (welded to something, roped, etc)
]]--
function ITEM:CanMerge(otherItem,bToHere)
	local ent=self:GetEntity();
	if ent && ent:IsConstrained() then return false end
	
	return true;
end

--[[
This runs after another stack's items have been transferred to this stack.

bPartial will be true/false. If bPartial is:
	true, then otherItem will be a stack of items. Since we couldn't move all of the items, this stack contains all the items that couldn't be merged.
	false, otherItem will be nil, since all of otherItem's contents were moved to this stack.

TODO getting client to recognize a merge
]]--
function ITEM:OnMerge(bPartial,otherItem)
	
end

--[[
Can this stack of items split into another stack?
This event gets called any time a stack wants to split off some of it's items into a new stack.
Serverside, if this returns false, it stops the split from happening.
Clientside, this function returning true/false is only good for prediction purposes.

howMany is how many items we want to transfer to the new stack.

By default, stacks can't split if they are constrained in some way (welded to something, roped, etc)
]]--
function ITEM:CanSplit(howMany)
	local ent=self:GetEntity();
	if ent && ent:IsConstrained() then return false end
	
	return true;
end

--[[
This runs when this stack of items is split into another stack of items.

newStack is the new stack of items.
howMany is how many items were split off to the new stack.s

TODO getting client to recognize a split
]]--
function ITEM:OnSplit(newStack,howMany)
end

--[[
Whenever a stack is split, a new stack is created. If this item is the new stack created by splitting from another stack of items, this function is called.
This function runs right after this stack has been created. Again, this function only runs if this item results from splitting from another stack of items.
originItem will be the original stack that this item split from.
howMany is how many items were transferred to this stack from originItem's stack.
TODO copy network vars from originItem
]]--
function ITEM:OnSplitFromStack(originItem,howMany)

end

--[[
This event is called after an inventory has been connected to the item.
]]--
function ITEM:OnConnectInventory(inv,conslot)
end

--[[
This event is called after an inventory has been severed from the item.
]]--
function ITEM:OnSeverInventory(inv)
end