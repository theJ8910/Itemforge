--[[
events_shared
SHARED

base_item is the default item. All items except base_item inherit from this item-type.
NOTE: The item type is the name of the folder it is in (this is base_item/shared_events.lua, so this item's type is "base_item")

This specific file deals with events that are present on both the client and server.
]]--




--[[
ENTITY SPECIFIC EVENTS
]]--




--[[
* SHARED
* Event

Can a player punt (push / launch while holding) this item with the gravity gun?
This event gives the item a chance to decide.

NOTE:
This event should only determine whether or not the punt is allowed, not actually respond to it.
Clientside, this can't actually stop the punt, it's just good for prediction purposes.
The event should return the same thing on both the client and server.

pl is the player who is trying to punt the item.
eEntity is the item's world entity (should be the same as self:GetEntity())

Return true to allow the punt, or false to forbid it.
]]--
function ITEM:CanGravGunPunt( pl, eEntity )
	return true;
end

--[[
* SHARED
* Event

Runs right after the player punts (pushes / launches while holding) this item with the gravity gun.

If the CanGravGunPunt event denies the punt, this event does not run.

pl is the player who punted the item.
eEntity is the item's world entity (should be the same as self:GetEntity())
]]--
function ITEM:OnGravGunPunt( pl, eEntity )
	
end

--[[
* SHARED
* Event

Can a player pick this item up with the physgun?
This event gives the item a chance to decide.

NOTE:
This event should only determine whether or not the pickup is allowed, not actually respond to it.
Clientside, this can't actually stop the pickup, it's just good for prediction purposes.
The event should return the same thing on both the client and server.

pl is the player who is trying to pick up the item with the physgun.
eEntity is the item's world entity (should be the same as self:GetEntity())

Return true to allow the pickup, or false to forbid it.
]]--
function ITEM:CanPhysgunPickup( pl, eEntity )
	return true;
end

--[[
* SHARED
* Event

Runs right after the player picks up this item with the physgun.

If the CanPhysgunPickup event denies the pickup, this event does not run.

pl is the player who picked up the item with the physgun.
eEntity is the item's world entity (should be the same as self:GetEntity())
]]--
function ITEM:OnPhysgunPickup( pl, eEntity )

end

--[[
* SHARED
* Event

Runs if the player was holding the item with the physgun and then drops it.

pl is the player who dropped the item with the physgun.
eEntity is the item's world entity (should be the same as self:GetEntity())
]]--
function ITEM:OnPhysgunDrop( pl, eEntity )

end




--[[
SWEP SPECIFIC EVENTS
]]--




--[[
* SHARED
* Event

Whenever an item is held as a weapon, an SWEP is created to represent it.
This function will be run while SetItem is being run on the SWEP.

eWeapon is the weapon entity - it's "SWEP.Weapon".
]]--
function ITEM:OnSWEPInit( eWeapon )
	--We'll grab and set the world model and view models of the SWEP first
	--eWeapon.WorldModel			= self:GetWorldModel();
	--eWeapon.ViewModel				= self:GetViewModel();
	
	--TODO use hooks
	eWeapon.Primary.Automatic		= self:GetPrimaryAuto();
	eWeapon.Secondary.Automatic		= self:GetSecondaryAuto();
	
	if CLIENT then
		eWeapon.PrintName			= self:Event( "GetName", "Itemforge Item" );
		eWeapon.Slot				= self:GetSWEPSlot();
		eWeapon.SlotPos				= self:GetSWEPSlotPos();
		eWeapon.ViewModelFlip		= self:GetSWEPViewModelFlip();
	end
	
	eWeapon:SetWeaponHoldType( self:GetSWEPHoldType() );
	
	return true;
end

--[[
* SHARED
* Event

This is run when a player is holding the item as an SWEP and presses the left mouse button
(primary attack).
The default action is to use the item.

NOTE: If ITEM.SWEPPrimaryAuto is true, then this event runs every frame the player has his
Left Mouse button pressed!
]]--
function ITEM:OnSWEPPrimaryAttack()
	if SERVER then self:Use( self:GetWOwner() ); end
end

--[[
* SHARED
* Event

This is run when a player is holding the item as an SWEP and presses the right mouse button
(secondary attack).
The default action is to use the item.

NOTE: If ITEM.SWEPSecondaryAuto is true, then this event runs every frame the player has his
Right Mouse button pressed!
]]--
function ITEM:OnSWEPSecondaryAttack()
	if SERVER then self:Use( self:GetWOwner() ); end
end

--[[
* SHARED
* Event

This is run every frame while the item is being held as an SWEP, and the player has it out.
]]--
function ITEM:OnSWEPThink()
	if self.ViewmodelIdleAt != 0 && self.ViewmodelIdleAt < CurTime() then
		self:SendWeaponAnim( ACT_VM_IDLE );
		self.ViewmodelIdleAt = 0;
	end
end

--[[
* SHARED
* Event

This is run when a player is holding the item as an SWEP and presses the reload button (usually the "R" key).
Nothing happens by default.

NOTE: OnSWEPReload is called every frame that the player has his [R] key pressed!
]]--
function ITEM:OnSWEPReload()
end

--[[
* SHARED
* Event

I don't really know what this function is or where it's used but it was in the base weapon
so I included it for you to potentially use
]]--
function ITEM:OnSWEPCheckReload()
end

--[[
* SHARED
* Event

When the item is a weapon held by a player, this function runs when that player
clicks the screen with his mouse.

NOTE: This function is only called in Sandbox based gamemodes. However, if you're making a
non-sandbox based gamemode and you want screen clicks you can probably write your own code
to call the ContextScreenClick event on the player's currently active SWEP.

vAim is a normal vector indicating what direction the click was in (it points towards
whatever point in the world the user clicked on).

eMousecode indicates what kind of click it was.
	Valid values are MOUSE_LEFT, MOUSE_RIGHT, MOUSE_MIDDLE, MOUSE_4, MOUSE_5.

bPressed is a true/false that will be:
	true if the player just pressed his mouse
	false if the player just released his mouse.

pl is the player who clicked the screen.
]]--
function ITEM:OnSWEPContextScreenClick( vAim, eMousecode, bPressed, pl )
	
end

--[[
* SHARED
* Event

This is the source engine OnDeploy hook (the normal OnDeploy that SWEPs use).
The source engine OnDeploy hook is predicted serverside and clientside, so it's safe to use
anything that needs to be predicted on both sides here.

Note, though, that this hook is not as reliable as Itemforge's Deploy/Holster hook.
It's possible for it to call several times or not at all. 

If the item is a weapon this hook calls when the player swaps to it.
]]--
function ITEM:OnSWEPDeploy()
	--DEBUG
	Msg( "Itemforge Items: Source Deploy on "..tostring( self ).."!\n" );
	self.ViewmodelIdleAt = CurTime();

	return true;
end

--[[
* SHARED
* Event

This is Itemforge's custom deploy hook.
It's more reliable than the source engine's OnDeploy hook, but is unpredicted. Anything
that absolutely needs to be in sync on both the server and client SHOULD NOT go here.

If the item is a weapon this hook calls ONCE when the player swaps to it.
]]--
function ITEM:OnSWEPDeployIF()
	--DEBUG
	Msg( "Itemforge Items: Itemforge Deploy on "..tostring( self ).."!\n" );
	
	if self.WMAttach then self.WMAttach:Show() end
	if self.ItemSlot then self.ItemSlot:SetVisible( true ) end
	
	return true;
end

--[[
* SHARED
* Event

This is the source engine OnHolster hook (the normal OnHolster that SWEPs use).
The source engine OnHolster hook is predicted serverside and clientside, so it's safe to use
anything that needs to be predicted on both sides here.

Note, though, that this event is not as reliable as Itemforge's Deploy/Holster event.
It's possible for it to call several times or not at all. 

If the item is a weapon this event calls when the player had it out but has swapped
to a different weapon now.
]]--
function ITEM:OnSWEPHolster()
	--DEBUG
	Msg( "Itemforge Items: Source Holster on "..tostring( self ).."!\n" );
	return true;
end

--[[
* SHARED
* Event

This is Itemforge's custom holster event.
It's more reliable than the source engine's OnHolster hook, but is unpredicted. Anything
that absolutely needs to be in sync on both the server and client SHOULD NOT go here.

If the item is a weapon this event calls ONCE when the player had it out but has swapped
to a different weapon now.
]]--
function ITEM:OnSWEPHolsterIF()
	--DEBUG
	Msg( "Itemforge Items: Itemforge Holster on "..tostring( self ).."!\n" );
	
	if self.WMAttach then self.WMAttach:Hide() end
	if self.ItemSlot then self.ItemSlot:SetVisible( false ) end
	
	return true;
end




--[[
ITEM EVENTS
]]--




--[[
* SHARED
* Event

Runs right after the item is created.
You can set the item up here if you want.

plOwner is the player this item was originally created for (e.g. if it spawns in a player's inventory, plOwner is the player).
]]--
function ITEM:OnInit( plOwner )
	
end

--[[
* SHARED
* Event

This function is run prior to an item being removed.
It cannot cancel the item from being removed.
]]--
function ITEM:OnRemove()
	
end

--[[
* SHARED
* Event

This function is run periodically (when the client ticks).
]]--
function ITEM:OnTick()

end

--[[
* SHARED
* Event

This event runs every frame if this item is set to think.
You can set when the next think will occur by doing self:SetNextThink( time )
You need to tell the item to self:StartThink() to start the item thinking.
]]--
function ITEM:OnThink()
	
end

--[[
* SHARED
* Event

Returns the name of the item.
]]--
function ITEM:GetName()
	return self.Name;
end

--[[
* SHARED
* Event

Returns the item's description.
]]--
function ITEM:GetDescription()
	return self.Description;
end

--[[
* SHARED
* Event

When tostring() is performed on an item reference, it returns a string containing some information about the item.
Format: "Item ID [ITEM_TYPE]xAMT"
Ex:		"Item 5 [item_crowbar]" (Item 5, a single crowbar)
Ex:		"Item 3 [item_rock]x53" (Item 3, a stack of 53 item_rocks)
Ex:		"Object [invalid]" (used to be some kind of object, invalid/has been removed/no longer exists)
Ex:		"Inventory 2" (Is inventory 2)
]]--
function ITEM:ToString()
	return "Item "..self:GetID().." ["..self:GetType().."]";
end

--[[
* SHARED
* Event

This is run when the player 'uses' the item.
An item can be used in the inventory with the use button, or if on the ground,
by looking at the item's model and pressing E.

IMPORTANT NOTE ABOUT "USE":
Clientside, there is no way to detect if the player uses the item with "E"
while it's in the world. That being said, the item's OnUse is not called clientside when used
like this. Only the serverside OnUse is called.

If the player uses the item in any other way, though, the clientside OnUse calls first,
and then if it returns true, it sends a message to the server that make the OnUse call there
too.

In the clientside OnUse, returning false will stop this from happening.
An example of why you would want to do this:
	Say the item is a pocket-watch that gives you the current time. You don't need to contact
	the server to figure this out since your client already knows what time it is. You can
	just output the time clientside and return false since you have no need to contact the server.
	
	Another example, you might determine clientside that the player can't use the item. In this
	case you know that it's going to fail if it gets to the server, so you just skip the Use
	entirely. BE AWARE that the client is not secure; this is not a security feature.
	It's simply to avoid networking unnecessary data.

On the client:
	Return true if OnUse needs to run on the server too (it usually does)
	Return false otherwise.
	
On the server:
	Return true if the player used the item with no troubles.
	
	Return false if the item doesn't have a specific use, or the player can't use it
	for some other reason. This will output a failure message to the player ("I can't use this!")
	and make the player complain verbally.
]]--
function ITEM:OnUse( pl )
	if SERVER then
		if !self:InWorld() then return false end
		self:Hold( pl );
	end

	return true;
end

--[[
* SHARED
* Event

If an item is in the void, this event can be used to return it's position in the world.
This event is useful for items that are are not in an item's inventory, but are attached to them (like ammo and locks).

This hook can return nil, a vector, or a table of vectors.
]]--
function ITEM:GetVoidPos()
end

--[[
* SHARED
* Event

This hook is called whenever a player tries to do something with an item (use it, hold it, drag it to world, merge it with something, etc).
Itemforge uses this in some places, but you can use this hook to check if a player can interact with something youself. EX:
	if !self:Event( "CanPlayerInteract", false, PLAYER ) then return false end



This hook is --VERY IMPORTANT--
Players can do all sorts of things with items - dragdrop them to world/an inventory, use them, load guns with them, etc.
This function double checks that the player is ALLOWED to do this at the moment.
Otherwise, the player could load ammo half-way across the map, or use items in a locked inventory.



If this hook returns true, then you're allowing the player to interact with an item in some way.
If this hook returns false, then the player can't interact with an item in some way.
]]--
function ITEM:CanPlayerInteract( pl )
	--The player has to be alive to interact with anything
	if !pl:Alive() then return false end
	
	--Serverside, we make sure the server has actually informed the player about the item (i.e. player 2 can't use an item in player 1's private inventory).
	--Clientside, we make sure the local player is interacting with items and not some other player (IE, if this client is controlling Player 1, only Player 1 can interact with an item on this client)
	if SERVER then	if !self:CanNetwork( pl )	then return false end
	else			if pl != LocalPlayer()		then return false end
	end
	
	--If the item is in an inventory, will the inventory let the players interact with it?
	local iC = self:GetContainer();
	local plOwner = self:GetWOwner();
	if iC then
		if iC:Event( "CanPlayerInteract", false, pl, self ) then return true end
	
	--If the item is held, only the player holding it can interact with it.
	elseif plOwner != nil then
		return plOwner == pl;
	
	--Otherwise, the player must be nearby the item in order to interact with it
	else
		local vPos = self:GetPos();
		if IF.Util:IsVector( vPos ) then
			if vPos:Distance( pl:GetPos() ) <= 256 then return true end
			
		--If we're in several locations we have to be nearby at least one (this happens when an item is in an inventory connected to several objects)
		elseif IF.Util:IsTable( vPos ) then
			for k,v in pairs( vPos ) do
				if v:Distance( pl:GetPos() ) <= 256 then return true end
			end
		end
	end
	return false;
end

--[[
* SHARED
* Event

This is a stub.
This hook is more or less the same as CanPlayerInteract but specifically affects NPCs.
When NPCs are able to use items, this hook will determine whether or not they will be allowed to.
]]--
function ITEM:CanNPCInteract( eNPC )
	return true;
end

--[[
* SHARED
* Event

This is a stub.

Not only can players interact with items (e.g. pick them up, drop them, move them around),
but items themselves can interact with each other.
For example, ranged weapons load ammo items, and locks attach to chests.
Both items must approve of the interaction (e.g. the weapon has to allow the ammo to be used, and the ammo has to allow itself to be used in the weapon).

Like CanPlayerInteract, this hook should be used for general sanity checks that would apply to most interactions between items;
for instance... if either of the items are in an inventory, are they at least in the same inventory? Are the items close to each other? And so on.

Whenever I get around to implementing this in Itemforge, this hook will determine whether or not that item is allowed to interact with this item.

Return true to allow the item to interact with this item,
or false to deny it.
]]--
function ITEM:CanItemInteract( item )
	return true;
end

--[[
* SHARED
* Event

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
function ITEM:CanMove( OldInv, OldSlot, NewInv, NewSlot )
	return true;
end

--[[
* SHARED
* Event

This is run after the item is moved from one inventory to another (or from one slot in an inventory to another).

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

If bForced is true (usually due to forced removal from an inventory because the item is being removed) then the removal could not have been stopped by CanMove.

TODO this event needs to be called in more places, and PROPERLY for that matter
]]--
function ITEM:OnMove( OldInv, OldSlot, NewInv, NewSlot, bForced )
end

--[[
* SHARED
* Event

Can the item be placed in the world at the given position and angles?

Serverside, if this returns false, attempts to place the item in the world will fail.
Clientside, the function returning true/false is only good for prediction purposes.

vPos is a Vector(), the position it's trying to enter at.
aAng is an Angle(), describing the orientation it's trying to enter at.
bTeleport is a true/false. If this is true, the item is already in the world - it just wants to teleport to the given position/angles.

Return false to stop the item from entering the world, or return true to allow it to enter the world.
]]--
function ITEM:CanEnterWorld( vPos, aAng, bTeleport )
	return true;
end

--[[
* SHARED
* Event

This event is called after the item has entered the world.
This runs any time item:ToWorld() was called successfully, including when the item was already in the world and was teleported.

eEnt is the item's world entity. It should be the same thing as item:GetEntity().
vPos is the position it's trying to be inserted at.
aAng is the angle it's trying to be inserted at.
bTeleport will be true if the item was already in the world and was just teleported to the given position instead.
	If this is false, it means that a new entity was created for the item.
]]--
function ITEM:OnEnterWorld( eEnt, vPos, aAng, bTeleport )
end

--[[
* SHARED
* Event

Can the item leave the world?

This event gets called any time the item is in the world and is non-forcefully being taken out of it.
By "non-forcefully" I mean that the item doesn't HAVE to leave - e.g., it's not being removed.
Serverside, if this returns false it stops the item from leaving the world. Returning true allows it to leave.
Clientside, the function returning true/false is only good for prediction purposes.

eEnt is the item's current world entity. It should be the same as self:GetEntity().
]]--
function ITEM:CanExitWorld( eEnt )
	return !eEnt:IsConstrained();
end

--[[
* SHARED
* Event

This event is called after an item leaves the world.

bForced is true if the removal of the item from the world was forced (with good reason usually, such as the item itself being removed).
]]--
function ITEM:OnExitWorld( bForced )

end

--[[
* SHARED
* Event

Can the item be held as a weapon?

Serverside, if this returns false, attempts to hold the item as a weapon will fail.
Clientside, the function returning true/false is only good for prediction purposes.

By default, items cannot be held if they are too large (size 30 or larger).
You can override this in your items.

pl is the player who will be holding the weapon.
]]--
function ITEM:CanHold( pl )
	return self:GetSize() < 30;
end

--[[
* SHARED
* Event

This event is called after an item is successfully held by a player.

pl is the player who is holding the item as a weapon.
eWeapon is the weapon entity.
]]--
function ITEM:OnHold( pl, eWeapon )
	--DEBUG
	Msg( "Held: By "..tostring( pl )..", weapon: "..tostring( eWeapon ).."\n" );
	
	if SERVER then return end

	--Need to do these with timers because if the SWEP acquires the item during a drawing hook,
	--OnHold will be called and would call these functions which create ClientsideModels, which is not allowed during a drawing hook
	self:SimpleTimer( 0, self.CreateSWEPWorldModel, pl, eWeapon );
	self:SimpleTimer( 0, self.CreateItemSlot, pl, eWeapon );
end

--[[
* SHARED
* Event

Can a player lose hold of this item?
This event gets called any time the item is being held (as a weapon) by a player and is being released (taken out of his weapon menu) non-forcefully.
By "non-forcefully" I mean that the item doesn't HAVE to be released - IE, it's not being removed, the player didn't just die, etc.

pl is the player who is currently holding the item. It should be the same thing as self:GetWOwner().

Serverside, if this returns false it stops the item from being released. Returning true allows it to be released.
Clientside, the function returning true/false is only good for prediction purposes.
]]--
function ITEM:CanRelease( pl )
	return true;
end

--[[
* SHARED
* Event

This is run if this item was being held (as a weapon) by a player who lost hold of it.

pl is the player who is currently holding the item.
bForced is true if the release of the item was forceful (the item is being removed, the player died, etc)
]]--
function ITEM:OnRelease( pl, bForced )
	if SERVER then return end

	if self.WMAttach then
		self.WMAttach:Remove();
		self.WMAttach = nil;
	end
		
	if self.ItemSlot then
		if self.ItemSlot:IsValid() then self.ItemSlot:RemoveAndCleanUp() end
		self.ItemSlot = nil;
	end
end

--[[
* SHARED
* Event

This is called when the player wants to split a stack of items into two or more stacks.
You may find this useful for certain kinds of items that have amounts but aren't really loose stacks of items, such as batteries, ropes, etc.

This event can decide whether or not this item can be split directly by a player (probably via the Split menu action).
Note that if CanSplit returns false, it stops all splits, including player splits.

pl is the player who wants to split the stack.

Return true to allow the player to split this stack.
Return false to prevent the player from splitting the stack.
]]--
function ITEM:CanPlayerSplit( pl )
	return true;
end

--[[
* SHARED
* Event

This is called when the player wants to merge two stacks of items in to a single stack.
You may find this useful for certain kinds of items that have amounts but aren't really loose stacks of items, such as batteries, wires, etc.

This event can decide whether or not this item can be merged directly by a player (probably via a drag & drop).
Note that if CanMerge returns false, it stops all merges, including player merges.

pl is the player who wants to merge the two stacks.
otherItem is the other stack of items that this stack is merging with.

TODO determine where this needs to be called (what qualifies as a player initiated merge?) and implement
]]--
function ITEM:CanPlayerMerge( pl, otherItem )
	return true;
end

--[[
* SHARED
* Event

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
function ITEM:CanWorldMerge( otherItem )
	return true;
end

--[[
* SHARED
* Event

This is called when an item is inserted into an inventory with an item of the same type.
If this item is in an inventory, and an item of the same type is placed in the inventory, should the two items merge?
	Ex: You have 30 grapes in a barrel. You put in 56 grapes.
	Should they merge into one stack of 86 grapes, or should the two stacks remain seperate (a stack of 30 grapes and a seperate stack of 56 grapes)?
This hook decides whether the two stacks are merged or not.
Note that if CanMerge returns false, it stops all merges.

otherItem is the other item that this item is attempting to merge with.
inventory is the inventory that this item is being inserted into.

Return true to allow the item to merge together as a single stack with another item,
or false to keep the item stacks seperate from each other.
]]--
function ITEM:CanInventoryMerge( otherItem, inventory )
	return true;
end

--[[
* SHARED
* Event

This is called when an item tries to be picked up, but an item of the same type is being held as a weapon.
Should the item you're trying to pick up be merged with the item you're holding?
	Ex: You're holding 5 rocks. You see a rock on the ground and want to pick it up, giving you 6 rocks. Can you?
This hook can decide whether or not this item can be merged with the item currently being held as a weapon.
Note that if CanMerge returns false, it stops all merges.

otherItem is the other item that this item is attempting to merge with.
pl is the player currently holding an item that is going to be merged.

Return true to allow the item to merge together as a single stack held by the player,
or false to keep the items stacks seperate (which means the player will pick up the item as a seperate stack, or if he's holding the max number of items already, stops the item from being held)
]]--
function ITEM:CanHoldMerge( otherItem, pl )
	return true;
end

--[[
* SHARED
* Event

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
function ITEM:CanMerge( otherItem, bToHere )
	local eEntity = self:GetEntity();
	if eEntity && eEntity:IsConstrained() then return false end
	
	return true;
end

--[[
* SHARED
* Event

This runs after another stack's items have been transferred to this stack.

bPartial will be true/false. If bPartial is:
	true, then otherItem will be a stack of items. Since we couldn't move all of the items, this stack contains all the items that couldn't be merged.
	false, otherItem will be nil, since all of otherItem's contents were moved to this stack.

TODO getting client to recognize a merge
]]--
function ITEM:OnMerge( bPartial, otherItem )
	
end

--[[
* SHARED
* Event

Can this stack of items split into another stack?
This event gets called any time a stack wants to split off some of it's items into a new stack.
Serverside, if this returns false, it stops the split from happening.
Clientside, this function returning true/false is only good for prediction purposes.

iHowMany is how many items we want to transfer to the new stack.

By default, stacks can't split if they are constrained in some way (welded to something, roped, etc)
]]--
function ITEM:CanSplit( iHowMany )
	local eEntity = self:GetEntity();
	if eEntity && eEntity:IsConstrained() then return false end
	
	return true;
end

--[[
* SHARED
* Event

This runs when this stack of items is split into another stack of items.

newStack is the new stack of items.
iHowMany is how many items were split off to the new stack.

TODO getting client to recognize a split
]]--
function ITEM:OnSplit( newStack, iHowMany )
	
end

--[[
* SHARED
* Event

Whenever a stack is split, a new stack is created. If this item is the new stack created by splitting from another stack of items, this function is called.
This function runs right after this stack has been created. Again, this function only runs if this item results from splitting from another stack of items.

originItem will be the original stack that this item split from.
iHowMany is how many items were transferred to this stack from originItem's stack.

TODO copy network vars from originItem
]]--
function ITEM:OnSplitFromStack( originItem, iHowMany )

end

--[[
* SHARED
* Event

This event is called after an inventory has been connected to the item.

inv is the inventory that was connected.
iConSlot is the slot # this item occupies on the inventory's list of connected items.
]]--
function ITEM:OnConnectInventory( inv, iConSlot )

end

--[[
* SHARED
* Event

This event is called after an inventory has been severed from the item.
]]--
function ITEM:OnSeverInventory( inv )

end

--[[
* CLIENT
* Event

This hash table translates the name of a changed network var (from OnSetNWVar) into a
function that can respond to the changing of a network var.
]]--
local OnSetNWVarHandler = {};

OnSetNWVarHandler["SWEPPrimaryAuto"]			= function( self, vValue )
	--If we're currently holding this item as a weapon we need to update it's auto-primary
	--TODO: test if this sets on every weapon or just this one. If it misbehaves we'll have to create a copied table each time.
	local eWep = self:GetWeapon();
	if eWep then eWep.Primary.Automatic = vValue; end
end

OnSetNWVarHandler["SWEPSecondaryAuto"]		= function( self, vValue )
	--If we're currently holding this item as a weapon we need to update it's auto-secondary
	--TODO: test if this sets on every weapon or just this one. If it misbehaves we'll have to create a copied table each time.
	local eWep = self:GetWeapon();
	if eWep then eWep.Secondary.Automatic = vValue; end
end

OnSetNWVarHandler["SWEPHoldType"]			= function( self, vValue )
	--If we're currently holding this item as a weapon we need to update it's holdtype
	local eWep = self:GetWeapon();
	if eWep then eWep:SetWeaponHoldType( self:GetSWEPHoldType() ); end
end

if CLIENT then




--Changing the amount or weight of an item affects the weight stored in the inventory, so panels displaying the inv need to be updated
OnSetNWVarHandler["Amount"]				= function( self, vValue ) self:UpdateContainer(); end
OnSetNWVarHandler["Weight"]				= function( self, vValue ) self:UpdateContainer(); end

--If the world model changes we need to update any panels displaying it so it refreshes the model displayed
OnSetNWVarHandler["WorldModel"]			= function( self, vValue ) self:Update(); end

OnSetNWVarHandler["OverrideMaterial"]	= function( self, vValue )
	if vValue != nil then self.OverrideMaterialMat = Material( vValue );
	else				  self.OverrideMaterialMat = nil;
	end
end

OnSetNWVarHandler["SWEPViewModelFlip"]	= function( self, vValue )
	--If we're currently holding this item as a weapon we need to update it's viewmodel flip status
	local eWep = self:GetWeapon();
	if eWep then eWep.ViewModelFlip = vValue end
end

OnSetNWVarHandler["SWEPSlot"]			= function( self, vValue )
	--If we're currently holding this item as a weapon we need to update it's slot
	local eWep = self:GetWeapon();
	if eWep then eWep.Slot = vValue end
end

OnSetNWVarHandler["SWEPSlotPos"]		= function( self, vValue )
	--If we're currently holding this item as a weapon we need to update it's slot pos
	local eWep = self:GetWeapon();
	if eWep then eWep.SlotPos = vValue end
end




end

--[[
* SHARED
* Event

This runs when a networked var is set on this item (with SetNW* or received from the server).

strName is the name of the network var that was set.
vValue is the value the network var was set to.
]]--
function ITEM:OnSetNWVar( strName, vValue )
	local fn = OnSetNWVarHandler[strName];
	if fn then fn( self, vValue ); end
end

--[[
* SHARED
* Class
* Event

This runs after this item class has inherited from it's base class.
This is not actually an item event, it's a class event. So self is not an item, it's an item class.
Since this is after inheritence, it runs on any class based off of base_item (all item classes basically),
unless someone overrides it on purpose.

This function registers the SWEPs that items of this class will use.

Additionally, it inherits networked commands and networked ids.

For example, if Item A has NWVars "VarString" and "VarInt",
and,            Item B has NWVars "VarString" and "VarFloat",
Item A will assign an ID of 1 to VarString and an ID to 2 to VarInt.
Item B will assign an ID of 1 to VarString and an ID of 2 to VarFloat.
BUT...
If Item B inherits from Item A, that means Item B now has "VarString", "VarInt" (from A) and "VarString", "VarFloat" (from B)
Or in other words, we have network vars with IDs 1, 2, 1, and 2. So, how do we deal with this now? The IDs have to be unique!
This is what this function is created for. It assigns unique IDs to networked vars and commands.
Now, since Item B inherits from A, Item B will get everything that A has, BUT if B already has something A has, B overrides A.
First we go through B... we assign a 1 to VarString and a 2 to VarFloat.
Next we go through B's base... we already have a VarString, so we don't need to give another ID for that.
We assign a 3 to VarInt.

Voila! Problem solved!
]]--
function ITEM:OnClassInherited()
	IF.Items:ClassInherited( self.ClassName, self );
end