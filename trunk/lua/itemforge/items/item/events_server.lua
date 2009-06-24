--[[
events_server
SERVER

item is the default item. All items except item inherit from this item-type.
NOTE: The item type is the name of the folder it is in (this is item/events_server.lua, so this item's type is "item")

This specific file deals with events that are present on the server.
]]--

--[[
ENTITY SPECIFIC EVENTS
]]--

--[[
Whenever an item is dropped into the world, an entity is created to represent it.
This function will be run when the entity is initialized, before it's spawned.
entity should be the same thing as self:GetEntity(). It's the entity the item is using while it's in the world.

Scripters can override this to init the entity however they like here.
Mine is pretty general, it sets the model to whatever the scripter has provided, inits physics, sets it to simple use (you press E once and it uses it once) and spawns it.
]]--
function ITEM:OnEntityInit(entity)
	--We'll grab and set the world model of the entity first
	entity:SetModel(self:GetWorldModel());
	
	--Next we init physics (and wake the object so it starts moving immediately)
	entity:PhysicsInit(SOLID_VPHYSICS);
	local phys = entity:GetPhysicsObject();
	if (phys:IsValid()) then
		phys:Wake();
	end
	
	--We'll do some other stuff like set it to simple use here
	entity:SetUseType(SIMPLE_USE);
	
	return true;
end

--[[
While the item is in the world as an entity, if it's damaged physically (such as being burned by fire or hit with a crowbar) then this event will be triggered.
By default, whenever an item's entity is damaged, the item is damaged. Then the item's entity is knocked around a bit when we do TakePhysicsDamage.
entity should be the same thing as self:GetEntity(). It's the entity the item is using while it's in the world.
dmgInfo is information passed to the entity's OnTakeDamage function.
]]--
function ITEM:OnEntTakeDamage(entity,dmgInfo)
	self:Hurt(dmgInfo:GetDamage(),dmgInfo:GetAttacker());
	entity:TakePhysicsDamage(dmgInfo);
end

--[[
While the item is in the world as an entity, if (one of) it's physics objects hits another physics object, this hook is called.
entity should be the same thing as self.Entity. It's the entity the item is using while it's in the world.
CollisionData is information about the collision passed on from the entity's event.
HitPhysObj is the physics object belonging to this entity which collided.
]]--
function ITEM:OnPhysicsCollide(entity,CollisionData,HitPhysObj)
	
end

--[[
While an item is in the world, if it bumps into another entity this function is called.
ent should be the same thing as self.Entity. It's the entity the item is using while it's in the world.
activator is the entity that has been bumped into by our item's entity.
otherItem will usually be nil, but if it isn't, that means this item has touched another item in the world.
]]--
function ITEM:OnStartTouch(ent,activator,otherItem)
	
end

--[[
While an item is in the world, this function is called while our item is touching something (it will run this function continuiously until the item comes to rest on the entity it's touching, or loses contact with it).
ent should be the same thing as self.Entity. It's the entity the item is using while it's in the world.
activator is the entity that is bumping into our entity.
otherItem will usually be nil, but if it isn't, that means this item has touched another item in the world.
]]--
function ITEM:OnTouch(ent,activator,otherItem)

end

--[[
While an item is in the world, this function is called when our item loses contact with something it was touching.
ent should be the same thing as self.Entity. It's the entity the item is using while it's in the world.
activator is the entity that had been bumped into by our item's entity but now no longer is being touched.
otherItem will usually be nil, but if it isn't, that means this item has touched another item in the world.
]]--
function ITEM:OnEndTouch(ent,activator,otherItem)

end

--[[
This event can be used to give your item a Wire debug name.
When this item enters the world, this event will be called to give the item's entity a Wire debug name (for Wiremod, if it's installed).
By default, this grabs the name of the item (with GetName()). If this fails for some reason, it defaults to "Itemforge Item".
Return a string here to decide what the Wire debug name is.
WIRE
]]--
function ITEM:GetWireDebugName()
	local s,r=pcall(self.GetName,self);
	if s then
		return r;
	else
		ErrorNoHalt(r.."\n");
		return "Itemforge Item";
	end
end

--[[
This event can be used to give your items Wire inputs. This event will never be called if Wiremod is not installed.
When this item enters the world, this event will be called to give the item's entity Wire inputs.
Wire entities, like a Wire button, can trigger these inputs and cause things to happen on your item.
For example, if you had an input "On", and you hooked a button up to it, then pressed the button, it would trigger the "On" input on your item.
This function just tells Wiremod what inputs the item has, not what the inputs do. To decide what the inputs do, see ITEM:OnWireInput() below.

entity is this item's world entity (the same as self:GetEntity()).
If your item has no inputs:						return nil
If you want to give your item inputs inputs:	return Wire_CreateInputs(entity,{"Your","Inputs","Here"})
WIRE
]]--
function ITEM:GetWireInputs(entity)
	--return Wire_CreateInputs(entity,{"Example Input","Another Input","Yet Another Input"});
	return nil;
end

--[[
This event can be used to give your items Wire outputs. This event will never be called if Wiremod is not installed.
When this item enters the world, this event will be called to give the item's entity Wire outputs.
Wire entities, such as an air compressor, can be controlled by outputs from other wire entities (like buttons or our items)
For example, if you had an output "Energy" (lets pretend it's a battery), and you hooked it up to a monitor, then the monitor would display how much energy the battery has!
This function just tells Wiremod what outputs the item has. Whenever you want to trigger an output, you need to use self:WireOutput("Name",data) (ex: self:WireOutput("Energy",100))

entity is this item's world entity (the same as self:GetEntity()).
If your item has no outputs:					return nil
If you want to give your item outputs:			return Wire_CreateOutputs(entity,{"Your","Outputs","Here"})
WIRE
]]--
function ITEM:GetWireOutputs(entity)
	--return Wire_CreateOutputs(entity,{"Example Output","Another Output","Yet Another Output"});
	return nil;
end

--[[
This event runs when a wire input is triggered. This event will never be called if Wiremod is not installed.
While your item is in the world, if a wire input (which you probably specified in GetWireInputs above) is triggered on your item, you can decide what happens here.
For example:
	Lets say your item has an input, "On".
	Your item's "On" input is hooked up to a button.
	Someone comes by and presses the button, and it outputs 1.
	This event runs; entity is, of course, this item's entity, inputName is "On", and value is 1.
	
entity will always be this item's entity (the same as self:GetEntity())
inputName will be the name of the input triggered. It should be one of the inputs you specified in GetWireInputs above.
value will be the value of whatever was outputted here. This is usually a number, BUT it could possibly not be a number, keep this in mind.
WIRE
]]--
function ITEM:OnWireInput(entity,inputName,value)
	--[[
	--An example for you
	if inputName=="On" then
		if value==0 then
			--Turn off if value is 0
		else
			--Turn on if value is anything else
		end
	end
	]]--
end

--[[
SWEP SPECIFIC EVENTS
]]--

--[[
Whenever an item is held as a weapon, an SWEP is created to represent it. This function will be run while SetItem is being run on the SWEP.
SWEP is the SWEP table. It's the same as eWeapon:GetTable().
eWeapon is the SENT that is created to hold the object.
]]--
function ITEM:OnSWEPInit(SWEP,eWeapon)
	--We'll grab and set the world model and view models of the weapon first
	local s,r=pcall(self.GetWorldModel,self);
	if !s then ErrorNoHalt(r.."\n")
	else SWEP.WorldModel=r;
	end
	
	local s,r=pcall(self.GetViewModel,self);
	if !s then ErrorNoHalt(r.."\n")
	else SWEP.ViewModel=r;
	end
	
	--TODO use hooks
	SWEP.Primary.Automatic=self.PrimaryAuto;
	SWEP.Secondary.Automatic=self.SecondaryAuto;
	
	--TODO use hook
	SWEP:SetWeaponHoldType(self.HoldType);
	
	return true;
end

--[[
This is run when a player is holding the item as an SWEP and presses the left mouse button (primary attack).
The default action is to use the item.
]]--
function ITEM:OnPrimaryAttack()
	self:Use(self:GetWOwner());
end

--[[
This is run when a player is holding the item as an SWEP and presses the right mouse button (secondary attack).
The default action is to use the item.
]]--
function ITEM:OnSecondaryAttack()
	self:Use(self:GetWOwner());
end

--[[
This is run when a player is holding the item as an SWEP and presses the reload button (usually the "R" key).
Nothing happens by default.
]]--
function ITEM:OnReload()
	
end


--[[
ENTITY/SWEP SHARED EVENTS
]]--

--[[
If a key-value is set on the item's entity (either while in the world as an entity or while held as an SWEP), it will trigger this event.
You get to decide what happens when a keyvalue is set using this function.
bSWEP will be true if the keyvalue was set on the item while being held as an SWEP. It will be false if it happened while in the world, as an entity.
eEntity is the entity the keyvalue was set on. It will either be the SWEP entity (SWEP.Weapon) or the SENT entity (ENT.Entity).
key is a string. It describes _what_ should be set. It could be something like "health" or "color".
value is also a string. It describes what 'key' should be set to. For example, "100",   or "red".
]]--
function ITEM:OnKeyValue(bSWEP,eEntity,key,value)
	--DEBUG
	Msg("Itemforge Item: Keyvalue "..key.."/"..value.." set on "..tostring(eEntity).." ("..tostring(self)..")\n");
end

--[[
If an input is received on the item's entity (either while in the world as an entity or while held as an SWEP), it will trigger this event.
With this event, you get to decide what happens when an entity uses an input on this item's entity.
bSWEP will be true if the input was received on the item while being held as an SWEP. It will be false if it happened while in the world, as an entity.
eEntity is the entity the input was received on. It will either be the SWEP entity (SWEP.Weapon) or the SENT entity (ENT.Entity).
sInput is a string, the name of the input received. This describes what kind of action has been requested, such as "SetRelationship".
eActivator is the entity directly responsible for triggering this input - ex: Entity A sends an input to Entity B, which sends an input to our entity. Entity B is the activator. Check to see if activator is valid+non-nil.
eCaller is the entity indirectly responsible for triggering this input -  ex: Entity A sends an input to Entity B, which sends an input to our entity. Entity A is the caller. Check to see if caller is valid+non-nil.
data is additional data that accompanies the input. It's probably in string format but I haven't tested.

Return true to OVERRIDE the input (meaning, whatever would normally happen to the entity when this input is received gets cancelled)
Return false to ALLOW the input (meaning, whatever would normally happen to the entity, does)
]]--
function ITEM:OnInput(bSWEP,eEntity,sInput,eActivator,eCaller,data)
	--DEBUG
	Msg("Itemforge Item: \""..tostring(sInput).."\" called on "..tostring(eEntity).." ("..tostring(self).."). Activator/Caller: "..tostring(eActivator).."/"..tostring(eCaller)..". Additional Data: "..tostring(data).."\n");
	return false;
end



--[[
ITEM EVENTS
]]--

function ITEM:OnInit(owner)
	
end

--This function is run prior to an item being removed. It cannot cancel the item from being removed.
function ITEM:OnRemove()
	
end

--[[
This is run when you 'use' an item. An item can be used in the inventory with the use button, or if on the ground, by looking at the item's model and pressing E.
The default action for when it's on the ground is to pick it up.
Return false to tell the player the item cannot be used
]]--
function ITEM:OnUse(pl)
	local ent=self:GetEntity();
	if self:InWorld() && self:CanPlayerInteract(pl) then
		self:Hold(pl);
		
		return true;
	end
	return false;
end

--[[
This function runs when an item in the stack is broken (health reaches 0).
This runs once for each item in the stack. Lets say you have a stack of 10 bottles. Each time a bottle breaks, this function runs.
howMany is how many items were broke (in the case of a stack of items, several items can possibly be broken with a single, powerful hit)
bLastBroke will be true if the last item in the stack was broken (and therefore, the whole item stack is about to be removed)
who is the entity or player who broke the items.
]]--
function ITEM:OnBreak(howMany,bLastBroke,who)
	if !bLastBroke then return false end
	
	local ent=self:GetEntity();
	if !ent then return false end
	
	breakEnt=ents.Create("prop_physics");
	breakEnt:SetModel(ent:GetModel());
	breakEnt:SetPos(ent:GetPos());
	breakEnt:SetAngles(ent:GetAngles());
	breakEnt:SetNotSolid(true);
	
	local phys1=ent:GetPhysicsObject();
	local phys2=breakEnt:GetPhysicsObject();
	
	if phys1 && phys1:IsValid() && phys2 && phys2:IsValid() then
		phys2:SetVelocity(phys1:GetVelocity());
		phys2:AddAngleVelocity(phys1:GetAngleVelocity());
	end
	breakEnt:Spawn();
	breakEnt:Fire("break","",0);
end

--[[
This event is called when a full update of this item is being sent to a player.
pl may be nil - if it is, it's sending the update to everyone.
]]--
function ITEM:OnSendFullUpdate(pl)
	
end

--[[
This is run when you hold the item as a weapon.
Can the item be held as a weapon? If this returns false, attempts to hold the item will fail.

pl is the player who wants to hold the item
Return true to allow the item to be held, or false to stop any attempts to hold.
]]--
function ITEM:OnHold(pl)
	return true;
end

--[[
This is run when you release the item. 
pl is the player who is currently holding the item.
forced is a true/false indicating whether or not we can stop the item from being released.
	If forced is true, returning false in this event will not stop the item from being released.
	forced will be true if the release has to happen. A couple of cases that this apply are death of a player or removal of the item.
Return false to prevent from releasing.
]]--
function ITEM:OnRelease(pl,forced)
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

Returning true will allow the item to be placed in and/or removed from an inventory with the given slot.
Returning false will stop the item from moving from inventory to inventory / slot to slot.

If forced is true (usually due to forced removal from an inventory because the item is being removed), then returning false will not stop the item from being moved.
TODO this event needs to be called in more places, and PROPERLY for that matter
]]--
function ITEM:OnMove(OldInv,OldSlot,NewInv,NewSlot,forced)
	--If we're moving the item to an inventory
	if NewInv then return true end
	
	return true;
end

--[[
This function is called when the item is trying to enter the world.
Can the item be placed in the world as an entity? If this returns false, attempts to place the item in the world will fail.

vPos is the position it's trying to be inserted at.
aAng is the angle it's trying to be inserted at.

Return false to stop the item from entering the world, or return true to allow it to enter the world.
]]--
function ITEM:OnWorldEntry(vPos,aAng)
	return true;
end

--[[
This function is called when the item is trying to leaving the world.
ent is the item's world entity. It should be the same as self.Entity.
forced is true if the removal of the item from the world is being forced (with good reason usually, such as the item itself being removed) - in the case that it is, the removal cannot be stopped by returning false here.

Return false to stop the item from leaving the world, or return true to allow it to enter the world.
]]--
function ITEM:OnWorldExit(ent,forced)
	if !forced && ent:IsConstrained() then return false end
	return true;
end

--This function is run periodically. You can set how often it runs by setting the think rate at the top of the script, or with self:SetThinkRate(). You need to tell the item to self:StartThink() to start the item thinking.
function ITEM:OnThink()
	
end

--[[
Before items are combined to create something, this function is run. You can return false to stop the combination from happening. Note: The combination has to work (ex: combining a branch and a stone). Non working combinations (ex: a bottle and a vine) will not trigger this.
The order this goes in is: (Are there any combinations for these items?) > (Have necessary # of ingredients?) > (Does the combination okay it?) > (does each item in the combination okay it?)
So, this function is called last. All of the items in the combination must return true for it to work.
Itemset is a table of all the items (including this item)
TODO Item combinations module
]]--
function ITEM:OnCombination(itemset,combination)
	return true;
end

--[[
This runs when this stack of items tries to merge with another stack of items. You can return false to stop the merge from happening.
]]--
function ITEM:OnMerge(otherItem)
	return true;
end

--[[
This is called when two items of the same type bump into each other in the world.
If this item is in the world (as an ent), and another item of the same type bumps into it, should the two items merge into a stack?
	Ex: You have a sheet of paper. Another sheet of paper falls on top of it.
	Should the two sheets of paper remain seperate, or should they form a stack of 2 papers?

This event can decide whether or not this item can be merged with other items in the world.
Note that if OnMerge returns false, it stops all merges.

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
Note that if OnMerge returns false, it stops all merges.

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
Note that if OnMerge returns false, it stops all merges.

otherItem is the other item that this item is attempting to merge with.
player is the player currently holding an item that is going to be merged.

Return true to allow the item to merge together as a single stack held by the player,
or false to keep the items stacks seperate (which will stop the item from being held)
]]--
function ITEM:CanHoldMerge(otherItem,player)
	return true;
end

--[[
This runs when this stack of items is split into another stack of items.
You can return false to stop the split from happening.
]]--
function ITEM:OnSplit(howMany)
	return true;
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

--This runs when a networked var is set on this item (with SetNW*).
function ITEM:OnSetNWVar(sName,vVal)
	return true;
end