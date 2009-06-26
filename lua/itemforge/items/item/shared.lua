--[[
item
SHARED

item is the default item. All items except item inherit from this item-type.
NOTE: The item type is the name of the folder it is in (this is item/shared.lua, so this item's type is "item")
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
ITEM.Name="Default Item Name";						--An item's name is displayed by the UI in several different locations, such as the weapon selection menu (when the item is held), or displayed when selected in an inventory.
ITEM.Description="This is the default description.";--An item's description gives additional details about the item. One place it is displayed is in the inventory when selected.
ITEM.Base=nil;										--The item is based off of this kind of item. Set this to nil if it's not based off of an item. Set it to the type of another item (ex: ITEM.Base="hammer") to base it off of that. (NOTE: This is useful for tools. For example: If you have an item called "Hammer" that "Stone Hammer" and "Iron Hammer" are based off of, and you have a combination that takes "Hammer" as one of it's ingredients, both the "Stone Hammer" and "Iron Hammer" can be used!)
ITEM.WorldModel="models/dav0r/buttons/button.mdl";	--When dropped on the ground, held by a player, or viewed on some places on the UI (like an inventory icon), the world model is the model displayed.
ITEM.ViewModel="models/weapons/v_pistol.mdl";		--When held by a player, the player holding it sees this model in first-person.
ITEM.Size=1;										--Default size of a single item in this stack. Size has nothing to do with how big the item looks or how much it weighs. Instead, size determines if an item can be placed in an inventory or not. In my opinion, a good size can be determined if you put the item into the world and get the entity's bounding sphere size.
ITEM.Color=Color(255,255,255,255);					--Default color of this item's model and icon. Can be changed.

--Restrictions on who can spawn
ITEM.Spawnable=false;								--Can this item be spawned by any player via the spawn menu on the items tab?
ITEM.AdminSpawnable=false;							--Can this item be spawned by an admin via the spawn menu on the items tab?

--SWEP related
ITEM.PrimaryAuto=false;								--If this item is held as a weapon, is it's primary fire automatic? Or, in other words, do I have to keep clicking to attack?
ITEM.SecondaryAuto=false;							--If this item is held as a weapon, is it's secondary fire automatic? Or, in other words, do I have to keep right-clicking to attack?

--Don't modify/override these. They're either set automatically, don't need to be changed, or are listed here so I can keep track of them.
--Belongs to item-type
ITEM.Type="";				--The item-type. This is the same as the name of the folder these files are in. This is set automatically when loading item-types.
ITEM.BaseClass=nil;			--Set to the Item-Type that ITEM.Base identifies after loading all item-types
ITEM.NWCommandsByName=nil;	--Networked commands are stored here. The key is the name, value is the command. These trigger networked hooks on the other side (Client to Server or Server to Client).
ITEM.NWCommandsByID=nil;	--Networked commands are stored here. The key is the id, value is the command. These trigger networked hooks on the other side (Client to Server or Server to Client).

--Belongs to individual items
ITEM.ID=0;					--Item ID. Assigned automatically.
ITEM.Container=nil;			--If the item is in an inventory, this is the inventory it is in.			Use self:GetContainer() to grab.
ITEM.Entity=nil;			--If the item is on the ground, this is the SENT that represents the item.	Use self:GetEntity() to grab this.
ITEM.Weapon=nil;			--If the item is being held by a player, this is the SWEP entity.			Use self:GetWeapon() to grab this.
ITEM.Owner=nil;				--If the item is being held, this is the player holding it.					Use self:GetWOwner() to grab this. (NOTE: GetNetOwner() does not return this).
ITEM.BeingRemoved=false;	--This will be true if the item is being removed.
ITEM.Inventories=nil;		--Inventories connected to this item are stored here. The item 'has' these inventories (a backpack or a crate would store it's inventory here, for example). The key is the inventory's ID. The value is the actual inventory.

--[[
DEFAULT METHODS
DO NOT OVERRIDE
IN THIS SCRIPT
OR OTHER SCRIPTS
]]--



--[[
Removes the item.
]]--
function ITEM:Remove()
	return IF.Items:Remove(self);
end
IF.Items:ProtectKey("Remove");

--[[
This function can determine if this item is based off of the given type in any way.
	For example, lets say we have three item types: base_weapon, base_melee, and item_sword.
	item_sword inherits from base_melee. base_melee inherits from base_weapon.
	Lets say we have a weapons salesman who will only buy weapons.
	We could check that the item we're trying to sell him is a weapon by doing mySword:InheritsFrom("base_weapon").
	It would return true, because a sword is a melee weapon, and a melee weapon is a weapon.
This includes if the item _IS_ what you're checking to see if it's based off of.
	Example: Checking to see if an item_egg is based off of an item_egg.
sType is the name of the itemtype ("item", "base_container", etc.)
This function returns true if the item inherits from this item type, or false if it doesn't.
]]--
function ITEM:InheritsFrom(sType)
	if self:GetType()==string.lower(sType) then
		return true;
	elseif self.BaseClass then
		return self.BaseClass:InheritsFrom(sType);
	end
	return false;
end
IF.Items:ProtectKey("InheritsFrom");

--[[
Sets the size of every item in the stack.
Size has nothing to do with weight or how big the item looks.
The only thing size determines is if an item can be placed inside of an inventory that has a size limit.
]]--
function ITEM:SetSize(size)
	return self:SetNWInt("Size",size);
end
IF.Items:ProtectKey("SetSize");

--[[
This sets the model color/icon color of this item.
]]--
function ITEM:SetColor(cCol)
	self:SetNWColor("Color",cCol);
end
IF.Items:ProtectKey("SetColor");








--[[
Returns the itemtype of this item
For example "item", "item_crowbar", etc...
]]--
function ITEM:GetType()
	return self.Type;
end
IF.Items:ProtectKey("GetType");

--Returns the item/stack's ID.
function ITEM:GetID()
	return self.ID;
end
IF.Items:ProtectKey("GetID");

--Get the size of an item in the stack (they all are the same size).
function ITEM:GetSize()
	return self:GetNWInt("Size");
end
IF.Items:ProtectKey("GetSize");

--[[
Returns the world model.
]]--
function ITEM:GetWorldModel()
	return self:GetNWString("WorldModel");
end
IF.Items:ProtectKey("GetWorldModel");

--[[
Returns the view model.
]]--
function ITEM:GetViewModel()
	return self:GetNWString("ViewModel");
end
IF.Items:ProtectKey("GetViewModel");

--[[
This returns the current model color/icon color of this item.
]]--
function ITEM:GetColor()
	return self:GetNWColor("Color");
end
IF.Items:ProtectKey("GetColor");

--[[
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
	if inv!=nil then
		return inv:GetOwner();
	end
	return nil;
end
IF.Items:ProtectKey("GetOwner");

--[[
If the item is in the world, returns the item's world entity.
If the item is held by a player, in an inventory, or in the void, this function returns nil.
Doing :IsValid() on an entity returned from here is not necessary; if this function returns an entity, it is always valid.
]]--
function ITEM:GetEntity()
	if self.Entity && !self.Entity:IsValid() then
		self.Entity=nil;
	end
	return self.Entity;
end
IF.Items:ProtectKey("GetEntity");

--[[
If the item is being held, returns it's weapon.
If the item is in the world, in an inventory, or in the void, this function returns nil.
Doing :IsValid() on a weapon returned from here is not necessary; if this function returns a weapon, it is always valid.
]]--
function ITEM:GetWeapon()
	if self.Weapon && !self.Weapon:IsValid() then
		self.Weapon=nil;
	end
	return self.Weapon;
end
IF.Items:ProtectKey("GetWeapon");

--[[
Returns the player who is holding this item as a weapon (the Weapon Owner; this is equivilent to self.Owner in an SWEP).
If the item has been put into an SWEP, but no player is holding it yet, nil is returned (this occasionally happens).
If the item isn't being held as a weapon, this returns nil.
]]--
function ITEM:GetWOwner()
	if self.Owner && !self.Owner:IsValid() then
		self.Owner=nil;
	end
	return self.Owner;
end
IF.Items:ProtectKey("GetWOwner");

--[[
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
		if !p then ErrorNoHalt("Itemforge Items: ERROR! GetPos failed on "..tostring(self)..". This item is being held, but player holding this item is no longer valid.\n"); return nil end
		return p:GetShootPos();
	elseif self:InInventory() then
		local container=self:GetContainer();
		return container:GetPos();
	end
	
	return nil;
end
IF.Items:ProtectKey("GetPos");

--[[
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
			ErrorNoHalt("Itemforge Items: ERROR! InInventory() failed on "..tostring(self)..". Inventory given is non-existent or has been removed. Check to see if the inventory is valid before passing it.\n");
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

--Returns true if the item is in the world
function ITEM:InWorld()
	local ent=self:GetEntity();
	if ent then return true; end
	return false;
end
IF.Items:ProtectKey("InWorld");

--[[
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
			if !byPlayer:IsValid() then ErrorNoHalt("Itemforge Items: ERROR! IsHeld failed on "..tostring(self)..". Given player is non-existent or has been removed.\n"); return false end
			if !byPlayer:IsPlayer() then ErrorNoHalt("Itemforge Items: ERROR! IsHeld failed on "..tostring(self)..". Given player is not a player!\n"); return false end
			
			--Check to see if the player holding this is still valid
			local p=self:GetWOwner();
			if !p then ErrorNoHalt("Itemforge Items: ERROR! IsHeld failed on "..tostring(self)..". This item is held, but the player holding this item cannot be determined.\n"); return false end
			
			--If this item isn't being held by the given player return false. (if it is being held by this player, true is returned beneath this check)
			if p!=byPlayer then return false end
		end
		
		return true;
	end
	return false;
end
IF.Items:ProtectKey("IsHeld");

--Returns true if the item is not held, in the world, or in an inventory
function ITEM:InVoid()
	if !self:GetEntity() && !self:GetWeapon() && !self:GetContainer() then
		return true;
	end
	return false;
end
IF.Items:ProtectKey("InVoid");

--Run this to start the item's Think event. Think is off by default.
function ITEM:StartThink()
	timer.Create("if_itemthink_"..self:GetID(),self.ThinkRate,0,self.OnThink,self);
end
IF.Items:ProtectKey("StartThink");

--[[
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

--Run this to stop the item's Think event. Think is off by default.
function ITEM:StopThink()
	local n="if_itemthink_"..self:GetID();
	if timer.IsTimer(n) then timer.Remove(n) end
end
IF.Items:ProtectKey("StopThink");




--[[
INTERNAL METHODS
DO NOT OVERRIDE IN THIS SCRIPT OR OTHER SCRIPTS
These functions are called internally by Itemforge. There should be no reason for a scripter to call these.
]]--




--[[
This is called when the item is created. This is NOT called when the item is placed into the world.
This function will call the item's OnInit event.

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:Initialize(owner)
	local s,r=pcall(self.OnInit,self,owner);
	if !s then ErrorNoHalt(r.."\n") end
	
	return true;
end
IF.Items:ProtectKey("Initialize");

--[[
Sets the item's entity. Whenever an item is in the world, a SENT is created.
We need to link this SENT with the item, so the item can refer to it later.
ent must be a valid "itemforge_item" entity, or this function will fail. If for some reason a different SENT needs to be used, I'll consider allowing different SENTS to be used.

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:SetEntity(ent)
	if !ent || !ent:IsValid() then ErrorNoHalt("Itemforge Items: Couldn't set entity on "..tostring(self).."! Given entity was not valid!\n"); return false end
	if ent:GetClass()!="itemforge_item" then ErrorNoHalt("Itemforge Items: Couldn't set entity on "..tostring(self).."! Given entity was not an itemforge_item!\n"); return false end
	
	self.Entity=ent;
	return true;
end
IF.Items:ProtectKey("SetEntity");

--[[
Clears the item's entity.

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:ClearEntity()
	self.Entity=nil;
end
IF.Items:ProtectKey("ClearEntity");

--[[
Sets this item's weapon. Whenever an item is held, an SWEP is created.
We need to link this SWEP with the item, so the item can refer to it later.
ent must be a valid itemforge_item_held_* entity, or this function will fail. If for some reason a different SWEP needs to be used, I'll consider allowing different SWEPs to be used.

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:SetWeapon(ent)
	if !ent || !ent:IsValid() then ErrorNoHalt("Itemforge Items: Couldn't set weapon on "..tostring(self).."! Given entity was not valid!\n"); return false end
	if !IF.Items:IsWeaponItem(ent) then ErrorNoHalt("Itemforge Items: Couldn't set weapon on "..tostring(self).."! Given entity was not an itemforge_item_held!\n"); return false end
	
	self.Weapon=ent;
	return true;
end
IF.Items:ProtectKey("SetWeapon")

--[[
Sets this item's owner. Whenever an item is held, an SWEP is created.
We need to record what player is holding this SWEP so the item can refer to him later.
pl must be a valid player or this function will fail.

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:SetWOwner(pl)
	if !pl || !pl:IsValid() then ErrorNoHalt("Itemforge Items: Couldn't set weapon owner on "..tostring(self).."! Given player was not valid!\n"); return false end
	if !pl:IsPlayer() then ErrorNoHalt("Itemforge Items: Couldn't set weapon owner on "..tostring(self).."! Given player was not a player!\n"); return false end

	self.Owner=pl;
	return true;
end
IF.Items:ProtectKey("SetWOwner")

--[[
Clears this item's weapon and weapon owner.
If ent is given, ent must match this item's set weapon.
	This is just in case the wrong weapon is cleared because of some strange happening.
If ent isn't given, then we'll just clear the weapon regardless of what is it.

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:ClearWeapon()
	self.Weapon=nil;
	self.Owner=nil;
	return true;
end
IF.Items:ProtectKey("ClearWeapon");

--[[
Sets the item's container (inventory that this item is inside of).

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:SetContainer(inv)
	self.Container=inv;
	return true;
end
IF.Items:ProtectKey("SetContainer");

--[[
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
Adds an inventory to this item's list of connected inventories.
Connect an inventory with inv:ConnectItem(item), not this function
true is returned if successful, false otherwise

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:ConnectInventory(inv,conslot)
	if !inv || !inv:IsValid() then ErrorNoHalt("Itemforge Items: Couldn't connect "..tostring(self).." to given inventory. The inventory given was invalid.\n"); return false end
	if !conslot then ErrorNoHalt("Itemforge Items: Couldn't connect "..tostring(self).." to given inventory. conslot wasn't given.\n"); return false end
	
	--Create inventories collection if we haven't yet
	if !self.Inventories then self.Inventories={}; end
	
	local newRecord={};
	newRecord.Inv=inv;
	newRecord.ConnectionSlot=conslot;
	
	self.Inventories[inv:GetID()]=newRecord;
	
	--We have events that detect connections of inventories both serverside and clientside
	local s,r=pcall(self.OnConnectInventory,self,inv,conslot);
	if !s then ErrorNoHalt(r.."\n") end
	
	return true;
end
IF.Items:ProtectKey("ConnectInventory");

--[[
Removes a connected inventory from this item's list of connected inventories.
Sever an inventory with inv:SeverItem(item), not this function

This function is called internally by Itemforge. There should be no reason for a scripter to call this.
]]--
function ITEM:SeverInventory(inv)
	if !inv || !inv:IsValid() then ErrorNoHalt("Itemforge Items: Couldn't sever "..tostring(self).." from given inventory. The inventory given was invalid.\n"); return false end

	if !self.Inventories || !self.Inventories[inv:GetID()] then ErrorNoHalt("Itemforge Items: Couldn't sever "..tostring(self).." from inventory "..inv:GetID()..". The inventory is not listed as connected on the item.\n"); return false end
	self.Inventories[inv:GetID()]=nil;
	
	--We have events that detect severing of inventories both serverside and clientside
	local s,r=pcall(self.OnSeverInventory,self,inv);
	if !s then ErrorNoHalt(r.."\n") end
	
	return true;
end
IF.Items:ProtectKey("SeverInventory");

function ITEM:GetInventoryConnectionSlot(invid)
	if !invid then ErrorNoHalt("Itemforge Items: Couldn't grab connection slot that item "..tostring(self).." is occupying on an inventory. The inventory ID wasn't given.\n"); return false end
	if !self.Inventories || !self.Inventories[invid] then ErrorNoHalt("Itemforge Items: Couldn't grab connection slot that item "..tostring(self).." is occupying on an inventory. This inventory isn't connected to this item.\n"); return false end
	return self.Inventories[invid].ConnectionSlot;
end
IF.Items:ProtectKey("GetInventoryConnectionSlot");