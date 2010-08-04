--[[
item
SHARED

base_item is the default item. All items except item inherit from this item-type.
NOTE: The item type is the name of the folder it is in (this is base_item/shared.lua, so this item's type is "base_item")
]]--

include("health.lua");
include("stacks.lua");
include("weight.lua");
include("nwvars.lua");
include("timers.lua");
include("sounds.lua");
include("events_shared.lua");

--[[
Non-Networked Vars
These vars are stored on both the client and the server, however, if these vars change on one side, they aren't updated on the other side.
This section is good for things that don't change often but need to be known to both the client and server, such as the item's name.
]]--

--Basic info
ITEM.Name="Default Item Name";							--An item's name is displayed by the UI in several different locations, such as the weapon selection menu (when the item is held), or displayed when selected in an inventory.
ITEM.Description="This is the default description.";	--An item's description gives additional details about the item. One place it is displayed is in the inventory when selected.
ITEM.Base="base_nw";									--The item is based off of this kind of item. Set this to nil if it's not based off of an item. Set it to the type of another item (ex: ITEM.Base="hammer") to base it off of that. (NOTE: This is useful for tools. For example: If you have an item called "Hammer" that "Stone Hammer" and "Iron Hammer" are based off of, and you have a combination that takes "Hammer" as one of it's ingredients, both the "Stone Hammer" and "Iron Hammer" can be used!)
ITEM.WorldModel="models/dav0r/buttons/button.mdl";		--When dropped on the ground, held by a player, or viewed on some places on the UI (like an inventory icon), the world model is the model displayed.
ITEM.ViewModel="models/weapons/v_pistol.mdl";			--When held by a player, the player holding it sees this model in first-person.
ITEM.Size=1;											--Default size of a single item in this stack. Size has nothing to do with how big the item looks or how much it weighs. Instead, size determines if an item can be placed in an inventory or not. In my opinion, a good size can be determined if you put the item into the world and get the entity's bounding sphere size.
ITEM.Color=Color(255,255,255,255);						--Default color of this item's model and icon. Can be changed.
ITEM.OverrideMaterial=nil;								--Default override material of this item's world model. Use nil if the model's material is not being overridden, or "path" if it is (where path is the path of the material). Can be changed.

--Restrictions on who can spawn
ITEM.Spawnable=false;									--Can this item be spawned by any player via the spawn menu on the items tab?
ITEM.AdminSpawnable=false;								--Can this item be spawned by an admin via the spawn menu on the items tab?

--SWEP related
ITEM.PrimaryAuto=false;									--If this item is held as a weapon, is it's primary fire automatic? Or, in other words, do I have to keep clicking to attack?
ITEM.SecondaryAuto=false;								--If this item is held as a weapon, is it's secondary fire automatic? Or, in other words, do I have to keep right-clicking to attack?
ITEM.HoldType="pistol";									--How does a player hold this item when he is holding it as a weapon? Valid values: "pistol","smg","grenade","ar2","shotgun","rpg","physgun","crossbow","melee","slam","normal"
ITEM.SWEPSlot=0;										--What slot # is this item categorized under in the weapon menu? (where 0 is slot #1, 1 is slot #2, etc)
ITEM.SWEPSlotPos=0;										--When you're selecting weapons from that slot, what order does this weapon come in? (where 0 means the weapon comes first, 1 means weapon comes second, etc. This is more of a suggestion than a hardline rule to the game; several items can have the same order.)

--Don't modify/override these. They're either set automatically, don't need to be changed, or are listed here so I can keep track of them.
--Belongs to item-type
ITEM.ClassName="";										--The item-type. This is the same as the name of the folder these files are in. This is set automatically when loading item-types.
ITEM.BaseClass=nil;										--Set to the Item-Type that ITEM.Base identifies after loading all item-types
ITEM.NWCommandsByName=nil;								--Networked commands are stored here. The key is the name, value is the command. These trigger networked hooks on the other side (Client to Server or Server to Client).
ITEM.NWCommandsByID=nil;								--Networked commands are stored here. The key is the id, value is the command. These trigger networked hooks on the other side (Client to Server or Server to Client).

--Belongs to individual items
ITEM.ID=0;												--Item ID. Assigned automatically.
ITEM.Container=nil;										--If the item is in an inventory, this is the inventory it is in.			Use self:GetContainer() to grab.
ITEM.Entity=nil;										--If the item is on the ground, this is the SENT that represents the item.	Use self:GetEntity() to grab this.
ITEM.Weapon=nil;										--If the item is being held by a player, this is the SWEP entity.			Use self:GetWeapon() to grab this.
ITEM.Owner=nil;											--If the item is being held, this is the player holding it.					Use self:GetWOwner() to grab this. (NOTE: GetNetOwner() does not return this).
ITEM.BeingRemoved=false;								--This will be true if the item is being removed.
ITEM.Inventories=nil;									--Inventories connected to this item are stored here. The item 'has' these inventories (a backpack or a crate would store it's inventory here, for example). The key is the inventory's ID. The value is the actual inventory.
ITEM.Rand=nil;											--Every item has a random number. This is mostly used for adding some variety to different effects, such as the model spinning. Use self:GetRand() to grab this.

--[[
DEFAULT METHODS
DO NOT OVERRIDE
IN THIS SCRIPT
OR OTHER SCRIPTS
]]--



--[[
* SHARED
* Protected

Removes the item.
]]--
function ITEM:Remove()
	return IF.Items:Remove(self);
end
IF.Items:ProtectKey("Remove");

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
function ITEM:ToInventory(inv,slot,pl,bNoMerge,bPredict)
	if self.BeingRemoved then return false end
	if !inv || !inv:IsValid()					then return self:Error("Could not insert item into an inventory - given inventory was invalid!\n") end
	if pl!=nil then
		if !pl:IsValid()						then return self:Error("Couldn't insert item into "..tostring(inv)..". Player given is not valid!\n");
		elseif !pl:IsPlayer()					then return self:Error("Couldn't insert item into "..tostring(inv)..". The player given is not a player.\n");
		elseif !inv:CanSendInventoryData(pl)	then return self:Error("Couldn't insert item into "..tostring(inv)..". The inventory given is private, and the player given is not the owner of the inventory.\n");
		end
	end
	
	if bPredict==nil then bPredict=CLIENT end
	local oldinv,oldslot=self:GetContainer();
	
	if SERVER || bPredict then
		local bSameInv=(oldinv==inv);
		if bSameInv && !slot					then return self:Error("Couldn't insert item into "..tostring(inv)..". The item is already in this inventory. No slot was given, so the item can't be moved to a different slot, either.\n") end
		
		local bSameSlot=(oldslot==slot);
		local bSendingUpdate=(bSameInv && bSameSlot);
		if !bSendingUpdate && !self:Event("CanMove",true,oldinv,oldslot,inv,slot) then return false end	
		
		--We're moving the item from one slot to another in the same inv
		if bSameInv then
			if !bSameSlot then
				if !inv:MoveItem(self,oldslot,slot,bPredict) then return false end
			
				--Ask client to transfer slots too
				if SERVER && !bPredict then self:SendNWCommand("TransferSlot",nil,inv,oldslot,slot); end
				return true;
			end
		
		--Since we're not moving items around, that means the item has just entered this inventory.
		--We'll merge this stack with as many existing stacks of items as possible (unless told not to).
		--False is returned if/when this whole stack has been merged into other stacks of items.
		elseif !bNoMerge then
			
			--TODO prediction will fail if we have to merge across several stacks of items
			for k,v in pairs(inv:GetItemsByType(self:GetType())) do if self:Event("CanInventoryMerge",false,v,inv) && v:Event("CanInventoryMerge",false,self,inv) && v:Merge(self,nil,bPredict)==true then return false end end
		end
	else
		--We don't stop insertion clientside if the item has an entity or another container already, but we bitch about it so the scripter knows something isn't right
		if slot==nil				then return self:Error("Could not add item to "..tostring(inv).." clientside! slot was not given!\n") end
		if oldinv && oldinv!=inv	then self:Error("Warning! This item is already in "..tostring(oldinv).." clientside, but is being inserted into "..tostring(inv).." anyway! Not supposed to happen!\n") end
	end
	
	local slotid=inv:InsertItem(self,slot,nil,bPredict);
	if slotid==false || (slot!=nil && slotid!=slot) then return false end
	
	if !bPredict then
		self:SetContainer(inv);
		self:Event("OnMove",nil,oldinv,oldslot,inv,slotid,false);
		
		if SERVER then
			--This was a real headache to do but I think I maxed out the efficency
			local newOwner=inv:GetOwner();
			local lastOwner=self:GetOwner();
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
		end
	end
	return true;
end
IF.Items:ProtectKey("ToInventory");

--A shorter alias
ITEM.ToInv=ITEM.ToInventory;
IF.Items:ProtectKey("ToInv");

--[[
* SHARED
* Protected

Serverside, this function places the item in the world (as an entity).
Clientside, this function is called when the item binds with it's world entity.
vPos is a Vector() describing the position in the world the entity should be created at.
aAng is an optional Angle() describing the angles it should be created at.
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
False is returned if the item cannot be moved to the world for any reason. Otherwise, the entity created is returned.
]]--
function ITEM:ToWorld(vPos,aAng,eEnt,bPredict)
	if self.BeingRemoved then return false end
	
	if bPredict==nil then bPredict=CLIENT end
	
	local ent=self:GetEntity();
	local bTeleport=(ent!=nil);
	
	if SERVER || bPredict then
		if vPos==nil then return self:Error("Could not create an entity, position to create item at was not given.\n") end
		aAng=aAng or Angle(0,0,0);
		
		--Give events a chance to stop the item from moving to the world there
		if !self:Event("CanEnterWorld",true,vPos,aAng,bTeleport) then return false end
		
		--Just teleport this item's ent if it's already in the world
		if bTeleport then
			if bPredict then return true end
			
			ent:SetPos(vPos);
			ent:SetAngles(aAng);
			
			local phys=ent:GetPhysicsObject();
			if phys && phys:IsValid() then
				phys:Wake();
			end
		else
			--Before we send the item to the world we have to remove it from where it was (or fail if we couldn't)
			if !self:ToVoid(false,nil,nil,bPredict) then return false end
			
			if bPredict then
				return true;
			else
				ent=ents.Create(IF.Items.BaseEntityClassName);
				if !ent || !ent:IsValid() then return self:Error("Tried to create "..IF.Items.BaseEntityClassName.." entity but failed.\n") end
				
				ent:SetItem(self);
				ent:SetPos(vPos);
				ent:SetAngles(aAng);
				self:SetEntity(ent);
				
				IF.Items:AddWorldItem(self);
			end
		end
	else
		if !eEnt || !eEnt:IsValid() then return self:Error("Couldn't set entity clientside... no valid entity was given.\n") end
		
		--Ideally, this item should never already have an entity when a new one is given to it clientside. However, it happens - sometimes an item acquires a new entity before an old one can be removed, so I'm making it ignore this check.
		--if bTeleport then self:Error("Warning! Setting entity to "..tostring(eEnt).." even though it already has an entity ("..tostring(ent)..")!\n") end
		
		ent=eEnt;
		self:SetEntity(ent);
		
		IF.Items:AddWorldItem(self);
	end
	
	--Run events to indicate a :ToWorld() occured
	self:Event("OnEnterWorld",nil,ent,vPos,aAng,bTeleport);
	return ent;
end
IF.Items:ProtectKey("ToWorld");

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
wep is only necessary clientside. This will be the SWEP created for this item.
This function calls the CanHold event, which has a chance to stop the item from being held.
If the item is successfully held:
	The item's OnSWEPInit event is called to initialize the SWEP.
	The item's OnHold event is called.

False is returned if the item can't be held for any reason. Otherwise, the newly created weapon entity is returned.
]]--
function ITEM:Hold(pl,bNoMerge,wep,bPredict)
	if self.BeingRemoved then return false end
	if self:GetWOwner() == pl then return true end
	
	if bNoMerge==nil then bNoMerge=false end
	if bPredict==nil then bPredict=CLIENT end
	
	local ent;
	
	if SERVER || bPredict then
		if !pl || !pl:IsValid()	then return self:Error("Couldn't hold item as weapon. Player given is not valid!\n")
		elseif !pl:IsPlayer()	then return self:Error("Couldn't hold item as weapon. The player given is not a player.\n")
		elseif !pl:Alive()		then return false end
		
		--We can allow the events a chance to stop the item from being held
		if !self:Event("CanHold",true,pl) then return false end
		
		
		
		--Here we determine two things: Can we merge this stack of items with a stack we're holding?
		local strWeaponName="if_"..self.ClassName;
		
		--TODO pl:GetWeapon is SERVER ONLY ARGhdhsgsgdjlk garry/valve you cocksuckers
		if SERVER then
			local currentlyHeld=pl:GetWeapon(strWeaponName);
			if currentlyHeld && currentlyHeld:IsValid() then
				if !bNoMerge then
					local heldItem=currentlyHeld:GetItem();
					if heldItem && self:Event("CanHoldMerge",false,heldItem,pl) && heldItem:Event("CanHoldMerge",false,self,pl) && heldItem:Merge(self,nil,bPredict) then
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
		if !self:ToVoid(false,nil,nil,bPredict) then return false end
		
		if bPredict then
			return true;
		else
			ent=pl:Give(strWeaponName);
			--local ent=ents.Create(strWeaponName);
			--ent:SetPos(pl:GetPos()+Vector(0,0,64));
		
			if !ent || !ent:IsValid() then return self:Error("Tried to create "..strWeaponName.." entity but failed.\n") end
		
			--This function triggers the item's OnSWEPInit hook.
			ent:SetItem(self);
		end
	else
		ent=wep;
	end
	
	self:SetWeapon(ent);
	self:SetWOwner(pl);
	IF.Items:AddHeldItem(self);
	
	--Run OnHold event
	self:Event("OnHold",nil,pl,ent);
	
	return ent;
end
IF.Items:ProtectKey("Hold");

--[[
* SHARED
* Protected

Moves this item to the same location as another item
extItem should be an existing item. If extItem is:
	In the world, this item is moved to the world at the exact same position and angles. Additionally, this item will be travelling at the same velocity as extItem when it is created.
	In an inventory, this item is moved to the inventory that extItem is in. If we can't fit the item in that inventory, we try to send it to the same location as the item/entity it's connected to.
	Held by a player, this item is also held by the player. If the player cannot hold any more items, then the item is moved to the world, at the shoot location of the player holding it.
	In the void, this item is moved to the void.

Scatter is an optional true/false.
	If scatter is true and extItem is in the world,
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
function ITEM:ToSameLocationAs(extItem,scatter,bNoMerge,bPredict)
	if !extItem or !extItem:IsValid() then return self:Error("Tried to move item to same location as another item, but the other item wasn't given / was invalid!\n") end
	
	if scatter==nil then scatter=false end
	if bNoMerge==nil then bNoMerge=false end
	if bPredict==nil then bPredict=CLIENT end
	
	local container=extItem:GetContainer();
	if container then
		--Sometimes we'll inventory merge, which returns false in :ToInventory but also removes this item TODO make it return true instead
		if !self:ToInventory(container,nil,nil,bNoMerge,bPredict) && self:IsValid() then
			--If we can't move the item to the container that extItem was in, we'll try moving it to the same place as that container's connected item.
			local t=container:GetConnectedItems();
			local c=table.getn(t);
			
			--If this inventory isn't connected to anything we fail
			if c==0 then return false end
			
			--If it is though, we'll pick one of the connections randomly and send the item to that location
			return self:ToSameLocationAs(t[math.random(1,c)],scatter,bNoMerge,bPredict);
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
			
			newEnt=self:ToWorld(where,whereAng,nil,bPredict);
			if !newEnt then return false end
		else
			newEnt=self:ToWorld(ent:GetPos(),ent:GetAngles(),nil,bPredict);
			if !newEnt then return false end
		end
		
		if !bPredict then
			local newEntPhys=newEnt:GetPhysicsObject();
			if newEntPhys && newEntPhys:IsValid() then newEntPhys:SetVelocity(ent:GetVelocity()); end
		end
		
		return true;
	elseif extItem:IsHeld() then
		local pl=extItem:GetWOwner();
		if !pl then return self:Error("ERROR! Trying to move item failed. The item given, "..tostring(extItem).." is being held, but player holding it could not be determined.\n") end
		
		--The :IsValid() check is here because Hold() could return false to indicate that this item was merged into an existing stack the player was holding
		if self:Hold(pl,bNoMerge,nil,bPredict) || !self:IsValid() || self:ToWorld(pl:GetShootPos(),pl:GetAimVector(),nil,bPredict)	then return true end
		
		return false;
	end
	
	if !self:ToVoid(nil,nil,nil,bPredict) then return false end
	return true;
end
IF.Items:ProtectKey("ToSameLocationAs");

--[[
* SHARED
* Protected

ToVoid releases a held item, removes the item from the world, or takes an item out of an inventory. Or in other words, it places the item in the void.
It isn't necessary to send an item to the void after it's created - the item is already in the void.

forced is an optional argument that should be true if you want the removal to ignore events that say not to release/remove/etc. This should only be true if the item has to come out, like if the item is being removed.
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
function ITEM:ToVoid(forced,vDoubleCheck,bNotFromClient,bPredict)
	if forced==nil then			forced=false			end
	if bNotFromClient==nil then	bNotFromClient=false	end
	if bPredict==nil then		bPredict=CLIENT			end
	
	--Is the item in the world?
	if self:InWorld() then
		local ent=self:GetEntity();
		if vDoubleCheck && ent!=vDoubleCheck then return false end
		
		if !forced && (SERVER || bPredict) && !self:Event("CanExitWorld",true,ent) then return false end
		if !bPredict then
			self:ClearEntity();
			if SERVER then ent:ExpectedRemoval(); end
			
			IF.Items:RemoveWorldItem(self);
			
			--TODO: DETERMINE IF SERVER FORCED REMOVAL
			self:OnExitWorldSafe(forced);
		end
	--Maybe it's being held.
	elseif self:IsHeld() then
		local ent=self:GetWeapon();
		if vDoubleCheck && ent!=vDoubleCheck then return false end
		local pOwner=self:GetWOwner();
		
		if !forced && (SERVER || bPredict) && !self:Event("CanRelease",true,pOwner) then return false end
		if !bPredict then
			if SERVER then ent:ExpectedRemoval(); end
			self:ClearWeapon(vDoubleCheck);
			
			IF.Items:RemoveHeldItem(self);
			
			--TODO: DETERMINE IF SERVER FORCED REMOVAL
			self:Event("OnRelease",nil,pOwner,forced);
		end
		
	--So we're not in the world or held; How about a container?
	elseif self:InInventory() then
		local container,cslot=self:GetContainer();
		if vDoubleCheck && container!=vDoubleCheck then return false end
		
		--If removal isn't forced our events can stop the removal
		if !forced && (SERVER || bPredict) && !self:Event("CanMove",true,container,cslot) then return false end
		if !container:RemoveItem(self:GetID(),forced,bPredict) && !forced && (SERVER || bPredict) then return false end
		
		if !bPredict then
			self:ClearContainer();
			self:Event("OnMove",nil,container,cslot,nil,nil,forced);
		
			--Tell clients to remove this item from the inventory (unless specifically told not to)
			if SERVER && !bNotFromClient then
				local oldOwner=container:GetOwner();
				self:SetOwner(oldOwner,nil);
				self:SendNWCommand("RemoveFromInventory",oldOwner,forced,container);
			end
		end
	end
	
	return true;
end
IF.Items:ProtectKey("ToVoid");

--[[
* SHARED
* Protected

Sets the size of every item in the stack.

Size has nothing to do with weight or how big the item looks.
The only thing size determines is if an item can be placed inside of an inventory that has a size limit.

iSize can be 0 to indicate it has no size, but negative values will result in an error.
]]--
function ITEM:SetSize(iSize)
	if iSize<0 then return self:Error("You can't set size to a negative value ("..iSize..").") end
	return self:SetNWInt("Size",iSize);
end
IF.Items:ProtectKey("SetSize");

--[[
* SHARED
* Protected

This sets the weapon menu slot and it's position in that slot that the item uses
when it's being held as a weapon.

Running this on the server will change the slot/position of any player who holds this item.
Running this on the client will only change the slot/position for that player, however.
]]--
function ITEM:SetSWEPSlot(iSlot,iSlotPos)
	if iSlot == nil then return self:Error("Couldn't set SWEP slot; the slot was invalid.") end
	if iSlotPos==nil then iSlotPos = self:GetSWEPSlotPos() end
	
	return self:SetNWInt("SWEPSlot",iSlot) && self:SetNWInt("SWEPSlotPos",iSlotPos);
end
IF.Items:ProtectKey("SetSWEPSlot");

--[[
* SHARED
* Protected

This sets the model color/icon color of this item.
]]--
function ITEM:SetColor(cCol)
	self:SetNWColor("Color",cCol);
end
IF.Items:ProtectKey("SetColor");

--[[
* SHARED
* Protected

This sets the override material this item uses for it's model.
]]--
function ITEM:SetOverrideMaterial(sMat)
	self:SetNWString("OverrideMaterial",sMat);
end
IF.Items:ProtectKey("SetOverrideMaterial");








--[[
* SHARED
* Protected

Returns the itemtype of this item
For example "base_item", "item_crowbar", etc...
]]--
function ITEM:GetType()
	return self.ClassName;
end
IF.Items:ProtectKey("GetType");

--[[
* SHARED
* Protected

Returns the item/stack's ID.
]]--
function ITEM:GetID()
	return self.ID;
end
IF.Items:ProtectKey("GetID");

--[[
* SHARED
* Protected

Returns this item's random number. Generates a random number for the item if it doesn't have one yet.
]]--
function ITEM:GetRand()
	if !self.Rand then self.Rand=math.random()*100 end
	return self.Rand;
end
IF.Items:ProtectKey("GetRand");

--[[
* SHARED
* Protected

Get the size of an item in the stack (they all are the same size).
]]--
function ITEM:GetSize()
	return self:GetNWInt("Size");
end
IF.Items:ProtectKey("GetSize");

--[[
* SHARED
* Protected

Returns the world model.
]]--
function ITEM:GetWorldModel()
	return self:GetNWString("WorldModel");
end
IF.Items:ProtectKey("GetWorldModel");

--[[
* SHARED
* Protected

Returns the view model.
]]--
function ITEM:GetViewModel()
	return self:GetNWString("ViewModel");
end
IF.Items:ProtectKey("GetViewModel");

--[[
* SHARED
* Protected

This returns the weapon menu slot the item uses
when it's being held as a weapon.
]]--
function ITEM:GetSWEPSlot()
	return self:GetNWInt("SWEPSlot");
end
IF.Items:ProtectKey("GetSWEPSlot");

--[[
* SHARED
* Protected

This returns the position the weapon occupies in the chosen weapon menu slot.
]]--
function ITEM:GetSWEPSlotPos()
	return self:GetNWInt("SWEPSlotPos");
end
IF.Items:ProtectKey("GetSWEPSlotPos");

--[[
* SHARED
* Protected

This returns the current model color/icon color of this item.
]]--
function ITEM:GetColor()
	return self:GetNWColor("Color");
end
IF.Items:ProtectKey("GetColor");

--[[
* SHARED
* Protected

This returns the override material this item uses for it's model.
]]--
function ITEM:GetOverrideMaterial()
	return self:GetNWString("OverrideMaterial");
end
IF.Items:ProtectKey("GetOverrideMaterial");

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
	local inv=self:GetContainer();
	if inv==nil then
		return nil;
	end
	return inv:GetOwner();
end
IF.Items:ProtectKey("GetOwner");

--[[
* SHARED
* Protected

If the item is in the world, returns the item's world entity.
If the item is held by a player, in an inventory, or in the void, this function returns nil.
Doing :IsValid() on an entity returned from here is not necessary; if this function returns an entity, it is always valid.
]]--
function ITEM:GetEntity()
	if self.Entity && !self.Entity:IsValid() then
		self.Entity=nil;
		return nil;
	end
	return self.Entity;
end
IF.Items:ProtectKey("GetEntity");

--[[
* SHARED
* Protected

If the item is being held, returns it's weapon.
If the item is in the world, in an inventory, or in the void, this function returns nil.
Doing :IsValid() on a weapon returned from here is not necessary; if this function returns a weapon, it is always valid.
]]--
function ITEM:GetWeapon()
	if self.Weapon && !self.Weapon:IsValid() then
		self.Weapon=nil;
		return nil;
	end
	return self.Weapon;
end
IF.Items:ProtectKey("GetWeapon");

--[[
* SHARED
* Protected

Returns the player who is holding this item as a weapon (the Weapon Owner; this is equivilent to self.Owner in an SWEP).
If the item has been put into an SWEP, but no player is holding it yet, nil is returned (this occasionally happens).
If the item isn't being held as a weapon, this returns nil.
]]--
function ITEM:GetWOwner()
	if self.Owner && !self.Owner:IsValid() then
		self.Owner=nil;
		return nil;
	end
	return self.Owner;
end
IF.Items:ProtectKey("GetWOwner");

--[[
* SHARED
* Protected

Returns two values: The inventory the item is in, and the slot that it's occupying in this inventory.
If the item isn't in an inventory, it returns nil,0.
If the inventory isn't valid any longer (or if the item isn't in the inventory any longer) it's set to nil and nil,0 is returned
Get the two values like so:
	local inv,slot=item:GetContainer();
]]--
function ITEM:GetContainer()
	if !self.Container then return nil,0 end
	if !self.Container:IsValid() then
			self.Container=nil;
			return nil,0;
	end
	local ContainerSlot=self.Container:GetItemSlotByID(self:GetID());
	if !ContainerSlot then
		self.Container=nil;
		return nil,0;
	end
	return self.Container,ContainerSlot;
end
IF.Items:ProtectKey("GetContainer");

--[[
* SHARED
* Protected

Returns the item's position in the world.
What is returned depends on the state the item is in.
If the item is in the world as an entity, the entity's position is returned.
If the item is being held as a weapon, the shoot position of the holding player is returned (it's usually the center of the player's view).
If the item is in an inventory, the position(s) of the inventory are returned.
	An inventory can be connected with one or more items and entities, or none at all.
	If you get the position of an inventory, it returns the position(s) of the inventory's connected object(s).
	So, if our item is in an inventory connected with a barrel entity, it returns the position of the barrel entity.
	If our item is in a bottle inside of a crate in the world, it returns the crate's position.
	If our item is in an inventory connected with, lets say, two bags that share the same inventory, then it returns both the positon of the first bag and the second (as a table).
	If the item is in an inventory that doesn't have a connected object, it returns nil.
If the item is in the void (not in any of the either three states) then nil is returned.

SO, in summary, this function can return three different types of data:
	A vector, if the item is in the world, being held, or if the item is in an inventory with one connected object
	a table of vectors, if the item is in an inventory with more than one connected object
	nil, if the item is in the void, or the inventory the item is in is in the void.
You can check to see what this returns by doing... local t=type(item:GetPos()); then checking to see if 't' is "vector", "table", or "nil"
]]--
function ITEM:GetPos()
	if self:InWorld() then
		local ent=self:GetEntity();
		return ent:GetPos();
	elseif self:IsHeld() then
		local p=self:GetWOwner();
		if !p then self:Error("ERROR! GetPos failed. This item is being held, but player holding this item is no longer valid.\n"); return nil end
		return p:GetShootPos();
	elseif self:InInventory() then
		local container=self:GetContainer();
		return container:GetPos();
	end
	
	return self:Event("GetVoidPos",nil);
end
IF.Items:ProtectKey("GetPos");

--[[
* SHARED
* Protected

Is this item in an inventory? (a specific inventory?) (a specific slot?)
inv is an optional argument.
slot is an optional argument.
	If neither inv or slot is given, then true is returned if the item is in any inventory, any slot.
	If inv is given but slot isn't, then true will be returned if the item is in the inventory given.
	If inv isn't given but slot is, true is returned if this item is in that slot on any inventory.
	If inv and slot are given, true is returned only if this item is in the given inventory, in that slot.

]]--
function ITEM:InInventory(inv,slot)
	local bInv=false;
	local bSlot=false;
	local container,iSlot=self:GetContainer();
	
	if container!=nil then				--If the item is in a container
		if !inv then					--and inv wasn't given
			bInv=true;
		elseif !inv:IsValid() then		--and inv was given, check to see if this inventory is legit
			self:Error("ERROR! InInventory() failed. Inventory given is non-existent or has been removed. Check to see if the inventory is valid before passing it.\n");
		elseif inv==container then		--then check if we're in this inventory
			bInv=true;
		end
		
		if !slot || iSlot==slot then
			bSlot=true;
		end
	end
	
	return (bInv&&bSlot);
end
IF.Items:ProtectKey("InInventory");
ITEM.InInv=ITEM.InInventory;
IF.Items:ProtectKey("InInv");

--[[
* SHARED
* Protected

Returns true if the item is in the world
]]--
function ITEM:InWorld()
	local ent=self:GetEntity();
	if ent then return true; end
	return false;
end
IF.Items:ProtectKey("InWorld");

--[[
* SHARED
* Protected

Returns true if the item is being held as a weapon
byPlayer is an optional argument.
	If byPlayer isn't given, then true will be returned if the item is held by any player at all.
	If byPlayer is given, then true will be returned only if the item is held by the player given.
TODO held by something other than a player
]]--
function ITEM:IsHeld(byPlayer)
	local ent=self:GetWeapon();
	if ent then
		if byPlayer!=nil then
			--Validate given player
			if !byPlayer:IsValid()		then return self:Error("IsHeld failed. Given player is non-existent or has been removed.\n") end
			if !byPlayer:IsPlayer()		then return self:Error("ERROR! IsHeld failed. Given player is not a player!\n") end
			
			--Check to see if the player holding this is still valid
			local p=self:GetWOwner();
			if !p then return self:Error("ERROR! IsHeld failed. This item is held, but the player holding this item cannot be determined.\n") end
			
			--If this item isn't being held by the given player return false. (if it is being held by this player, true is returned beneath this check)
			if p!=byPlayer then return false end
		end
		
		return true;
	end
	return false;
end
IF.Items:ProtectKey("IsHeld");

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
IF.Items:ProtectKey("InVoid");

--[[
* SHARED
* Protected

Protected OnExitWorld event.
Stops all looping sounds and then runs the overridable OnExitWorld event.
]]--
function ITEM:OnExitWorldSafe(forced)
	self:StopAllLoopingSounds();
	
	--Run the event
	self:Event("OnExitWorld",nil,forced);
end
IF.Items:ProtectKey("OnExitWorldSafe");

--[[
* SHARED
* Protected

Run this to start the item's Think event. Think is off by default.
]]--
function ITEM:StartThink()
	timer.Create("if_itemthink_"..self:GetID(),self.ThinkRate,0,self.Event,self,"OnThink");
end
IF.Items:ProtectKey("StartThink");

--[[
* SHARED
* Protected

Set the think rate. Set this to 0 to trigger the think every frame.
Note that if the item is currently thinking (after StartThink()), calling this function cancels the think timer and restarts it at the new speed
]]--
function ITEM:SetThinkRate(rate)
	self.ThinkRate=rate;
	if timer.IsTimer("if_itemthink_"..self:GetID()) then
		self:StopThink();
		self:StartThink();
	end
end
IF.Items:ProtectKey("SetThinkRate");

--[[
* SHARED
* Protected

Run this to stop the item's Think event. Think is off by default.
]]--
function ITEM:StopThink()
	local n="if_itemthink_"..self:GetID();
	if timer.IsTimer(n) then timer.Remove(n) end
end
IF.Items:ProtectKey("StopThink");

--[[
* SHARED
* Protected

Run this function to request that a player move the item to a given inventory.
False is returned if the item is unable to be moved for any reason.
]]--
function ITEM:PlayerSendToInventory(pl,inv,iSlot)
	if !pl || !pl:IsValid() || !pl:IsPlayer() || !self:Event("CanPlayerInteract",false,pl) then return false end
	if !inv || !inv:IsValid()	then return self:Error("Couldn't move to inventory as requested by "..tostring(pl)..", inventory given was not valid!\n") end
	if iSlot==0 then iSlot=nil end
	
	--Predict whether or not the item can be inserted clientside,
	--or actually attempt an insertion serverside
	if !self:ToInventory(inv,iSlot,nil,true) then return false end
	
	--Clientside, if we've predicted it will succeed then we'll attempt an insertion serverside.
	if CLIENT then
		self:SendNWCommand("PlayerSendToInventory",inv,iSlot);
	end
end
IF.Items:ProtectKey("PlayerSendToInventory");




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

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:Initialize(owner)
	self:Event("OnInit",nil,owner);
	
	return true;
end
IF.Items:ProtectKey("Initialize");

--[[
* SHARED
* Protected

Sets the item's entity. Whenever an item is in the world, a SENT is created.
We need to link this SENT with the item, so the item can refer to it later.
ent must be a valid "itemforge_item" entity, or this function will fail. If for some reason a different SENT needs to be used, I'll consider allowing different SENTS to be used.

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:SetEntity(ent)
	if !ent || !ent:IsValid()						then return self:Error("Couldn't set entity! Given entity was not valid!\n") end
	if ent:GetClass()!=IF.Items.BaseEntityClassName	then return self:Error("Couldn't set entity! Given entity was not an "..IF.Items.BaseEntityClassName.."!\n") end
	
	self.Entity=ent;
	return true;
end
IF.Items:ProtectKey("SetEntity");

--[[
* SHARED
* Protected

Clears the item's entity.

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:ClearEntity()
	self.Entity=nil;
end
IF.Items:ProtectKey("ClearEntity");

--[[
* SHARED
* Protected

Sets this item's weapon. Whenever an item is held, an SWEP is created.
We need to link this SWEP with the item, so the item can refer to it later.
ent must be a valid itemforge_item_held_* entity, or this function will fail. If for some reason a different SWEP needs to be used, I'll consider allowing different SWEPs to be used.

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:SetWeapon(ent)
	if !ent || !ent:IsValid()		then return self:Error("Couldn't set weapon! Given entity was not valid!\n") end
	if !IF.Items:IsWeaponItem(ent)	then return self:Error("Couldn't set weapon! Given entity was not a valid Itemforge weapon class!\n") end
	
	self.Weapon=ent;
	return true;
end
IF.Items:ProtectKey("SetWeapon")

--[[
* SHARED
* Protected

Sets this item's owner. Whenever an item is held, an SWEP is created.
We need to record what player is holding this SWEP so the item can refer to him later.
pl must be a valid player or this function will fail.

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:SetWOwner(pl)
	if !pl || !pl:IsValid()	then return self:Error("Couldn't set weapon owner! Given player was not valid!\n") end
	if !pl:IsPlayer()		then return self:Error("Couldn't set weapon owner! Given player was not a player!\n") end

	self.Owner=pl;
	return true;
end
IF.Items:ProtectKey("SetWOwner")

--[[
* SHARED
* Protected

Clears this item's weapon and weapon owner.

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:ClearWeapon()
	self.Weapon=nil;
	self.Owner=nil;
	return true;
end
IF.Items:ProtectKey("ClearWeapon");

--[[
* SHARED
* Protected

Sets the item's container (inventory that this item is inside of).

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:SetContainer(inv)
	self.Container=inv;
	return true;
end
IF.Items:ProtectKey("SetContainer");

--[[
* SHARED
* Protected

Clears this item's container (inventory that this item is inside of).
If inv is given, inv must match this item's set container.
	This is just in case we're expecting a certain inventory to be cleared and something goes wrong because of something like netsync.
If inv isn't given, then we'll just clear the container regardless of what it is.

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:ClearContainer()
	self.Container=nil;
	return true;
end
IF.Items:ProtectKey("ClearContainer");

--[[
* SHARED
* Protected

Adds an inventory to this item's list of connected inventories.
Connect an inventory with inv:ConnectItem(item), not this function
true is returned if successful, false otherwise

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:ConnectInventory(inv,conslot)
	if !inv || !inv:IsValid()	then return self:Error("Couldn't connect item to given inventory. The inventory given was invalid.\n") end
	if !conslot					then return self:Error("Couldn't connect item to given inventory. conslot wasn't given.\n") end
	
	--Create inventories collection if we haven't yet
	if !self.Inventories then self.Inventories={}; end
	
	local newRecord={};
	newRecord.Inv=inv;
	newRecord.ConnectionSlot=conslot;
	
	self.Inventories[inv:GetID()]=newRecord;
	
	--We have events that detect connections of inventories both serverside and clientside
	self:Event("OnConnectInventory",nil,inv,conslot);
		
	return true;
end
IF.Items:ProtectKey("ConnectInventory");

--[[
* SHARED
* Protected

Removes a connected inventory from this item's list of connected inventories.
Sever an inventory with inv:SeverItem(item), not this function

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:SeverInventory(inv)
	if !inv || !inv:IsValid() then return self:Error("Couldn't sever item from given inventory. The inventory given was invalid.\n") end

	local invid=inv:GetID();
	if !self.Inventories || !self.Inventories[invid] then return self:Error("Couldn't sever item from "..tostring(inv)..". The inventory is not listed as connected on the item.\n") end
	self.Inventories[invid]=nil;
	
	--We have events that detect severing of inventories both serverside and clientside
	self:Event("OnSeverInventory",nil,inv);
	
	return true;
end
IF.Items:ProtectKey("SeverInventory");

--[[
* SHARED
* Protected

If the given inventory is connected to this item, returns the index of the connection on this item.
]]--
function ITEM:GetInventoryConnectionSlot(invid)
	if !invid											then return self:Error("Couldn't grab connection slot that this item is occupying on an inventory. The inventory ID wasn't given.\n") end
	if !self.Inventories || !self.Inventories[invid]	then return self:Error("Couldn't grab connection slot that this item is occupying on an inventory. This inventory isn't connected to this item.\n") end
	return self.Inventories[invid].ConnectionSlot;
end
IF.Items:ProtectKey("GetInventoryConnectionSlot");