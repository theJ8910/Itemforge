--[[
base_item
SHARED

base_item is the default item. All items except item inherit from this item-type.
NOTE: The item type is the name of the folder it is in (this is base_item/shared.lua, so this item's type is "base_item")
]]--

include( "health.lua" );
include( "stacks.lua" );
include( "weight.lua" );
include( "nwvars.lua" );
include( "timers.lua" );
include( "sounds.lua" );
include( "events_shared.lua" );

--[[
Non-Networked Vars
These vars are stored on both the client and the server, however, if these vars change on one side, they aren't updated on the other side.
This section is good for things that don't change often but need to be known to both the client and server, such as the item's name.
]]--

--Basic info
ITEM.Name				= "Default Item Name";						--An item's name is displayed by the UI in several different locations, such as the weapon selection menu (when the item is held), or displayed when selected in an inventory.
ITEM.Description		= "This is the default description.";		--An item's description gives additional details about the item. One place it is displayed is in the inventory when selected.
ITEM.Base				= "base_nw";								--The item is based off of this kind of item. Set this to nil if it's not based off of an item. Set it to the type of another item (ex: ITEM.Base = "hammer") to base it off of that. (NOTE: This is useful for tools. For example: If you have an item called "Hammer" that "Stone Hammer" and "Iron Hammer" are based off of, and you have a combination that takes "Hammer" as one of it's ingredients, both the "Stone Hammer" and "Iron Hammer" can be used!)
ITEM.WorldModel			= "models/dav0r/buttons/button.mdl";		--When dropped on the ground, held by a player, or viewed on some places on the UI (like an inventory icon), the world model is the model displayed.
ITEM.ViewModel			= "models/weapons/v_pistol.mdl";			--When held by a player, the player holding it sees this model in first-person.
ITEM.Size				= 1;										--Default size of a single item in this stack. Size has nothing to do with how big the item looks or how much it weighs. Instead, size determines if an item can be placed in an inventory or not. In my opinion, a good size can be determined if you put the item into the world and get the entity's bounding sphere size.
ITEM.Color				= Color( 255, 255, 255, 255 );				--Default color of this item's model and icon. Can be changed.
ITEM.OverrideMaterial	= nil;										--Default override material of this item's world model. Use nil if the model's material is not being overridden, or "path" if it is (where path is the path of the material). Can be changed.

--Restrictions on who can spawn
ITEM.Spawnable			= false;									--Can this item be spawned by any player via the spawn menu on the items tab?
ITEM.AdminSpawnable		= false;									--Can this item be spawned by an admin via the spawn menu on the items tab?

--SWEP related
ITEM.SWEPPrimaryAuto	= false;									--If this item is held as a weapon, is it's primary fire automatic by default? Or, in other words, do I have to keep clicking to attack?
ITEM.SWEPSecondaryAuto	= false;									--If this item is held as a weapon, is it's secondary fire automatic by default? Or, in other words, do I have to keep right-clicking to attack?
ITEM.SWEPHoldType		= "pistol";									--How does a player hold this item when he is holding it as a weapon (by default)? Valid values: "pistol", "smg", "grenade", "ar2", "shotgun", "rpg", "physgun", "crossbow", "melee", "slam", "normal", "fist", "melee2", "passive", "knife", "duel"
ITEM.SWEPSlot			= 0;										--What slot # is this item categorized under in the weapon menu? (where 0 is slot #1, 1 is slot #2, etc)
ITEM.SWEPSlotPos		= 0;										--When you're selecting weapons from that slot, what order does this weapon come in? (where 0 means the weapon comes first, 1 means weapon comes second, etc. This is more of a suggestion than a hardline rule to the game; several items can have the same order.)
ITEM.SWEPViewModelFlip	= false;									--Should we flip the viewmodel? If this is true, it makes left-handed viewmodels righthanded, and makes right-handed viewmodels lefthanded.

--Don't modify/override these. They're either set automatically, don't need to be changed, or are listed here so I can keep track of them.
--Belongs to item-type
ITEM.ClassName			= "";										--The item-type. This is the same as the name of the folder these files are in. This is set automatically when loading item-types.
ITEM.BaseClass			= nil;										--Set to the Item-Type that ITEM.Base identifies after loading all item-types
ITEM.NWCommandsByName	= nil;										--Networked commands are stored here. The key is the name, value is the command. These trigger networked hooks on the other side (Client to Server or Server to Client).
ITEM.NWCommandsByID		= nil;										--Networked commands are stored here. The key is the id, value is the command. These trigger networked hooks on the other side (Client to Server or Server to Client).

--Belongs to individual items
ITEM.ID					= 0;										--Item ID. Assigned automatically.
ITEM.NextThink			= 0;										--If the item is set to think, the next think will occur at this time. Can be set with self:SetNextThink() (makes the most sense to call this from an ITEM:OnThink() event)
ITEM.Container			= nil;										--If the item is in an inventory, this is the inventory it is in.			Use self:GetContainer() to grab.
ITEM.Entity				= nil;										--If the item is on the ground, this is the SENT that represents the item.	Use self:GetEntity() to grab this.
ITEM.Weapon				= nil;										--If the item is being held by a player, this is the SWEP entity.			Use self:GetWeapon() to grab this.
ITEM.Owner				= nil;										--If the item is being held, this is the player holding it.					Use self:GetWOwner() to grab this. (NOTE: GetNetOwner() does not return this).
ITEM.BeingRemoved		= false;									--This will be true if the item is being removed.
ITEM.Inventories		= nil;										--Inventories connected to this item are stored here. The item 'has' these inventories (a backpack or a crate would store it's inventory here, for example). The key is the inventory's ID. The value is the actual inventory.
ITEM.Rand				= nil;										--Every item has a random number. This is mostly used for adding some variety to different effects, such as the model spinning. Use self:GetRand() to grab this.
ITEM.ViewmodelIdleAt	= 0;										--When the item is held as an SWEP, the viewmodel's idle animation should play at this time.

local HoldTypeToIDHashTable = {
	["pistol"]		= 0,
	["smg"]			= 1,
	["grenade"]		= 2,
	["ar2"]			= 3,
	["shotgun"]		= 4,
	["rpg"]			= 5,
	["physgun"]		= 6,
	["crossbow"]	= 7,
	["melee"]		= 8,
	["slam"]		= 9,
	["normal"]		= 10,
	["fist"]		= 11,
	["melee2"]		= 12,
	["passive"]		= 13,
	["knife"]		= 14,
	["duel"]		= 15,
};

local HoldTypeToStringHashTable = {
	[0]		= "pistol",
	[1]		= "smg",
	[2]		= "grenade",
	[3]		= "ar2",
	[4]		= "shotgun",
	[5]		= "rpg",
	[6]		= "physgun",
	[7]		= "crossbow",
	[8]		= "melee",
	[9]		= "slam",
	[10]	= "normal",
	[11]	= "fist",
	[12]	= "melee2",
	[13]	= "passive",
	[14]	= "knife",
	[15]	= "duel",
};

--[[
DEFAULT METHODS
DO NOT OVERRIDE
IN THIS SCRIPT
OR OTHER SCRIPTS
]]--

local aZero = Angle( 0, 0, 0 );

--[[
* SHARED
* Protected

Removes the item.
]]--
function ITEM:Remove()
	return IF.Items:Remove( self );
end
IF.Items:ProtectKey( "Remove" );

--[[
* SHARED
* Protected

This function puts an item inside of an inventory.
inv is the inventory to add the item to.
slot is an optional number that requests a certain slot to insert the item into. This should be the slot number you want to place the item in (starting at 1), or nil if any slot will do.
	false is returned if the item cannot be placed in the requested slot.
If pl is given, only that player will be told to add the item to the given inventory clientside.
	This is useful for sending an update of what inventory the item is in to a specific player.
bNoMerge is an optional true/false. If bNoMerge is:
	true, the item won't automatically merge itself with existing items of the same type in the given inventory, even if it normally would.
	false or not given, then this function calls the CanInventoryMerge of both this item and the item it's trying to merge with.
		If both items approve, the two are merged and this item removed as part of the merge.
		If for some reason a merge can't be done, false is returned.
bPredict is an optional true/false that defaults to false on the server and true on the client. If bPredict is:
	false, then we will actually insert the item into the inventory.
	true, instead we are predicting whether or not we can insert the item into the inventory.

This function calls this item's CanMove event. CanMove can stop the item from being inserted into / being moved to an inventory.
When this item is successfully moved to the inventory, the OnMove event is called.

If the item cannot be inserted for any reason, then false is returned. True is returned otherwise.
NOTE: If this item merges with an existing item in the inventory, false is returned, and this item is removed.
TODO: This function needs to be reworked to reduce it's complexity
]]--
function ITEM:ToInventory( inv, slot, pl, bNoMerge, bPredict )
	if self.BeingRemoved then return false end
	if !IF.Util:IsInventory( inv )				then return self:Error( "Could not insert item into an inventory - given inventory was invalid!\n" ) end
	if pl != nil then
		if !pl:IsValid()						then return self:Error( "Couldn't insert item into "..tostring( inv )..". Player given is not valid!\n" );
		elseif !pl:IsPlayer()					then return self:Error( "Couldn't insert item into "..tostring( inv )..". The player given is not a player.\n" );
		elseif !inv:CanNetwork( pl )			then return self:Error( "Couldn't insert item into "..tostring( inv )..". The inventory given is private, and the player given is not the owner of the inventory.\n" );
		end
	end
	
	if bPredict == nil then bPredict = CLIENT end
	local oldinv, oldslot = self:GetContainer();
	
	if SERVER || bPredict then
		local bSameInv = ( oldinv == inv );
		if bSameInv && !slot					then return self:Error( "Couldn't insert item into "..tostring( inv )..". The item is already in this inventory. No slot was given, so the item can't be moved to a different slot, either.\n" ) end
		
		local bSameSlot = ( oldslot == slot );
		local bSendingUpdate = ( bSameInv && bSameSlot );
		if !bSendingUpdate && !self:Event( "CanMove", true, oldinv, oldslot, inv, slot ) then return false end	
		
		--We're moving the item from one slot to another in the same inv
		if bSameInv then
			if !bSameSlot then
				if !inv:MoveItem( self, oldslot, slot, bPredict ) then return false end
			
				--Ask client to transfer slots too
				if SERVER && !bPredict then self:SendNWCommand( "TransferSlot", nil, inv, oldslot, slot ); end
				return true;
			end
		
		--[[
		Since we're not moving items around, that means the item has just entered this inventory.
		We'll merge this stack with as many existing stacks of items as possible (unless told not to).
		false is returned if/when this whole stack has been merged into other stacks of items.
		]]--
		elseif !bNoMerge then
			
			--TODO prediction will fail if we have to merge across several stacks of items
			for k, v in pairs( inv:GetItemsByType( self:GetType() ) ) do if self:Event( "CanInventoryMerge", false, v, inv ) && v:Event( "CanInventoryMerge", false, self, inv ) && v:Merge( self, nil, bPredict ) == true then return false end end
		end
	else
		--We don't stop insertion clientside if the item has an entity or another container already, but we bitch about it so the scripter knows something isn't right
		if slot == nil				then return self:Error( "Could not add item to "..tostring( inv ).." clientside! slot was not given!\n" ) end
		if oldinv && oldinv != inv	then self:Error( "Warning! This item is already in "..tostring( oldinv ).." clientside, but is being inserted into "..tostring( inv ).." anyway! Not supposed to happen!\n" ) end
	end
	
	local slotid = inv:InsertItem( self, slot, nil, bPredict );
	if slotid == false || ( slot != nil && slotid != slot ) then return false end
	
	if !bPredict then
		self:SetContainer( inv );
		self:Event( "OnMove", nil, oldinv, oldslot, inv, slotid, false );
		
		if SERVER then
			--This was a real headache to do but I think I maxed out the efficency
			local newOwner = inv:GetOwner();
			local lastOwner = self:GetOwner();
			if bSendingUpdate then
				self:SendNWCommand( "ToInventory", pl, inv, slotid );
			else
				--Publicize or privitize the item
				self:SetOwner( lastOwner, newOwner );
			
				--Is the item going public?
				if newOwner == nil then
					
					--From a public...
					if lastOwner == nil then
						--container?
						if oldinv then
							self:SendNWCommand( "TransferInventory", nil, oldinv, inv, slotid );
						
						--...setting (void, world, held)?
						else
							self:SendNWCommand( "ToInventory", nil, inv, slotid );
						end
					
					--...from a private inventory? 
					elseif lastOwner != nil then
						--Insert it into the given inventory clientside on everybody but the last owner.
						for k,v in pairs( player.GetAll() ) do if v != lastOwner then self:SendNWCommand( "ToInventory", v, inv, slotid ); end end
						
						--On the last owner, transfer to the new inventory.
						self:SendNWCommand( "TransferInventory", lastOwner, oldinv, inv, slotid );
					end
					
				--or private?
				else
					--...from a public...
					if lastOwner == nil then
						--container?
						if oldinv then
							--Transfer from the old inventory to the new inventory on the new owner.
							self:SendNWCommand( "TransferInventory", newOwner, oldinv, inv, slotid );
							
						--setting?
						else
							--Insert it on the new owner.
							self:SendNWCommand( "ToInventory", newOwner, inv, slotid );
						end
						
						
					--...from a private inventory owned by the same guy?
					elseif lastOwner == newOwner then
					
						--Transfer from the old inventory to the new inventory.
						self:SendNWCommand( "TransferInventory", newOwner, oldinv, inv, slotid );
						
					--...from a private inventory not owned by the same guy?
					else
						--Insert it on the new owner.
						self:SendNWCommand( "ToInventory", newOwner, inv, slotid );
					end
				end
			end
		end
	end
	return true;
end
IF.Items:ProtectKey( "ToInventory" );

--A shorter alias
ITEM.ToInv = ITEM.ToInventory;
IF.Items:ProtectKey( "ToInv" );

--[[
* SHARED
* Protected

Serverside, this function places the item in the world (as an entity).
Clientside, this function is called when the item binds with it's world entity.

vPos is a Vector() describing the position in the world the entity should be created at.
ang is an optional Angle() describing the angles it should be created at.
If the item is already in the world, the item's world entity will be teleported to the given position and angles.
	If for some reason you want to actually want to re-send it to the world with a new entity instead of just teleporting it,
	send it to the void first with :ToVoid() and then :ToWorld() it where you want it.
eEnt is only necessary clientside. This is the entity the item is binding with.
bPredict is an optional true/false that defaults to false on the server and true on the client. If bPredict is true:
	false, we'll send the item to the world. Serverside, this creates an entity. Clientside, this sets the item's entity to eEnt. OnEnterWorld events are called in both cases.
	true, instead of sending the item to the world, we'll return true if the item can be sent to the world, or false if it can't be for some reason.

This function calls the CanEnterWorld event. This event has a chance to stop the move.
If the item had a new world entity created, then:
	The item's OnEntityInit event is called, which is used to set up the entity after it's been created.
	The item's OnEnterWorld event is called.

false is returned if the item cannot be moved to the world for any reason.
Otherwise, the entity created is returned.
]]--
function ITEM:ToWorld( vPos, ang, eExistingEnt, bPredict )
	if self.BeingRemoved then return false end
	
	if bPredict == nil then bPredict = CLIENT end
	
	local eEntity = self:GetEntity();
	local bTeleport = ( eEntity != nil );
	
	if SERVER || bPredict then
		if vPos == nil then return self:Error( "Could not create an entity, position to create item at was not given.\n" ) end
		ang = ang or aZero;
		
		--Give events a chance to stop the item from moving to the world there
		if !self:Event( "CanEnterWorld", true, vPos, ang, bTeleport ) then return false end
		
		--Just teleport this item's ent if it's already in the world
		if bTeleport then
			if bPredict then return true end
			
			eEntity:SetPos( vPos );
			eEntity:SetAngles( ang );
			
			local phys = eEntity:GetPhysicsObject();
			if IsValid( phys ) then
				phys:Wake();
			end
		else
			--Before we send the item to the world we have to remove it from where it was (or fail if we couldn't)
			if !self:ToVoid( false, nil, nil, bPredict ) then return false end
			
			if bPredict then
				return true;
			else
				eEntity = ents.Create( IF.Items.BaseEntityClassName );
				if !IsValid( eEntity ) then return self:Error( "Tried to create "..IF.Items.BaseEntityClassName.." entity but failed.\n" ) end
				
				eEntity:SetItem( self );
				eEntity:SetPos( vPos );
				eEntity:SetAngles( ang );
				self:SetEntity( eEntity );
				
				IF.Items:AddWorldItem( self );
			end
		end
	else
		if !IsValid( eExistingEnt ) then return self:Error( "Couldn't set entity clientside... no valid entity was given.\n" ) end
		
		--Ideally, this item should never already have an entity when a new one is given to it clientside. However, it happens - sometimes an item acquires a new entity before an old one can be removed, so I'm making it ignore this check.
		--if bTeleport then self:Error( "Warning! Setting entity to "..tostring( eExistingEnt ).." even though it already has an entity ("..tostring( eEntity )..")!\n" ) end
		
		eEntity = eExistingEnt;
		self:SetEntity( eEntity );
		
		IF.Items:AddWorldItem( self );
	end
	
	--Run events to indicate a :ToWorld() occured
	self:Event( "OnEnterWorld", nil, eEntity, vPos, ang, bTeleport );
	return eEntity;
end
IF.Items:ProtectKey( "ToWorld" );

--[[
* SHARED
* Protected

This function makes the given player hold this item as a weapon. 

pl should be a player entity.
bNoMerge is an optional true/false. If the player given is already holding a stack of items of this type (ex: player is holding a handful of pebbles, and is trying to :Hold() more pebbles), and bNoMerge is:
	false or not given, and both items CanHoldMerge events allow it, then the two stacks will attempt to merge. False is returned if this item __successfully__ merged with another stack. 
	true, then no attempt to merge the two items into one stack will be made, even if it normally would. Rather than merge the two stacks, we'll attempt to hold this stack as a seperate weapon in the weapon menu.
bPredict is an optional true/false that defaults to false on the server and true on the client. If bPredict is:
	false, then we're actually trying to hold the weapon.
	true, then we're predicting whether or not we will be allowed to hold the weapon. true/false is returned if the weapon can/can't be held.
eWeapon is only necessary clientside. This will be the SWEP created for this item.

Serverside this function calls the CanHold event, which has a chance to stop the item from being held.
If the item is successfully held:
	The item's OnSWEPInit event is called to initialize the SWEP.
	The item's OnHold event is called.

false is returned if the item can't be held for any reason. Otherwise, the newly created weapon entity is returned.
]]--
function ITEM:Hold( pl, bNoMerge, eWeapon, bPredict )
	if self.BeingRemoved then return false end
	if self:GetWOwner() == pl then return true end
	
	if bNoMerge == nil then bNoMerge = false end
	if bPredict == nil then bPredict = CLIENT end
	
	local eEntity;
	
	if SERVER || bPredict then
		if !pl || !pl:IsValid()	then return self:Error( "Couldn't hold item as weapon. Player given is not valid!\n" )
		elseif !pl:IsPlayer()	then return self:Error( "Couldn't hold item as weapon. The player given is not a player.\n" )
		elseif !pl:Alive()		then return false end
		
		--We can allow the events a chance to stop the item from being held
		if !self:Event( "CanHold", true, pl ) then return false end
		
		
		
		--Here we determine two things: Can we merge this stack of items with a stack we're holding?
		local strWeaponName = "if_"..self.ClassName;
		
		--TODO pl:GetWeapon is SERVER ONLY ARGhdhsgsgdjlk garry/valve you cocksuckers
		if SERVER then
			local currentlyHeld = pl:GetWeapon( strWeaponName );
			if currentlyHeld && currentlyHeld:IsValid() then
				if !bNoMerge then
					local heldItem = currentlyHeld:GetItem();
					if heldItem && self:Event( "CanHoldMerge", false, heldItem, pl ) && heldItem:Event( "CanHoldMerge", false, self, pl ) && heldItem:Merge( self, nil, bPredict ) then
						return false;
					end
				end
				return false;
			end
		end
		
		--[[
		Send to void. False is returned in case of errors or if events stop the removal of the item from it's current medium.
		We try to send an item to the void when all other possible errors have been ruled out.
		If we didn't... this could happen: We put the item in the void, then try to put it in the world but can't create the ent. So our item is stuck in the void. We try to avoid this.
		]]--
		if !self:ToVoid( false, nil, nil, bPredict ) then return false end
		
		if bPredict then
			return true;
		else
			--eEntity = pl:Give( strWeaponName );
			eEntity = ents.Create( strWeaponName );
			if !IsValid( eEntity ) then return self:Error( "Tried to create "..strWeaponName.." entity but failed.\n" ) end
			
			local vPos = pl:GetPos();
			vPos.z = vPos.z + 32;
			eEntity:SetPos( vPos );
			eEntity:Spawn();

			--In some irritating cases (standing on an elevator / or noclipping into the world), sometimes the weapon fails to pickup. This marks the player who we intended the weapon to be picked up by.
			eEntity:RegisterFailedPickup( pl );

			--This function triggers the item's OnSWEPInit hook.
			eEntity:SetItem( self );
			
		end
	else
		eEntity = eWeapon;
	end
	
	self:SetWeapon( eEntity );
	self:SetWOwner( pl );
	IF.Items:AddHeldItem( self );
	
	--Run OnHold event
	self:Event( "OnHold", nil, pl, eEntity );
	
	return eEntity;
end
IF.Items:ProtectKey( "Hold" );

--[[
* SHARED
* Protected

Moves this item to the same location as another item
extItem should be an existing item. If extItem is:
	In the world, this item is moved to the world at the exact same position and angles. Additionally, this item will be travelling at the same velocity as extItem when it is created.
	In an inventory, this item is moved to the inventory that extItem is in. If we can't fit the item in that inventory, we try to send it to the same location as the item/entity it's connected to.
	Held by a player, this item is also held by the player. If the player cannot hold any more items, then the item is moved to the world, at the shoot location of the player holding it.
	In the void, this item is moved to the void.

bScatter is an optional true/false.
	If bScatter is true and extItem is in the world,
	the angles the items are placed in the world at will be random,
	and the position will be chosen randomly from inside of extItem's bounding box,
	rather than spawning at the entity's center.

bNoMerge is an optional true/false. If extItem is in held or in an inventory, then the auto-merge will be disabled.

bPredict is an optional true/false that defaults to false on the server and true on the client. If bPredict is:
	false, we are actually sending the item to the same location as another item.
	true, we are predicting whether or not we can send the item to the same location as another item.

true is returned if the item was successfully moved to the same location as extItem. false is returned if the item could not be moved for any reason.
TODO sometimes the items fall through the world, could probably fix by taking the bounding box size of this item into consideration when picking a scatter location
]]--
function ITEM:ToSameLocationAs( extItem, bScatter, bNoMerge, bPredict )
	if !extItem or !extItem:IsValid() then return self:Error( "Tried to move item to same location as another item, but the other item wasn't given / was invalid!\n" ) end
	
	if bScatter == nil then bScatter = false  end
	if bNoMerge == nil then bNoMerge = false  end
	if bPredict == nil then bPredict = CLIENT end
	
	local invContainer = extItem:GetContainer();
	if invContainer then

		--Sometimes we'll inventory merge, which returns false in :ToInventory but also removes this item.
		--TODO make it return true instead
		if !self:ToInventory( invContainer, nil, nil, bNoMerge, bPredict ) && self:IsValid() then
			--If we can't move the item to the container that extItem was in, we'll try moving it to the same place as that container's connected item.
			local t = invContainer:GetConnectedItems();
			local c = table.getn( t );
			
			--If this inventory isn't connected to anything we fail
			if c == 0 then return false end
			
			--If it is though, we'll pick one of the connections randomly and send the item to that location
			return self:ToSameLocationAs( t[ math.random(1,c) ], bScatter, bNoMerge, bPredict );
		end
		
		return true;
	elseif extItem:InWorld() then
		local eEntity = extItem:GetEntity();
		local eNewEntity;
		if bScatter then
			local vWhere	= eEntity:LocalToWorld( IF.Util:RandomVectorInAABB( eEntity:OBBMins(), eEntity:OBBMaxs() ) );
			local aWhere	= IF.Util:RandomAngle();
			
			eNewEntity		= self:ToWorld( vWhere, aWhere, nil, bPredict );
			if !eNewEntity then return false end
		else
			eNewEntity		= self:ToWorld( eEntity:GetPos(), eEntity:GetAngles(), nil, bPredict );
			if !eNewEntity then return false end
		end
		
		if !bPredict then
			local eNewEntityPhys = eNewEntity:GetPhysicsObject();
			if IsValid( eNewEntityPhys ) then eNewEntityPhys:SetVelocity( eEntity:GetVelocity() ) end
		end
		
		return true;
	elseif extItem:IsHeld() then
		local pl = extItem:GetWOwner();
		if !pl then return self:Error( "Trying to move item failed. The item given, "..tostring(extItem).." is being held, but player holding it could not be determined.\n" ) end
		
		--The :IsValid() check is here because Hold() could return false to indicate that this item was merged into an existing stack the player was holding
		if self:Hold( pl, bNoMerge, nil, bPredict ) || !self:IsValid() || self:ToWorld( pl:GetShootPos(), pl:GetAimVector(), nil, bPredict ) then return true end
		
		return false;
	end
	
	if !self:ToVoid( nil, nil, nil, bPredict ) then return false end
	return true;
end
IF.Items:ProtectKey( "ToSameLocationAs" );

--[[
* SHARED
* Protected

ToVoid releases a held item, removes the item from the world, or takes an item out of an inventory. Or in other words, it places the item in the void.
It isn't necessary to send an item to the void after it's created - the item is already in the void.

bForced is an optional argument that should be true if you want the removal to ignore events that say not to release/remove/etc.
	This should only be true if the item has to come out, like if the item is being removed.
vDoubleCheck is an optional variable.
	You can give this if you want to make sure that the item is being removed from the right inventory, entity, or weapon.
	Sometimes, an item will be added to an inventory or something before the entity it was using is removed. When the entity gets removed, it voids the item. vDoubleCheck helps ensure we don't accidentilly take it out of the new location it's in when the entity gets removed.
	This can be nil, an inventory, or an Itemforge SENT/SWEP. There's really no reason for a scripter to have to use this; Itemforge uses this internally.
bNotFromClient is an optional true/false that only applies if this item is being removed from an inventory serverside. If bNotFromClient is:
	true, the item will not be instructed to remove itself clientside. When utilized properly this can be used to save bandwidth with networking macros.
	false, or not given, it will automatically be removed clientside.
bPredict is an optional true/false that defaults to false on the server and true on the client. If bPredict is:
	false, then we will actually void the item.
	true, then instead of actually voiding the item we'll just return whether it's possible or not.

true is returned if the item was placed in the void, or is in the void already.
false is returned if the item couldn't be placed in the void.
]]--
function ITEM:ToVoid( bForced, vDoubleCheck, bNotFromClient, bPredict )
	if bForced == nil		 then bForced = false			end
	if bNotFromClient == nil then bNotFromClient = false	end
	if bPredict == nil		 then bPredict = CLIENT			end
	
	--Is the item in the world?
	if self:InWorld() then
		local eEntity = self:GetEntity();
		if vDoubleCheck && eEntity != vDoubleCheck then return false end
		
		if !bForced && ( SERVER || bPredict ) && !self:Event( "CanExitWorld", true, eEntity ) then return false end
		if !bPredict then
			self:ClearEntity();
			if SERVER then eEntity:ExpectedRemoval();
			else		   eEntity:SetItem( nil );
			end
			
			IF.Items:RemoveWorldItem( self );
			
			--TODO: DETERMINE IF SERVER FORCED REMOVAL
			self:OnExitWorldSafe( bForced );
		end

	--Maybe it's being held.
	elseif self:IsHeld() then
		local eWeapon = self:GetWeapon();
		if vDoubleCheck && eWeapon != vDoubleCheck then return false end
		local plOwner = self:GetWOwner();
		
		if !bForced && ( SERVER || bPredict ) && !self:Event( "CanRelease", true, plOwner ) then return false end
		if !bPredict then
			if SERVER then eWeapon:ExpectedRemoval();
			else		   eWeapon:SetItem( nil );
			end

			self:ClearWeapon( vDoubleCheck );
			
			IF.Items:RemoveHeldItem( self );
			
			--TODO: DETERMINE IF SERVER FORCED REMOVAL
			self:Event( "OnRelease", nil, plOwner, bForced );
		end
		
	--So we're not in the world or held; How about a container?
	elseif self:InInventory() then
		local invContainer, cslot = self:GetContainer();
		if vDoubleCheck && invContainer != vDoubleCheck then return false end
		
		--If removal isn't forced our events can stop the removal
		if !bForced && ( SERVER || bPredict ) && !self:Event( "CanMove", true, invContainer, cslot ) then return false end
		if !invContainer:RemoveItem( self:GetID(), bForced, bPredict ) && !bForced && ( SERVER || bPredict ) then return false end
		
		if !bPredict then
			self:ClearContainer();
			self:Event( "OnMove", nil, invContainer, cslot, nil, nil, bForced );
		
			--Tell clients to remove this item from the inventory (unless specifically told not to)
			if SERVER && !bNotFromClient then
				local plOldOwner = invContainer:GetOwner();
				self:SetOwner( plOldOwner, nil );
				self:SendNWCommand( "RemoveFromInventory", plOldOwner, bForced, invContainer );
			end
		end
	end
	
	return true;
end
IF.Items:ProtectKey( "ToVoid" );

--[[
* SHARED
* Protected

Sets the size of every item in the stack.

Size has nothing to do with weight or how big the item looks.
The only thing size determines is if an item can be placed inside of an inventory that has a size limit.

iSize can be 0 to indicate it has no size, but negative values will result in an error.
]]--
function ITEM:SetSize( iSize )
	if iSize < 0 then return self:Error( "You can't set size to a negative value ("..iSize..")." ) end
	return self:SetNWInt( "Size", iSize );
end
IF.Items:ProtectKey( "SetSize" );

--[[
* SHARED
* Protected

This sets whether or not the primary automatically refires while the player holding the item holds his primary attack button down.

This hook can be run on the server, or in a predicted shared event.
If run only on the server, the primary becomes manual/automatic on the server, and then becomes manual/automatic on the clients a short time later.
If run in a predicted, shared hook, the primary becomes manual/automatic on the server and client at the same time.
	Running it in a predicted shared hook will help minimize weapon prediction errors.

bAuto should be true or false:
    If this is true, the primary automatically refires while holding down the primary attack button.
	If this is false, the primary does not refire automatically. The player has to click each time he wants to fire.
]]--
function ITEM:SetSWEPPrimaryAuto( bAuto )
	return self:SetNWBool( "SWEPPrimaryAuto", bAuto );
end
IF.Items:ProtectKey( "SetSWEPPrimaryAuto" );

--[[
* SHARED
* Protected

This sets whether or not the secondary automatically refires while the player holding the item holds his secondary attack button down.

This hook can be run on the server, or in a predicted shared event.
If run only on the server, the secondary becomes manual/automatic on the server, and then becomes manual/automatic on the clients a short time later.
If run in a predicted, shared hook, the secondary becomes manual/automatic on the server and client at the same time.
	Running it in a predicted shared hook will help minimize weapon prediction errors.

bAuto should be true or false:
    If this is true, the secondary automatically refires while holding down the secondary attack button.
	If this is false, the secondary does not refire automatically. The player has to click each time he wants to fire.
]]--
function ITEM:SetSWEPSecondaryAuto( bAuto )
	return self:SetNWBool( "SWEPSecondaryAuto", bAuto );
end
IF.Items:ProtectKey( "SetSWEPSecondaryAuto" );

--[[
* SHARED
* Protected

This function sets the SWEP holdtype.
The holdtype controls how the player holds this item while holding it as a weapon.

strHoldType should be the holdtype you want to use.
	See ITEM.SWEPHoldType at the top of the file for a list of valid values.
]]--
function ITEM:SetSWEPHoldType( strHoldType )
	return self:SetNWInt( "SWEPHoldType", self:HoldTypeToID( strHoldType ) );
end
IF.Items:ProtectKey( "SetSWEPHoldType" );

--[[
* SHARED
* Protected

This sets whether or not the viewmodel is flipped when holding this item.

Running this on the server will apply the viewmodel flip to any player who holds this item.
Running this on the client will only apply the viewmodel flip for that player, however.

bShouldFlip should be true or false:
    If this is true, the viewmodel is flipped (left handed viewmodels become right handed viewmodels, and right handed viewmodels become left handed viewmodels)
	If this is false, no viewmodel flipping is performed
]]--
function ITEM:SetSWEPViewModelFlip( bShouldFlip )
	if bShouldFlip == nil then return self:Error( "Couldn't set viewmodel flip; true/false value was expected but was not delivered." ) end
	
	return self:SetNWBool( "SWEPViewModelFlip", bShouldFlip );
end
IF.Items:ProtectKey( "SetSWEPViewModelFlip" );

--[[
* SHARED
* Protected

This sets the weapon menu slot and it's position in that slot that the item uses
when it's being held as a weapon.

Running this on the server will change the slot/position of any player who holds this item.
Running this on the client will only change the slot/position for that player, however.
]]--
function ITEM:SetSWEPSlot( iSlot, iSlotPos )
	if iSlot == nil		then return self:Error( "Couldn't set SWEP slot; the slot was invalid." ) end
	if iSlotPos == nil	then iSlotPos = self:GetSWEPSlotPos() end
	
	return self:SetNWInt( "SWEPSlot", iSlot ) && self:SetNWInt( "SWEPSlotPos", iSlotPos );
end
IF.Items:ProtectKey( "SetSWEPSlot" );

--[[
* SHARED
* Protected

This sets the model color/icon color of this item.
]]--
function ITEM:SetColor( cCol )
	self:SetNWColor( "Color", cCol );
end
IF.Items:ProtectKey( "SetColor" );

--[[
* SHARED
* Protected

This sets the override material this item uses for it's model.
]]--
function ITEM:SetOverrideMaterial( sMat )
	self:SetNWString( "OverrideMaterial", sMat );
end
IF.Items:ProtectKey( "SetOverrideMaterial" );








--[[
* SHARED
* Protected

Returns the itemtype of this item
For example "base_item", "item_crowbar", etc...
]]--
function ITEM:GetType()
	return self.ClassName;
end
IF.Items:ProtectKey( "GetType" );

--[[
* SHARED
* Protected

Returns the item/stack's ID.
]]--
function ITEM:GetID()
	return self.ID;
end
IF.Items:ProtectKey( "GetID" );

--[[
* SHARED
* Protected

Returns this item's random number.
Generates a random number for the item if it doesn't have one yet.
]]--
function ITEM:GetRand()
	if !self.Rand then self.Rand = 100 * math.random() end
	return self.Rand;
end
IF.Items:ProtectKey( "GetRand" );

--[[
* SHARED
* Protected

Get the size of an item in the stack (they all are the same size).
]]--
function ITEM:GetSize()
	return self:GetNWInt( "Size" );
end
IF.Items:ProtectKey( "GetSize" );

--[[
* SHARED
* Protected

Returns the world model.
]]--
function ITEM:GetWorldModel()
	return self:GetNWString( "WorldModel" );
end
IF.Items:ProtectKey( "GetWorldModel" );

--[[
* SHARED
* Protected

Returns the view model.
]]--
function ITEM:GetViewModel()
	return self:GetNWString( "ViewModel" );
end
IF.Items:ProtectKey( "GetViewModel" );

--[[
* SHARED
* Protected

This returns whether or not the primary automatically refires while the player holding the item holds his primary attack button down.
]]--
function ITEM:GetPrimaryAuto()
	return self:GetNWBool( "SWEPPrimaryAuto" );
end
IF.Items:ProtectKey( "GetPrimaryAuto" );

--[[
* SHARED
* Protected

This returns whether or not the secondary automatically refires while the player holding the item holds his secondary attack button down.
]]--
function ITEM:GetSecondaryAuto()
	return self:GetNWBool( "SWEPSecondaryAuto" );
end
IF.Items:ProtectKey( "GetSecondaryAuto" );

--[[
* SHARED
* Protected

This function returns the SWEP holdtype.
The holdtype controls how the player holds this item while holding it as a weapon.
]]--
function ITEM:GetSWEPHoldType( strHoldType )
	return self:HoldTypeToString( self:GetNWString( "SWEPHoldType" ) );
end
IF.Items:ProtectKey( "GetSWEPHoldType" );

--[[
* SHARED
* Protected

This returns the weapon menu slot the item uses
when it's being held as a weapon.
]]--
function ITEM:GetSWEPSlot()
	return self:GetNWInt( "SWEPSlot" );
end
IF.Items:ProtectKey( "GetSWEPSlot" );

--[[
* SHARED
* Protected

This returns whether or not the viewmodel is flipped
when it's being held as a weapon.
]]--
function ITEM:GetSWEPViewModelFlip()
	return self:GetNWBool( "SWEPViewModelFlip" );
end
IF.Items:ProtectKey( "GetSWEPViewModelFlip" );

--[[
* SHARED
* Protected

This returns the position the weapon occupies in the chosen weapon menu slot.
]]--
function ITEM:GetSWEPSlotPos()
	return self:GetNWInt( "SWEPSlotPos" );
end
IF.Items:ProtectKey( "GetSWEPSlotPos" );

--[[
* SHARED
* Protected

This returns the current model color/icon color of this item.
]]--
function ITEM:GetColor()
	return self:GetNWColor( "Color" );
end
IF.Items:ProtectKey( "GetColor" );

--[[
* SHARED
* Protected

This returns the override material this item uses for it's model.
]]--
function ITEM:GetOverrideMaterial()
	return self:GetNWString( "OverrideMaterial" );
end
IF.Items:ProtectKey( "GetOverrideMaterial" );

--[[
* SHARED
* Protected

Returns the player who is NetOwner of this item.

The NetOwner is the player who receives networked data about this item.
If the NetOwner is nil, everybody receives networked data about this item.

Items with a NetOwner are called "Private Items".
Items without a NetOwner are called "Public Items".

The NetOwner of the item depends on what inventory this item is in:
	If the item is not in an inventory (in the world, held as a weapon, or in the void) the owner is nil.
	If the item is in a public inventory (an inventory not owned by a player), the owner is nil.
	If the item is in a private inventory (an inventory owned by a player), the owner is the owner of the inventory.
]]--
function ITEM:GetOwner()
	local inv = self:GetContainer();
	if inv == nil then
		return nil;
	end
	return inv:GetOwner();
end
IF.Items:ProtectKey( "GetOwner" );

--[[
* SHARED
* Protected

If the item is in the world, returns the item's world entity.
If the item is held by a player, in an inventory, or in the void, this function returns nil.
Doing :IsValid() on an entity returned from here is not necessary; if this function returns an entity, it is always valid.
]]--
function ITEM:GetEntity()
	if self.Entity && !self.Entity:IsValid() then
		self.Entity = nil;
		return nil;
	end
	return self.Entity;
end
IF.Items:ProtectKey( "GetEntity" );

--[[
* SHARED
* Protected

If the item is being held, returns it's weapon.
If the item is in the world, in an inventory, or in the void, this function returns nil.
Doing :IsValid() on a weapon returned from here is not necessary; if this function returns a weapon, it is always valid.
]]--
function ITEM:GetWeapon()
	if self.Weapon && !self.Weapon:IsValid() then
		self.Weapon = nil;
		return nil;
	end
	return self.Weapon;
end
IF.Items:ProtectKey( "GetWeapon" );

--[[
* SHARED
* Protected

Returns the player who is holding this item as a weapon (the Weapon Owner; this is equivilent to self.Owner in an SWEP).
If the item has been put into an SWEP, but no player is holding it yet, nil is returned (this occasionally happens).
If the item isn't being held as a weapon, this returns nil.
]]--
function ITEM:GetWOwner()
	if self.Owner && !self.Owner:IsValid() then
		self.Owner = nil;
		return nil;
	end
	return self.Owner;
end
IF.Items:ProtectKey( "GetWOwner" );

--[[
* SHARED
* Protected

Returns two values: The inventory the item is in, and the slot that it's occupying in this inventory.
If the item isn't in an inventory, it returns nil, 0.
If the inventory isn't valid any longer (or if the item isn't in the inventory any longer) it's set to nil and nil, 0 is returned
Get the two values like so:
	local inv, slot = item:GetContainer();
]]--
function ITEM:GetContainer()
	if !self.Container then return nil, 0 end
	if !self.Container:IsValid() then
			self.Container = nil;
			return nil, 0;
	end
	local ContainerSlot = self.Container:GetItemSlotByID( self:GetID() );
	if !ContainerSlot then
		self.Container = nil;
		return nil, 0;
	end
	return self.Container, ContainerSlot;
end
IF.Items:ProtectKey( "GetContainer" );

--[[
* SHARED
* Protected

Returns the item's position(s) in the world.

What is returned depends on the state the item is in.
If the item is in the world as an entity, the entity's position is returned.
If the item is being held as a weapon, the shoot position of the holding player is returned (it's usually the center of the player's view).
If the item is in an inventory, the position(s) of the inventory are returned.
	An inventory can be connected with one or more items and entities, or none at all.
	If you get the position of an inventory, it returns the position(s) of the inventory's connected object(s).
	So, if our item is in an inventory connected with a barrel entity, it returns the position of the barrel entity.
	If our item is in a bottle inside of a crate in the world, it returns the bottle's position, which returns the crate's position.
	If our item is in an inventory connected with, lets say, two bags that share the same inventory, then it returns both the positon of the first bag and the second (as a table).
	If the item is in an inventory that doesn't have a connected object, it returns nil.
If the item is in the void (not in any of the either three states) then nil is returned (unless the item has a GetVoidPosition event defined; in that case, it can return nil, a vector, or a table).

SO, in summary, this function can return three different types of data:
	A vector, if the item is in the world, being held, or if the item is in an inventory with one connected object
	a table of vectors, if the item is in an inventory with more than one connected object
	nil, if the item is in the void, or the inventory the item is in is in the void.

You can check to see what this returns by doing...
	local pos = item:GetPos();
	local t = type( pos );
	
Then check to see if 't' is equal to "vector", "table", or "nil".
]]--
function ITEM:GetPos()
	if self:InWorld() then
		local eEntity = self:GetEntity();
		return eEntity:GetPos();
	elseif self:IsHeld() then
		local pl = self:GetWOwner();
		if !pl then self:Error( "ERROR! GetPos failed. This item is being held, but player holding this item is no longer valid.\n" ); return nil end
		return pl:GetShootPos();
	elseif self:InInventory() then
		local invContainer = self:GetContainer();
		return invContainer:GetPos();
	end
	
	return self:Event( "GetVoidPos", nil );
end
IF.Items:ProtectKey( "GetPos" );

--[[
* SHARED
* Protected

Returns how submerged in water the item is, between 0 and 3 (0 if not submerged, returns 3 if fully submerged).
If the item is held, we use the player to calculate water level.
If the item is in the world, we use the item's world entity to calculate water level.

NOTE: The item is considered to be dry if it is in the void or in an inventory.
]]--
function ITEM:GetWaterLevel()
	local eEntity = self:GetWOwner() or self:GetEntity();
	if eEntity then return eEntity:WaterLevel() end
	
	return 0;
end
IF.Items:ProtectKey( "GetWaterLevel" );

--[[
* SHARED
* Protected

Is this item in an inventory? (a specific inventory?) (a specific slot?)

inv is an optional argument.
iSlot is an optional argument.

If neither inv or iSlot is given, then true is returned if the item is in any inventory, any slot.
If inv is given but iSlot isn't, then true will be returned if the item is in the inventory given.
If inv isn't given but iSlot is, true is returned if this item is in that slot on any inventory.
If inv and iSlot are given, true is returned only if this item is in the given inventory, in that slot.
]]--
function ITEM:InInventory( inv, iSlot )
	local bInv = false;
	local bSlot = false;
	local invContainer, iContainerSlot = self:GetContainer();
	
	if invContainer != nil then				--If the item is in a container
		if !inv then						--and inv wasn't given
			bInv = true;
		elseif !inv:IsValid() then			--and inv was given, check to see if this inventory is legit
			self:Error( "ERROR! InInventory() failed. Inventory given is non-existent or has been removed. Check to see if the inventory is valid before passing it.\n" );
		elseif inv == invContainer then		--then check if we're in this inventory
			bInv = true;
		end
		
		if !iSlot || iSlot == iContainerSlot then
			bSlot = true;
		end
	end
	
	return ( bInv && bSlot );
end
IF.Items:ProtectKey( "InInventory" );
ITEM.InInv = ITEM.InInventory;
IF.Items:ProtectKey( "InInv" );

--[[
* SHARED
* Protected

Returns true if the item is in the world
]]--
function ITEM:InWorld()
	local eEntity = self:GetEntity();
	if eEntity then return true; end
	return false;
end
IF.Items:ProtectKey( "InWorld" );

--[[
* SHARED
* Protected

Returns true if the item is being held as a weapon.

plByThisPlayer is an optional argument.
	If plByThisPlayer isn't given, then true will be returned if the item is held by any player at all.
	If plByThisPlayer is given, then true will be returned only if the item is held by the player given.

TODO held by something other than a player
]]--
function ITEM:IsHeld( plByThisPlayer )
	local eEntity = self:GetWeapon();
	if !eEntity then return false end

	if plByThisPlayer != nil then
		--Validate given player
		if !plByThisPlayer:IsValid()		then return self:Error( "IsHeld failed. Given player is non-existent or has been removed.\n" ) end
		if !plByThisPlayer:IsPlayer()		then return self:Error( "ERROR! IsHeld failed. Given player is not a player!\n" ) end
			
		--Check to see if the player holding this is still valid
		local pl = self:GetWOwner();
		if !pl then return self:Error( "ERROR! IsHeld failed. This item is held, but the player holding this item cannot be determined.\n" ) end
			
		--If this item isn't being held by the given player return false. (if it is being held by this player, true is returned beneath this check)
		if pl != plByThisPlayer then return false end
	end
		
	return true;
end
IF.Items:ProtectKey( "IsHeld" );

--[[
* SHARED
* Protected

Returns true if the item is not held, in the world, or in an inventory
]]--
function ITEM:InVoid()
	if !self:GetEntity() && !self:GetWeapon() && !self:GetContainer() then
		return true;
	end
	return false;
end
IF.Items:ProtectKey( "InVoid" );

--[[
* SHARED
* Protected

Protected OnExitWorld event.
Stops all looping sounds and then runs the overridable OnExitWorld event.

bForced will be true if the item was forcibly removed from the world.
]]--
function ITEM:OnExitWorldSafe( bForced )
	self:StopAllLoopingSounds();
	
	--Run the event
	self:Event("OnExitWorld", nil, bForced );
end
IF.Items:ProtectKey( "OnExitWorldSafe" );

--[[
* SHARED
* Protected

Run this to make the item's Think event call every frame.
Think is off by default.
]]--
function ITEM:StartThink()
	IF.Items:AddThinkingItem( self );
end
IF.Items:ProtectKey( "StartThink" );

--[[
* SHARED
* Protected

Sets the time that the next think should occur.
If you want the next think to occur on the next frame, don't call this function, or call it and pass 0 for fNextThink.

fNextThink should be CurTime() + however many seconds you want the next think to occur at.
]]--
function ITEM:SetNextThink( fNextThink )
	self.NextThink = fNextThink;
end
IF.Items:ProtectKey( "SetNextThink" );

--[[
* SHARED

Returns the time (based on CurTime()) that the item's next think should occur.
]]--
function ITEM:GetNextThink()
	return self.NextThink;
end
IF.Items:ProtectKey( "GetNextThink" );

--[[
* SHARED
* Protected

Replaces the item's current OnThink event with the given function.

This is useful if your item behaves differently when it's in different "modes".
For instance, simple items like the item magnet have two modes, off / on. You could have an ITEM:OnThinkWhileOff and an ITEM:OnThinkWhileOn.
Another example, weapons could have different thinks for each of their possible states, e.g. not firing / primary firing / secondary firing / reloading / etc.

To set this as the current think function:
	function ITEM:ExampleThink()
		--Do something
	end
You'd do:	self:SetThinkFunction( self.ExampleThink );

To set
	local function fnExampleThink = function( self )
		--Do something...
	end
You'd do:	self:SetThinkFunction( fnExampleThink );

fnOnThink should be a function that takes self as the first argument and returns nothing.
	NOTE: If this is a function in the item itself (like function ITEM:ExampleThink()) your function already has "self" as a hidden first argument.
]]--
function ITEM:SetThinkFunction( fnOnThink )
end
IF.Items:ProtectKey( "SetThinkFunction" );

--[[
* SHARED
* Protected

Run this to stop the item's Think event from calling every frame.
Think is off by default.
]]--
function ITEM:StopThink()
	IF.Items:RemoveThinkingItem( self );
end
IF.Items:ProtectKey( "StopThink" );

--[[
* SHARED

Fires bullets from this item.
Doesn't play sounds or anything, just fires bullets.
Bullets cannot be fired while the item is in the void.

vFrom is the location the bullets should come from.
vDir is the direction the bullets should travel.
eCredit is the entity the bullet damage should be credited to. Bullets will be fired from this entity.
iNum is the number of bullets to fire.
iDamage is how much damage each bullet should do.
fForce is an impact force multiplier; the bullets will push this much harder against physics objects when they are struck.
vSpread is a vector describing the spread of the bullets.
strTracerType is an optional string describing the bullet tracer to use.
	Valid values: "Tracer", "AR2Tracer", "AirboatGunHeavyTracer", "LaserTracer", "" for none
fnCallback is an optional callback function that is called whenever a bullet strikes an object.
	NOTE: fnCallback cannot be used if more than 1 bullet is being fired.
iAmmoType is an optional integer corresponding to HL2 ammo. This influences things like damage and impact force.
	This is mostly only useful for reproductions of HL2 weapons. Valid values (and what they correspond to) are:
	0	(AR2)				1	(AlyxGun)				2	(Pistol)
	3	(SMG1)				4	(357)					5	(XBowBolt)
	6	(Buckshot)			7	(RPG_Round)				8	(SMG1_Grenade)
	9	(SniperRound)		10	(SniperPenetratedRound)	11	(Grenade)
	12	(Thumper)			13	(Gravity)				14	(Battery)
	15	(GaussEnergy)		16	(CombineCannon)			17	(AirboatGun)
	18	(StriderMinigun)	19	(HelicopterGun)			20	(AR2AltFire)

Returns true if bullets were fired,
and false otherwise.
]]--
function ITEM:ShootBullets( vFrom, vDir, eCredit, iNum, iDamage, fForce, vSpread, strTracerType, fnCallback, iAmmoType )
	
	--If bullets are fired while this item is in an inventory, the object(s) the inventory is connected to takes damage.
	--TODO: This can be further improved by allowing sibling items (items in the same inventory as this item) to become targets,
	--and by doing some kind of bullet psuedosimulation where bullets travel through their randomly selected targets, losing damage, potentially exiting the container into the world, etc.
	local inv = self:GetContainer();
	if inv then
	
		local tItems = inv:GetConnectedItems();
		local tEntities = inv:GetConnectedEntities();
		local iNumConnections = #tItems + #tEntities;

		if iNumConnections == 0 then return false end

		local iDamagePerConnection = iDamage * iNum / ( iNumConnections );
		
		for k, v in pairs( tItems ) do		v:Hurt( iDamagePerConnection );			end
		for k, v in pairs( tEntities ) do	v:TakeDamage( iDamagePerConnection );	end

		return true;

	end

	if iNum != 1 then fnCallback = nil end

	local bullet = {
		Num			= iNum or 1,
		Damage		= iDamage;
		Force		= fForce,
		Spread		= vSpread,
		TracerName	= strTracerType,
		Callback	= fnCallback;
		AmmoType	= iAmmoType;
		Tracer		= 1,
		Src			= vFrom;
		Dir			= vDir;
	};

	eCredit:FireBullets( bullet );
	return true;
end

--[[
* SHARED

If the player is holding this item as a weapon, plays the given viewmodel activity.

I recommend using this function instead of grabbing the weapon and doing SendWeaponAnim on it directly.
After the animation finishes playing, the idle animation will start up automatically.

eViewmodelActivity is an optional ACT_VM_* activity. If this is:
	a viewmodel activity, it is played on the viewmodel.
	nil / not given, nothing happens.
]]--
function ITEM:SendWeaponAnim( eViewmodelActivity )
	if eViewmodelActivity == nil then return end

	local eWep = self:GetWeapon();
	if !eWep then return end
	
	eWep:SendWeaponAnim( eViewmodelActivity );
	
	local pOwner = self:GetWOwner();
	self.ViewmodelIdleAt = CurTime() + pOwner:GetViewModel():SequenceDuration();
end

--[[
* SHARED
* Protected

Run this function to request that a player move the item to a given inventory / slot.

pl is the player who wants to send the item to an inventory.
	If the player is invalid or unable to interact with the item, false is returned.
inv is the inventory the player wants to move the item to.
iSlot is the slot in the inventory the player wants to move the item to.
	Give 0 to indicate you don't care what slot it goes in.

false is returned if the item is unable to be moved for any reason.
true is returned otherwise.
]]--
function ITEM:PlayerSendToInventory( pl, inv, iSlot )
	if !IF.Util:IsPlayer( pl ) || !self:Event( "CanPlayerInteract", false, pl )		then return false end
	if !inv || !inv:IsValid()														then return self:Error( "Couldn't move to inventory as requested by "..tostring( pl )..", inventory given was not valid!\n" ) end
	if iSlot == 0																	then iSlot = nil end
	
	--Predict whether or not the item can be inserted clientside,
	--or actually attempt an insertion serverside
	if !self:ToInventory( inv, iSlot, nil, true ) then return false end
	
	--Clientside, if we've predicted it will succeed then we'll attempt an insertion serverside.
	if CLIENT then
		self:SendNWCommand( "PlayerSendToInventory", inv, iSlot );
	end
	return true;
end
IF.Items:ProtectKey( "PlayerSendToInventory" );




--[[
INTERNAL METHODS
DO NOT OVERRIDE IN THIS SCRIPT OR OTHER SCRIPTS
These functions are called internally by Itemforge. There should be no reason for a scripter to call these.
]]--




--[[
* SHARED
* Protected

This is called when the item is created. This is NOT called when the item is placed into the world.
This function will call the item's OnInit event.

plOwner is the player this item was originally created for (e.g. if it spawns in a player's inventory, plOwner is the player).

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:Initialize( plOwner )
	self:Event( "OnInit", nil, plOwner );
	
	return true;
end
IF.Items:ProtectKey( "Initialize" );

--[[
* SHARED
* Protected

Sets the item's entity. Whenever an item is in the world, a SENT is created.
We need to link this SENT with the item, so the item can refer to it later.
ent must be a valid "itemforge_item" entity, or this function will fail. If for some reason a different SENT needs to be used, I'll consider allowing different SENTS to be used.

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:SetEntity( eEntity )
	if !IF.Items:IsEntItem( eEntity ) then return self:Error( "Couldn't set entity! Given entity was not a valid Itemforge Item class!\n" ) end
	
	self.Entity = eEntity;
	return true;
end
IF.Items:ProtectKey( "SetEntity" );

--[[
* SHARED
* Protected

Clears the item's entity.

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:ClearEntity()
	self.Entity = nil;
end
IF.Items:ProtectKey( "ClearEntity" );

--[[
* SHARED
* Protected

Sets this item's weapon. Whenever an item is held, an SWEP is created.
We need to link this SWEP with the item, so the item can refer to it later.
ent must be a valid itemforge_item_held_* entity, or this function will fail. If for some reason a different SWEP needs to be used, I'll consider allowing different SWEPs to be used.

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:SetWeapon( eEntity )
	if !IF.Items:IsWeaponItem( eEntity )	then return self:Error( "Couldn't set weapon! Given entity was not a valid Itemforge weapon class!\n" ) end
	
	self.Weapon = eEntity;
	return true;
end
IF.Items:ProtectKey( "SetWeapon" );

--[[
* SHARED
* Protected

Sets this item's owner. Whenever an item is held, an SWEP is created.
We need to record what player is holding this SWEP so the item can refer to him later.
pl must be a valid player or this function will fail.

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:SetWOwner( pl )
	if !pl || !pl:IsValid()	then return self:Error( "Couldn't set weapon owner! Given player was not valid!\n" ) end
	if !pl:IsPlayer()		then return self:Error( "Couldn't set weapon owner! Given player was not a player!\n" ) end

	self.Owner = pl;
	return true;
end
IF.Items:ProtectKey( "SetWOwner" );

--[[
* SHARED
* Protected

Clears this item's weapon and weapon owner.

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:ClearWeapon()
	self.Weapon = nil;
	self.Owner = nil;
	return true;
end
IF.Items:ProtectKey( "ClearWeapon" );

--[[
* SHARED
* Protected

Sets the item's container (inventory that this item is inside of).

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:SetContainer( inv )
	self.Container = inv;
	return true;
end
IF.Items:ProtectKey( "SetContainer" );

--[[
* SHARED
* Protected

Clears this item's container (inventory that this item is inside of).

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:ClearContainer()
	self.Container = nil;
	return true;
end
IF.Items:ProtectKey( "ClearContainer" );

--[[
* SHARED
* Protected

Adds an inventory to this item's list of connected inventories.
Connect an inventory with inv:ConnectItem(item), not this function
true is returned if successful, false otherwise

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:ConnectInventory( inv, iConSlot )
	if !inv || !inv:IsValid()	then return self:Error( "Couldn't connect item to given inventory. The inventory given was invalid.\n" ) end
	if !iConSlot				then return self:Error( "Couldn't connect item to given inventory. iConSlot wasn't given.\n" ) end
	
	--Create inventories collection if we haven't yet
	if !self.Inventories then self.Inventories = {} end
	
	local newRecord = {};
	newRecord.Inv = inv;
	newRecord.ConnectionSlot = iConSlot;
	
	self.Inventories[ inv:GetID() ] = newRecord;
	
	--We have events that detect connections of inventories both serverside and clientside
	self:Event( "OnConnectInventory", nil, inv, iConSlot );
		
	return true;
end
IF.Items:ProtectKey( "ConnectInventory" );

--[[
* SHARED
* Protected

Removes a connected inventory from this item's list of connected inventories.
Sever an inventory with inv:SeverItem(item), not this function

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:SeverInventory( inv )
	if !inv || !inv:IsValid() then return self:Error( "Couldn't sever item from given inventory. The inventory given was invalid.\n" ) end

	local invid = inv:GetID();
	if !self.Inventories || !self.Inventories[invid] then return self:Error( "Couldn't sever item from "..tostring(inv)..". The inventory is not listed as connected on the item.\n" ) end
	self.Inventories[invid] = nil;
	
	--We have events that detect severing of inventories both serverside and clientside
	self:Event( "OnSeverInventory", nil, inv );
	
	return true;
end
IF.Items:ProtectKey( "SeverInventory" );

--[[
* SHARED
* Protected

If the given inventory is connected to this item, returns the index of the connection on this item.
]]--
function ITEM:GetInventoryConnectionSlot( invid )
	if !invid											then return self:Error( "Couldn't grab connection slot that this item is occupying on an inventory. The inventory ID wasn't given.\n" ) end
	if !self.Inventories || !self.Inventories[invid]	then return self:Error( "Couldn't grab connection slot that this item is occupying on an inventory. This inventory isn't connected to this item.\n" ) end
	return self.Inventories[invid].ConnectionSlot;
end
IF.Items:ProtectKey( "GetInventoryConnectionSlot" );

--[[
* SHARED
* Protected

Returns an ID corresponding to the given holdtype string.
If no ID for the given string exists, returns the ID for "normal".
 
strHoldType should be the holdtype string you want to convert.
	See ITEM.SWEPHoldType at the top of the file for a list of valid values.
]]--
function ITEM:HoldTypeToID( strHoldType )
	return HoldTypeToIDHashTable[strHoldType] or HoldTypeToIDHashTable["normal"];
end
IF.Items:ProtectKey( "HoldTypeToID" );

--[[
* SHARED
* Protected

Returns a string corresponding to the given holdtype ID.
If no string for the given id exists, returns "normal".
 
iHoldType should be the holdtype ID you want to convert.
]]--
function ITEM:HoldTypeToString( iHoldTypeID )
	return HoldTypeToStringHashTable[iHoldTypeID] or "normal";
end
IF.Items:ProtectKey( "HoldTypeToString" );