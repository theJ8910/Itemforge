--[[
item
SERVER

item is the default item. All items except item inherit from this item-type.
NOTE: The item type is the name of the folder it is in (this is item/init.lua, so this item's type is "item")
]]--
AddCSLuaFile("shared.lua");
AddCSLuaFile("cl_init.lua");
AddCSLuaFile("health.lua");
AddCSLuaFile("stacks.lua");
AddCSLuaFile("weight.lua");
AddCSLuaFile("nwvars.lua");
AddCSLuaFile("timers.lua");
AddCSLuaFile("sounds.lua");
AddCSLuaFile("events_shared.lua");
AddCSLuaFile("events_client.lua");

include("shared.lua");
include("events_server.lua");

ITEM.ThinkRate=0;									--Run think serverside every # of seconds set here. If this is 0 it runs every frame serverside.

--SWEP related
ITEM.HoldType="pistol";								--How does a player hold this item when he is holding it as a weapon? Valid values: "pistol","smg","grenade","ar2","shotgun","rpg","physgun","crossbow","melee","slam","normal"

--Don't modify/override these. They're either set automatically or don't need to be changed.

--[[
This doesn't actually set the NetOwner, but it will publicize or privitize the item.
lastOwner should be the player who was NetOwner of this item previously. This can be a player, or nil. Doing item:GetNetOwner() or getting the NetOwner of the old container should suffice in most cases.
newOwner should be the player who now owns this item. This can be a player, or nil. The NetOwner of an inventory the item is going in, or nil should work in most cases.
]]--
function ITEM:SetOwner(lastOwner,newOwner)
	if newOwner!=nil then
		if lastOwner==nil then
			IF.Items:RemoveClientsideOnAllBut(self:GetID(),newOwner);
		
		elseif lastOwner!=newOwner then
			IF.Items:RemoveClientside(self:GetID(),lastOwner);
			IF.Items:SendFullUpdate(self:GetID(),newOwner);
			
			for _,i in pairs(self.Inventories) do
				if i.Inv:CanSendInventoryData(newOwner) then i.Inv:ConnectItem(self,newOwner); end
			end
		end
	
	elseif lastOwner!=nil then
		for k,v in pairs(player.GetAll()) do
			if v!=lastOwner then
				IF.Items:SendFullUpdate(self:GetID(),v);
				for _,i in pairs(self.Inventories) do
					if i.Inv:CanSendInventoryData(v) then i.Inv:ConnectItem(self,v); end
				end
			end
		end
	end
end

--[[
This function puts an item inside of an inventory.
inv is the inventory to add the item to.
reqSlot is an optional number that requests a certain slot to insert the item into. This can be a number (to request the item be placed in a certain slot in the given inventory), or can be nil/not given.
If pl is given, only that player will be told to add the item to the given inventory clientside.
bNoMerge is an optional true/false. If bNoMerge is:
	true, the item will not attempt to merge itself with existing items of the same type in the given inventory, even if it normally would.
	false or not given, then this function calls the CanInventoryMerge of both this item and the item it's trying to merge with.
		If both items approve, the two are merged and this item removed as part of the merge.
		If for some reason a merge can't be done, false is returned.
This function calls this item's OnMove event if it's moving to a new inventory. OnMove can stop the move.

If the item cannot be inserted for any reason, then false is returned. True is returned otherwise.
NOTE: If this item merges with an existing item in the inventory, false is returned, and this item is removed.
TODO: This function needs to be reworked to reduce it's complexity
]]--
function ITEM:ToInventory(inv,reqSlot,pl,bNoMerge)
	if self.BeingRemoved then return false end
	if !inv || !inv:IsValid() then ErrorNoHalt("Itemforge Items: Could not insert "..tostring(self).." into an inventory - given inventory was invalid!\n"); return false end
	
	--Validate player if given
	if pl!=nil then
		if !pl:IsValid() then ErrorNoHalt("Itemforge Items: Couldn't insert "..tostring(self).." into inventory "..inv:GetID()..". Player given is not valid!\n"); return false;
		elseif !pl:IsPlayer() then ErrorNoHalt("Itemforge Items: Couldn't insert "..tostring(self).." into inventory "..inv:GetID()..". The player given is not a player.\n"); return false;
		elseif !inv:CanSendInventoryData(pl) then ErrorNoHalt("Itemforge Items: Couldn't insert "..tostring(self).." into inventory "..inv:GetID()..". The inventory given is private, and the player given is not the owner of the inventory.\n"); return false;
		end
	end
	local oldinv,oldslot=self:GetContainer();
	
	--If we're just moving an item from one slot to another, make sure that a requested slot was given
	if oldinv==inv && !reqSlot then ErrorNoHalt("Itemforge Items: Couldn't insert "..tostring(self).." into inventory "..inv:GetID()..". The item is already in this inventory. No slot was given, so the item can't be moved to a different slot, either.\n"); return false; end
	
	--Here we determine if we're moving/inserting an item somewhere, or just sending an update.
	--If we're moving/inserting the item, we call the item's OnMove event and give it a chance to stop whatever is happening.
	local bSendingUpdate=false;
	if oldinv!=inv || oldslot!=reqSlot then
		local s,r=pcall(self.OnMove,self,oldinv,oldslot,inv,reqSlot,false);
		if !s then ErrorNoHalt(r.."\n")
		elseif !r then return false
		end
	else
		bSendingUpdate=true;
	end
	
	--If we want to move the item from one slot to another instead of inserting it somewhere:
	if oldinv==inv && oldslot!=reqSlot then
		if !inv:MoveItem(self,oldslot,reqSlot) then return false end
		
		--Ask client to transfer slots too
		self:SendNWCommand("TransferSlot",nil,inv,oldslot,reqSlot);
		return true;
	end
	
	local newOwner=inv:GetOwner();
	local lastOwner=self:GetOwner();
	
	--If an inventory merge is allowed (and we're not just sending an update to a player), we can try to merge this item with an existing item of the same type
	if !bNoMerge && !bSendingUpdate then
		local extStack=inv:GetItemByType(self:GetType());
		if extStack && extStack!=self then
			local s,r1=pcall(self.CanInventoryMerge,self,extStack,inv);
			if !s then ErrorNoHalt(r1.."\n"); r1=false; end
			
			local s,r2=pcall(extStack.CanInventoryMerge,extStack,self,inv);
			if !s then ErrorNoHalt(r2.."\n"); r2=false; end
			
			if r1 && r2 && extStack:Merge(true,self) then
				--We return false because we're not inserting the item, we're merging it with an item already inserted, and removing this item
				return false;
			end
		end
	end
	
	--[[
	Get the slot ID of the newly inserted item so we can tell the client what slot it's going in
	If the item is already in the inventory it just returns the slot number it's already in
	This function will cause the item to be sent to the void right before the item is added to the inventory (so if it was elsewhere before being inserted, that's taken care of)
	]]--
	local slotid=inv:InsertItem(self,reqSlot);
	
	--[[
	The inventory can stop the item from being inserted serverside
	If this is false the requested slot was occupied, the inventory stopped the item from being inserted, the item couldn't be sent to the void, or some other error has occured
	If we try to insert an item into an inventory that it's already inside of, but in a different slot, it will fail as well (we need to use )
	]]--
	if slotid==false || (reqSlot!=nil && slotid!=reqSlot) then return false end
	
	--Record the inventory we've been inserted into
	self:SetContainer(inv);
	
	
	
	--This was a real headache to do but I think I maxed out the efficency
	if bSendingUpdate then
		self:SendNWCommand("ToInventory",pl,inv,slotid);
	else
		--Publicize or privitize the item
		self:SetOwner(lastOwner,newOwner);
	
		--Is the item going public?
		if newOwner==nil then
			
			--From a public...
			if lastOwner==nil then
				--container?
				if oldinv then
					self:SendNWCommand("TransferInventory",nil,oldinv,inv,slotid);
				
				--...setting (void, world, held)?
				else
					self:SendNWCommand("ToInventory",nil,inv,slotid);
				end
			
			--...from a private inventory? 
			elseif lastOwner!=nil then
				--Insert it into the given inventory clientside on everybody but the last owner.
				for k,v in pairs(player.GetAll()) do if v!=lastOwner then self:SendNWCommand("ToInventory",v,inv,slotid); end end
				
				--On the last owner, transfer to the new inventory.
				self:SendNWCommand("TransferInventory",lastOwner,oldinv,inv,slotid);
			end
			
		--or private?
		else
			--...from a public...
			if lastOwner==nil then
				--container?
				if oldinv then
					--Transfer from the old inventory to the new inventory on the new owner.
					self:SendNWCommand("TransferInventory",newOwner,oldinv,inv,slotid);
					
				--setting?
				else
					--Insert it on the new owner.
					self:SendNWCommand("ToInventory",newOwner,inv,slotid);
				end
				
				
			--...from a private inventory owned by the same guy?
			elseif lastOwner==newOwner then
			
				--Transfer from the old inventory to the new inventory.
				self:SendNWCommand("TransferInventory",newOwner,oldinv,inv,slotid);
				
			--...from a private inventory not owned by the same guy?
			else
				--Insert it on the new owner.
				self:SendNWCommand("ToInventory",newOwner,inv,slotid);
			end
		end
	end
	
	return true;
end
IF.Items:ProtectKey("ToInventory");

--A shorter alias
ITEM.ToInv=ITEM.ToInventory;
IF.Items:ProtectKey("ToInv");

--[[
This function places the item in the world (as an entity).
vPos is a Vector() describing the position in the world the entity should be created at.
aAng is an optional Angle() describing the angles it should be created at.
If the item is already in the world, the item will be moved to the given position and angles.
If for some reason you want to actually want to re-send it to the world with a new entity instead of just teleporting it, send it to the void first with :ToVoid() and then send it to the world at the new location.
This function calls the OnWorldEntry event, which has a chance to stop the move, right before moving the item to the world.
If the item is moved to the world successfully, this function calls the OnEntityInit event, which is used to set up the entity after it's been created.
False is returned if the item cannot be moved to the world for any reason. Otherwise, the entity created is returned.
]]--
function ITEM:ToWorld(vPos,aAng)
	if self.BeingRemoved then return false end
	if vPos==nil then ErrorNoHalt("Itemforge Items: Could not create an entity for "..tostring(self)..", position to create item at was not given.\n"); return false end
	local aAng=aAng or Angle(0,0,0);
	
	--Give events a chance to stop the insertion
	local s,r=pcall(self.OnWorldEntry,self,vPos,aAng);
	if !s then		ErrorNoHalt(r.."\n")
	elseif !r then	return false
	end
	
	--Just teleport this item's ent if it's already in the world
	if self:InWorld() then
		local ent=self:GetEntity();
		
		ent:SetPos(vPos);
		ent:SetAngles(aAng);
		local phys=ent:GetPhysicsObject();
		if phys && phys:IsValid() then
			phys:Wake();
		end
		
		return ent;
	end
	
	local ent=ents.Create("itemforge_item");
	if !ent || !ent:IsValid() then ErrorNoHalt("Itemforge Items: Tried to create itemforge_item entity for "..tostring(self).." but failed.\n"); return false end
	
	--[[
	Send to void. False is returned in case of errors or if events stop the removal of the item from it's current medium.
	We try to send an item to the void when all other possible errors have been ruled out.
	If we didn't... this could happen: We put the item in the void, then try to create the SENT but can't. So our item is stuck in the void. We try to avoid this.
	]]--
	if !self:ToVoid() then
		ent:Remove();
		return false;
	end
	
	ent:SetPos(vPos);
	ent:SetAngles(aAng);
	
	--Set item will set both the entity's item and the item's entity (it will make two one-way connections)
	--This function triggers the item's OnEntityInit event.
	ent:SetItem(self);
	
	return ent;
end
IF.Items:ProtectKey("ToWorld");

--[[
This function moves the item to a weapon, held by the given player. 
pl should be a player entity.
bNoMerge is an optional argument.
	If the player given is already holding an item of this type (ex: player is holding a handful of pebbles, and is trying to pick up more pebbles):
		If bNoMerge is false or not given, then this function calls the CanHoldMerge event of both this item and the item it's trying to merge with. If both items approve, the two are merged. This stack is removed as part of the merge, and false is returned. If for some reason a merge can't be done, false is returned.
		If bNoMerge is true, then no attempt to merge the two items into one stack will be made, even if it normally would. False will be returned.
This function calls the OnHold event, which has a chance to stop the item from being held.
If the item is successfully held, the item's OnSWEPInit event is called.

False is returned if the item can't be held for any reason. Otherwise, the newly created weapon entity is returned.
]]--
function ITEM:Hold(pl,bNoMerge)
	if self.BeingRemoved then return false end
	
	local bNoMerge=bNoMerge or false;
	
	if !pl || !pl:IsValid() then ErrorNoHalt("Itemforge Items: Couldn't hold "..tostring(self).." as weapon. Player given is not valid!\n"); return false
	elseif !pl:IsPlayer() then ErrorNoHalt("Itemforge Items: Couldn't hold "..tostring(self).." as weapon. The player given is not a player.\n"); return false
	elseif !pl:Alive() then return false end
	
	--We can allow the events a chance to stop the item from being held
	local s,r=pcall(self.OnHold,self,pl);
	if !s then ErrorNoHalt(r.."\n")
	elseif !r then return false
	end
	
	--Here we determine two things: Do we have an empty slot, and can we merge already holding an item of this type?
	local iEmptySlot=0;
	for i=1,IF.Items.MaxHeldItems do
		local currentlyHeld=pl:GetWeapon("itemforge_item_held_"..i);
		if !currentlyHeld || !currentlyHeld:IsValid() then
			iEmptySlot=i;
		elseif !bNoMerge then
			local heldItem=currentlyHeld:GetItem();
			
			if heldItem && self:GetType()==heldItem:GetType() then
				local s,r1=pcall(self.CanHoldMerge,self,heldItem,pl);
				if !s then ErrorNoHalt(r1.."\n"); r1=false end
				
				local s,r2=pcall(heldItem.CanHoldMerge,heldItem,self,pl);
				if !s then ErrorNoHalt(r2.."\n"); r2=false end
				
				if r1 && r2 && heldItem:Merge(true,self) then return false end
			end
		end
	end
	
	--Can't hold an item if the player is holding the max number of items already
	if iEmptySlot==0 then
		--ErrorNoHalt("Itemforge Items: Could not hold "..tostring(self).." as weapon. Player "..pl:Name().." is already holding an item. Release that item first.\n");
		return false;
	end
	
	
	--local ent=ents.Create("itemforge_item_held_"..iEmptySlot);
	
	--[[
	Send to void. False is returned in case of errors or if events stop the removal of the item from it's current medium.
	We try to send an item to the void when all other possible errors have been ruled out.
	If we didn't... this could happen: We put the item in the void, then try to put it in the world but can't create the ent. So our item is stuck in the void. We try to avoid this.
	]]--
	if !self:ToVoid() then
		return false;
	end
	
	local ent=pl:Give("itemforge_item_held_"..iEmptySlot);
	if !ent || !ent:IsValid() then ErrorNoHalt("Itemforge Items: Tried to create itemforge_item_held entity for "..tostring(self).." but failed.\n"); return false end
	
	--TODO sometimes the weapon isn't picked up, such as when noclipping, need to fix this. Temporary solution below.
	--ent:SetPos(pl:GetPos()+Vector(0,0,64));
	
	--Set item will set both the SWEP's item and the item's entity (it will make two one-way connections)
	--This function triggers the item's OnSWEPInit hook.
	ent:SetItem(self);
	
	return ent;
end
IF.Items:ProtectKey("Hold");

--[[
Moves this item to the same location as another item
extItem should be an existing item. If extItem is:
	In the world, this item is moved to the world at the exact same position and angles. Additionally, this item will be travelling at the same velocity as extItem when it is created.
	In an inventory, this item is moved to the inventory that extItem is in.
	Held by a player, this item is moved to the world, at the shoot location of the player holding it.
	In the void, this item is moved to the void.

Scatter is an optional true/false.
	If scatter is true and extItem is in the world,
	the angles the items are placed in the world at will be random,
	and the position will be chosen randomly from inside of extItem's bounding box,
	rather than spawning at the entity's center.

bNoMerge is an optional true/false. If extItem is in an inventory, then the auto-merge will be disabled.

true is returned if the item was successfully moved to the same location as extItem. false is returned if the item could not be moved for any reason.
TODO sometimes the items fall through the world, could probably fix by taking the bounding box size of this item into consideration when picking a scatter location
]]--
function ITEM:ToSameLocationAs(extItem,scatter,bNoMerge)
	if !extItem or !extItem:IsValid() then ErrorNoHalt("Itemforge Items: Tried to move "..tostring(self).." to same location as another item, but the other item wasn't given!\n"); return nil end
	
	scatter=scatter or false;
	bNoMerge=bNoMerge or false;
	
	local container=extItem:GetContainer();
	if container then
		--Sometimes we'll inventory merge, which returns false in :ToInventory but also removes this item TODO make it return true instead
		if !self:ToInventory(container,nil,nil,bNoMerge) && self:IsValid() then
			--If we can't move the item to the container that extItem was in, we'll try moving it to the same place as that container's connected item.
			local t=container:GetConnectedItems();
			local c=table.getn(t);
			
			--If this inventory isn't connected to anything we fail
			if c==0 then return false end
			
			--If it is though, we'll pick one of the connections randomly and send the item to that location
			return self:ToSameLocationAs(t[math.random(1,c)]);
		end
		
		return true;
	elseif extItem:InWorld() then
		local ent=extItem:GetEntity();
		local newEnt=0;
		if scatter then
			local min=ent:OBBMins();
			local max=ent:OBBMaxs();
			local where=ent:LocalToWorld(Vector(math.random(min.x,max.x),math.random(min.y,max.y),math.random(min.z,max.z)));
			local whereAng=Angle(math.random(0,360),math.random(0,360),math.random(0,360));
			
			newEnt=self:ToWorld(where,whereAng);
			if !newEnt then return false end
		else
			newEnt=self:ToWorld(ent:GetPos(),ent:GetAngles());
			if !newEnt then return false end
		end
		
		local newEntPhys=newEnt:GetPhysicsObject();
		if newEntPhys && newEntPhys:IsValid() then newEntPhys:SetVelocity(ent:GetVelocity()); end
		
		return true;
	elseif extItem:IsHeld() then
		local pl=extItem:GetWOwner();
		if !pl then ErrorNoHalt("Itemforge Items: ERROR! Trying to move "..tostring(self).." failed. The item given, "..tostring(extItem).." is being held, but player holding it could not be determined.\n"); return nil end
		
		if !self:ToWorld(pl:GetShootPos(),pl:GetAimVector()) then return false end
		
		return true;
	end
	
	if !self:ToVoid() then return false end
	return true;
end

--[[
ToVoid releases a held item, removes the item from the world, or takes an item out of an inventory. Or in other words, it places the item in the void.
It isn't necessary to send an item to the void after it's created - the item is already in the void.

forced is an optional argument that should be true if you want the removal to ignore events that say not to release/remove/etc. This should only be true if the item has to come out, like if the item is being removed.
bNotFromClient is an optional true/false that only applies if the item is being removed from an inventory. If bNotFromClient is:
	true, the item will not be instructed to remove itself clientside. When utilized properly this can be used to save bandwidth with networking macros.
	false, or not given, it will automatically be removed clientside.
vDoubleCheck is an optional variable.
	You can give this if you want to make sure that the item is being removed from the right inventory, entity, or weapon.
	This can be nil, an inventory, or an itemforge SENT/SWEP. There's really no reason for a scripter to have to use this; Itemforge uses this internally.

true is returned if the item was placed in the void, or is in the void already.
false is returned if the item couldn't be placed in the void.
]]--
function ITEM:ToVoid(forced,bNotFromClient,vDoubleCheck)
	local forced=forced or false;
	local bNotFromClient=bNotFromClient or false;
	
	--Is the item in the world?
	if self:InWorld() then
		local ent=self:GetEntity();
		
		if vDoubleCheck && ent!=vDoubleCheck then ErrorNoHalt("Itemforge Items: WARNING! Tried to take "..tostring(self).." out of the world, but the entity being removed ("..tostring(vDoubleCheck)..") didn't match the current world entity ("..tostring(ent).."). Old world entity?\n"); return false end
		
		--Give events a chance to stop the removal (or at least let them run if it's forced)
		if !self:OnWorldExitSafe(ent,forced) && !forced then return false end
		
		self:ClearEntity();
		ent:ExpectedRemoval();
	
	--Maybe it's being held.
	elseif self:IsHeld() then
		local ent=self:GetWeapon();
		
		if vDoubleCheck && ent!=vDoubleCheck then ErrorNoHalt("Itemforge Items: WARNING! Tried to stop holding "..tostring(self)..", but the SWEP being removed ("..tostring(vDoubleCheck)..") didn't match the current SWEP ("..tostring(ent).."). Old SWEP?\n"); return false end
		
		--Give events a chance to stop the removal (or at least let them run if it's forced)
		local s,r=pcall(self.OnRelease,self,self:GetWOwner(),forced);
		if !s then					ErrorNoHalt(r.."\n")
		elseif !r && !forced then	return false
		end
		
		self:ClearWeapon(vDoubleCheck);
		ent:ExpectedRemoval();
	
	--So we're not in the world or held; How about a container?
	elseif self:InInventory() then
		local container,cslot=self:GetContainer();
		
		if vDoubleCheck && container!=vDoubleCheck then ErrorNoHalt("Itemforge Items: WARNING! Tried to take "..tostring(self).." out of an inventory, but the given inventory ("..tostring(vDoubleCheck)..") wasn't the inventory this item was in ("..tostring(container).."). Netsync problems?\n"); return false end
		
		--If removal isn't forced our events can stop the removal
		local s,r=pcall(self.OnMove,self,container,cslot,nil,nil,forced);
		if !s then					ErrorNoHalt(r.."\n")
		elseif !r && !forced then	return false
		end
		
		if !container:RemoveItem(self:GetID(),forced) && !forced then return false end
		self:ClearContainer();
		
		--Tell clients to remove this item from the inventory (unless specifically told not to)
		if !bNotFromClient then
			local oldOwner=container:GetOwner();
			
			self:SetOwner(oldOwner,nil);
			
			--And then take it out
			self:SendNWCommand("RemoveFromInventory",oldOwner,forced,container);
		end
	end
	
	return true;
end
IF.Items:ProtectKey("ToVoid");

--[[
Protected OnWorldExit event.
Stops all looping sounds and then runs the overridable OnWorldExit event and returns the result.
]]--
function ITEM:OnWorldExitSafe(ent,forced)
	self:StopAllLoopingSounds();
	
	--Give events a chance to stop the removal (or at least let them run if it's forced)
	local s,r=pcall(self.OnWorldExit,self,ent,forced);
	if !s then					ErrorNoHalt(r.."\n")
	elseif !r then				return false;
	end
	return true;
end
IF.Items:ProtectKey("OnWorldExitSafe");

--[[
This function returns true if this item can send information about itself to a given player.
It will return true in two case:
	This item's NetOwner is nil (this item is public)
	This item's NetOwner is the same as the given player (this is a private item "owned" by this player)
]]--
function ITEM:CanSendItemData(pl)
	local owner=self:GetOwner();
	if owner==nil or owner==pl then return true end
	return false;
end
IF.Items:ProtectKey("CanSendItemData");

--[[
Run this function to use the item.
It will trigger the OnUse event in the item.
This function will only be run serverside if the item is used while on the ground (with the "e" key).
The function will be run clientside and then serverside in most other cases. The server should have the final say on if something can be used or not though.
False is returned if the item is unable to be used for any reason.

TODO: Possibly have the item used by something other than a player
]]--
function ITEM:Use(pl)
	if !pl || !pl:IsValid() || !pl:IsPlayer() || !self:CanPlayerInteract(pl) then return false end
	
	local s,r=pcall(self.OnUse,self,pl);
	if !s then ErrorNoHalt(r.."\n")
	elseif !r then
		pl:PrintMessage(HUD_PRINTTALK,"I can't use this!");
		IF.Vox:PlayRandomFailure(pl);
		return false;
	end
	
	return true;
end
IF.Items:ProtectKey("Use");

--[[
Protected start touch event.
World Merge attempts are triggered here.
After an _unsuccessful_ world merge attempt, this calls the overridable OnStartTouch event.
]]--
function ITEM:OnStartTouchSafe(entity,activator,touchItem)
	--If this item touched an item of the same type...
	if touchItem && self:GetType()==touchItem:GetType() then
		--And both items' events...
		local s,r1=pcall(self.CanWorldMerge,self,touchItem);
		if !s then ErrorNoHalt(r1.."\n"); r1=false end
		
		--...approve a world merge
		local s,r2=pcall(touchItem.CanWorldMerge,touchItem,self);
		if !s then ErrorNoHalt(r2.."\n"); r2=false end
		
		--Then we'll merge the two items here. If it works, we stop here. Otherwise, we call the OnStartTouch event.
		if r1 && r2 && self:Merge(true,touchItem) then
			return;
		end
	end
	
	--If a merger isn't possible we pass the touch onto the item's OnStartTouch and let it handle it.
	local s,r=pcall(self.OnStartTouch,self,entity,activator,touchItem);
	if !s then ErrorNoHalt(r.."\n") end;
end
IF.Items:ProtectKey("OnStartTouchSafe");

--[[
Changes the item's world model.
]]--
function ITEM:SetWorldModel(sModel)
	if !sModel then ErrorNoHalt("Itemforge Items: Couldn't change world model. No model was given.\n"); return false end
	self:SetNWString("WorldModel",sModel);
	
	if self:InWorld() then
		local ent=self:GetEntity();
		
		--If this item's ent has a model it needs to change
		ent:SetModel(sModel);
		
		--If this item's ent has a physics model it needs to be updated
		if (ent:GetPhysicsObject():IsValid()) then
			ent:PhysicsInit(SOLID_VPHYSICS);
		end
	end
end

--[[
Changes this item's view model.
TODO actually change visible viewmodel.
]]--
function ITEM:SetViewModel(sModel)
	if !sModel then ErrorNoHalt("Itemforge Items: Couldn't change view model. No model was given.\n"); return false end
	self:SetNWString("ViewModel",sModel);
end
IF.Items:ProtectKey("SetViewModel");

--Sends all of the necessary item data to a player. Triggers "OnSendFullUpdate" event.
function ITEM:SendFullUpdate(pl)
	
	--Send networked vars. We'll only send networked vars that have changed (NWVars that have been set to something other than the default value)
	if self.NWVars then
		for k,v in pairs(self.NWVars) do
			--This shouldn't happen, but just in case.
			if !self.NWVarsByName[k] then ErrorNoHalt("Itemforge Items: Couldn't send networked var \""..k.."\" via full update on "..tostring(self)..". This networked var has not been defined in the itemtype with IF.Items:CreateNWVar. This shouldn't be happening.\n"); end
			
			if !self.NWVarsByName[k].HoldFromUpdate then self:SendNWVar(k,pl); end
		end
	end
	
	local container,cslot=self:GetContainer();
	if container then self:ToInventory(container,cslot,pl,true); end
	
	local s,r=pcall(self.OnSendFullUpdate,self,pl);
	if !s then ErrorNoHalt(r.."\n") end
end
IF.Items:ProtectKey("SendFullUpdate");

--[[
Runs every time the server ticks.
]]--
function ITEM:Tick()
	if !self.NWVars then return false end
	
	--Send predicted network vars.
	for k,v in pairs(self.NWVars) do
		--This shouldn't happen, but just in case.
		if !self.NWVarsByName[k] then ErrorNoHalt("Itemforge Items: Couldn't send networked var \""..k.."\" via tick on "..tostring(self)..". This networked var has not been defined in the itemtype with IF.Items:CreateNWVar. This shouldn't be happening.\n"); return false end
		
		if self.NWVarsByName[k].Predicted then
			--Create the "Last Tick" table if it hasn't been created yet
			if !self.NWVarsLastTick then self.NWVarsLastTick={}; end
			
			--Only send networked vars that have changed since the last tick
			if self.NWVars[k]!=self.NWVarsLastTick[k] then
				self.NWVarsLastTick[k]=self.NWVars[k];
				self:SendNWVar(k);
			end
		end
	end
end
IF.Items:ProtectKey("Tick");

--[[
Triggers a Wire output on this item. This will not work if Wiremod is not installed.
Whenever a wire output is triggered, it will send the given value to anything that happened to be wired to that output.

outputName is the name of the output to trigger (ex: "Energy", "DetectedPlayer", etc)
value is what value you want to output.
	Most wire inputs take numbers, so I recommend using a number for value.
	An on/off type output usually uses 0 for off and 1 for on.
	Value can be any kind of data you want - bools, tables, numbers, vectors, angles, whatever. Just keep in mind that it has to be understood by the other side.

Returns false if Wiremod v843 or better is not installed or if the item is not in the world. Returns true if the Wire output was triggered successfully.
WIRE
]]--
function ITEM:WireOutput(outputName,value)
	--This only works if Wire is present
	if !WireVersion||WireVersion<843 then return false end
	
	--This only works if we are in the world
	local entity=self:GetEntity();
	if !entity then return false end
	
	Wire_TriggerOutput(entity,outputName,value)
	return true;
end
IF.Items:ProtectKey("WireOutput");

--[[
Sends a networked command by name with the supplied arguments
Serverside, this sends usermessages.
pl can be a player, a recipient filter, or 'nil' to send to all players (clients). If nil is given for player, and the item is in a private inventory, then the command is sent to that player only. 
]]--
function ITEM:SendNWCommand(sName,pl,...)
	local command=self.NWCommandsByName[sName];
	if command==nil then ErrorNoHalt("Itemforge Items: Couldn't send command '"..sName.."' on "..tostring(self)..", there is no NWCommand by this name! \n"); return false end
	if command.Hook!=nil then ErrorNoHalt("Itemforge Items: Command '"..command.Name.."' on "..tostring(self).." can't be sent serverside. It has a hook, meaning this command is recieved serverside, not sent.\n"); return false end
	
	if pl!=nil then
		if !pl:IsValid() then ErrorNoHalt("Itemforge Items: Couldn't send networked command - The player to send "..tostring(self).." to isn't valid!\n"); return false; end
		if !pl:IsPlayer() then ErrorNoHalt("Itemforge Items: Couldn't send networked command - The player to send "..tostring(self).." to isn't a player!\n"); return false; end
	else
		local allSuccess=true;
		for k,v in pairs(player.GetAll()) do
			if !self:SendNWCommand(sName,v,unpack(arg)) then allSuccess=false end
		end
		return allSuccess;
	end
	
	IF.Items:IFIStart(pl or self:GetOwner(),IFI_MSG_SV2CLCOMMAND,self:GetID());
	IF.Items:IFIChar(self.NWCommandsByName[sName].ID-128);
	
	--If our command sends data, then we need to send the appropriate type of data.
	for i=1,table.maxn(command.Datatypes) do
		local v=command.Datatypes[i];
		
		if v==1 then
			IF.Items:IFILong(math.floor(arg[i] or 0));
		elseif v==2 then
			IF.Items:IFIChar(math.floor(arg[i] or 0));
		elseif v==3 then
			IF.Items:IFIShort(math.floor(arg[i] or 0));
		elseif v==4 then
			IF.Items:IFIFloat(arg[i] or 0);
		elseif v==5 then
			IF.Items:IFIBool(arg[i] or false);
		elseif v==6 then
			IF.Items:IFIString(arg[i] or "");
		elseif v==7 then
			IF.Items:IFIEntity(arg[i]);
		elseif v==8 then
			IF.Items:IFIVector(arg[i] or Vector(0,0,0));
		elseif v==9 then
			IF.Items:IFIAngle(arg[i] or Angle(0,0,0));
		elseif v==10||v==11 then
			if arg[i]!=nil && arg[i]:IsValid() then
				IF.Items:IFIShort(arg[i]:GetID()-32768);
			else
				IF.Items:IFIShort(0);
			end
		elseif v==12 then
			if arg[i]!=nil then
				IF.Items:IFIChar(math.floor(arg[i])-128);
			else
				IF.Items:IFIChar(0);
			end
		elseif v==13 then
			if arg[i]!=nil then
				IF.Items:IFILong(math.floor(arg[i])-2147483648);
			else
				IF.Items:IFILong(0);
			end
		elseif v==14 then
			if arg[i]!=nil then
				IF.Items:IFIShort(math.floor(arg[i])-32768);
			else
				IF.Items:IFIShort(0);
			end
		elseif v==0 then
			IF.Items:IFIChar(0);
		end
	end
	
	IF.Items:IFIEnd();
end
IF.Items:ProtectKey("SendNWCommand");

--[[
This function is called automatically, whenever a networked command from a client is received. fromPl will always be a player.
commandid is the ID of the command recieved from the server
args will be a table of arguments (should be converted to the correct datatype as specified in CreateNWCommand).
There's no need to override this, we'll call the hook the command is associated if there is one.
]]--
function ITEM:ReceiveNWCommand(fromPl,commandid,args)
	local command=self.NWCommandsByID[commandid];
	
	if command==nil then ErrorNoHalt("Itemforge Items: Couldn't find a NWCommand with ID '"..commandid.."' on "..tostring(self)..". Make sure commands are created in the same order BOTH serverside and clientside. \n"); return false end
	if command.Hook==nil then ErrorNoHalt("Itemforge Items: Command '"..command.Name.."' was received on "..tostring(self)..", but there is no Hook to run!\n"); return false end
	
	--If our command sends data, then we need to receive the appropriate type of data.
	--We'll pass this onto the hook function.
	local hookArgs={};
	local NIL="%%00";		--If a command isn't given, this is substituted. It means we received nil (nothing).
	
	for i=1,table.maxn(command.Datatypes) do
		local v=command.Datatypes[i];
		local currentArg=args[i];
		if currentArg==NIL then
			hookArgs[i]=nil;
		elseif v==1||v==2||v==3||v==4||v==12||v==13||v==14 then
			hookArgs[i]=tonumber(currentArg);
		elseif v==5 then
			if currentArg=="t" then
				hookArgs[i]=true;
			else
				hookArgs[i]=false;
			end
		elseif v==6 then
			hookArgs[i]=string.gsub(currentArg,"%%20"," ");
		elseif v==7 then
			hookArgs[i]=ents.GetByIndex(currentArg);
		elseif v==8 then
			local breakString=string.Explode(",",currentArg);
			
			hookArgs[i]=Vector(tonumber(breakString[1]),tonumber(breakString[2]),tonumber(breakString[3]));
		elseif v==9 then
			local breakString=string.Explode(",",currentArg);
			
			hookArgs[i]=Angle(tonumber(breakString[1]),tonumber(breakString[2]),tonumber(breakString[3]));
		elseif v==10 then
			local itemid=tonumber(currentArg);
			hookArgs[i]=IF.Items:Get(itemid);
		elseif v==11 then
			local invid=tonumber(currentArg);
			hookArgs[i]=IF.Inv:Get(invid);
		end
	end
	command.Hook(self,fromPl,unpack(hookArgs));
end
IF.Items:ProtectKey("ReceiveNWCommand");

--Runs when a client requests to send this item to an inventory
function ITEM:PlayerSendToInventory(pl,inv,invSlot)
	if !self:CanPlayerInteract(pl) then return false end
	if !inv || !inv:IsValid() then ErrorNoHalt("Itemforge Items: Couldn't move "..tostring(self).." to inventory as requested by player "..tostring(pl)..", inventory given was not valid!\n"); return false end
	if invSlot==nil then ErrorNoHalt("Itemforge Items: Couldn't move "..tostring(self).." to inventory "..inv:GetID().." as requested by player "..tostring(pl)..", no slot was given!\n"); return false end
	
	if invSlot==0 then invSlot=nil end
	
	local container,cSlot=self:GetContainer();
	self:ToInventory(inv,invSlot);
end
IF.Items:ProtectKey("PlayerSendToInventory");

--Runs when a client requests to send this item to the world somewhere
--TODO range checking on "where"
function ITEM:PlayerSendToWorld(pl,where)
	if !self:CanPlayerInteract(pl) then return false end
	self:ToWorld(where);
end
IF.Items:ProtectKey("PlayerSendToWorld");

--Runs when a client requests to hold an item
function ITEM:PlayerHold(pl)
	if !self:CanPlayerInteract(pl) then return false end
	self:Hold(pl);
end
IF.Items:ProtectKey("PlayerHold");

--Runs when a client requests to merge this item and another item
function ITEM:PlayerMerge(pl,otherItem)
	if !self:CanPlayerInteract(pl) || !otherItem:CanPlayerInteract(pl) then return false end
	self:Merge(true,otherItem);
end
IF.Items:ProtectKey("PlayerMerge");

--Runs when a client requests to split this item
function ITEM:PlayerSplit(player,amt)
	if !self:CanPlayerInteract(player) then return false end
	return self:Split(true,amt);
end
IF.Items:ProtectKey("PlayerSplit");

--Place networked commands here in the same order as in cl_init.lua.
IF.Items:CreateNWCommand(ITEM,"ToInventory",nil,{"inventory","short"});
IF.Items:CreateNWCommand(ITEM,"RemoveFromInventory",nil,{"bool","inventory"});
IF.Items:CreateNWCommand(ITEM,"TransferInventory",nil,{"inventory","inventory","short"});
IF.Items:CreateNWCommand(ITEM,"TransferSlot",nil,{"inventory","short","short"});
IF.Items:CreateNWCommand(ITEM,"PlayerUse",function(self,...) self:Use(...) end);
IF.Items:CreateNWCommand(ITEM,"PlayerHold",function(self,...) self:PlayerHold(...) end);
IF.Items:CreateNWCommand(ITEM,"PlayerSendToInventory",function(self,...) self:PlayerSendToInventory(...) end,{"inventory","short"});
IF.Items:CreateNWCommand(ITEM,"PlayerSendToWorld",function(self,...) self:PlayerSendToWorld(...) end,{"vector"});
IF.Items:CreateNWCommand(ITEM,"PlayerMerge",function(self,...) self:PlayerMerge(...) end,{"item"});
IF.Items:CreateNWCommand(ITEM,"PlayerSplit",function(self,...) self:PlayerSplit(...) end,{"int"});