--[[
Itemforge Inventory Module
SHARED

This implements inventories. It keeps track of inventories and syncs them.
TODO turn ifs into elseifs in respect to player validation
TODO allow inventories to reuse IDs like items
TODO allow inventories to have "soft weight caps" like fallout 3 (weight cap can be set and exceeded)
TODO when sending updates about connected items/entities check that they are still valid (I bound an inventory to a bot and after kicking him, had a null player bound to the inventory)
]]--

MODULE.Name						= "Inv";					--Our module will be stored at IF.Inv
MODULE.Disabled					= false;					--Our module will be loaded
MODULE.MaxInventories			= 65535;					--How many unique inventories can exist at a single time?

if CLIENT then

MODULE.FullUpInProgress			= false;					--If this is true a full update is being recieved from the server
MODULE.FullUpTarget				= 0;						--Whenever a full update starts, this is how many inventories need to be sent from the server.
MODULE.FullUpCount				= 0;						--Every time an inventory is created while a full update is being recieved, this number is increased by 1.
MODULE.FullUpInventoriesUpdated	= {};						--Every time an inventory is created while a full update is being recieved, FullUpInventoriesUpdated[Inventory ID] is set to true.

end

--These are local on purpose. I'd like people to use the Get function, and not grab the inventories directly from the table.
local BaseType					= "base_inv";				--This is the undisputed absolute base inventory-type. All inventories inherit from this type of inventory.
local InvTypes					= {};						--Registered inventory types are stored here.
local InventoryRefs				= {};						--Inventory references. One for every inventory. Allows us to pass this instead of the actual inventory. We can garbage collect removed inventories, giving some memory back to the game, while at the same time alerting scripters of careless mistakes (referencing an item after it's been removed)
local NextInventory				= 1;						--This is a pointer of types, that records where the next inventory will be made. IDs are assigned based on this number. This only serves as a starting point to search for a free ID. If this slot is taken then it will search through the entire inventory array once to look for a free slot.

--Methods and default values for all inventories are stored here.
local _INV = {};

--Itemforge Inventory (IFINV) Message (-128 to 127. Uses char in usermessage)
IFINV_MSG_CREATE				=	-128;					--(Server > Client) Sync create inventory clientside
IFINV_MSG_REMOVE				=	-127;					--(Server > Client) Sync remove inventory clientside
IFINV_MSG_REQFULLUP				=	-126;					--(Client > Server) Client requests full update of an inventory
IFINV_MSG_REQFULLUPALL			=	-125;					--(Client > Server) Client requests full update of all inventories (joining player)
IFINV_MSG_STARTFULLUPALL		=	-124;					--(Server > Client) This message tells the client that a full update of all inventories is going to being sent and how many to expect.
IFINV_MSG_ENDFULLUPALL			=	-123;					--(Server > Client) This message tells the client the full update of all inventories has finished.
IFINV_MSG_INVFULLUP				=	-122;					--(Server > Client) A full update on an inventory is being sent. This sends basic data about the inventory.
IFINV_MSG_WEIGHTCAP				=	-121;					--(Server > Client) The weight capacity of the inventory has changed serverside. Sync to client.
IFINV_MSG_SIZELIMIT				=	-120;					--(Server > Client) The size limit of the inventory has changed serverside. Sync to client.
IFINV_MSG_MAXSLOTS				=	-119;					--(Server > Client) The max number of slots was changed. Sync to client.
IFINV_MSG_CONNECTITEM			=	-118;					--(Server > Client) The inventory has connected itself with an item. Have client connect too.
IFINV_MSG_CONNECTENTITY			=	-117;					--(Server > Client) The inventory has connected itself with an entity. Have client connect too.
IFINV_MSG_SEVERITEM				=	-116;					--(Server > Client) The inventory is severing itself from an item. Have client sever as well.
IFINV_MSG_SEVERENTITY			=	-115;					--(Server > Client) The inventory is severing itself from an entity. Have client sever too.
IFINV_MSG_LOCK					=	-114;					--(Server > Client) The inventory has been locked serverside. Have client lock too.
IFINV_MSG_UNLOCK				=	-113;					--(Server > Client) The inventory has been unlocked serverside. Have client unlock too.

--Itemforge Inventory (IFINV) Connection Type.
IFINV_CONTYPE_ITEM				=	1;						--Inventory connected to an item.
IFINV_CONTYPE_ENT				=	2;						--Inventory connected to an entity.

--Itemforge Inventory Removal Actions... when an inventory is removed, the items should be:
IFINV_RMVACT_REMOVEITEMS		=	1;						--Removed along with the inventory
IFINV_RMVACT_VOIDITEMS			=	2;						--Voided (just take them out of the inventory and leave them in the void)
IFINV_RMVACT_SAMELOCATION		=	3;						--Sent to the same location as the item/entity this inventory was attached to before it was removed (in the case of multiple attachments at the time of removal, sends them to the same location as the first available connected object)



--[[
* SHARED

Initilize Inventories module.
We need to register the base inventory type here.
]]--
function MODULE:Initialize()
	self:RegisterType( _INV, BaseType );
end

--[[
* SHARED

Clean up the inventory module.
Removes all inventories.

Currently I have this done prior to a refresh. It will remove any inventories.
]]--
function MODULE:Cleanup()
	for k, v in pairs( InventoryRefs ) do
		v:Remove();
	end

	Templates		= nil;
	Inventories		= nil;
	InventoryRefs	= nil;
	InventoryCount	= nil;
end

--[[
* SHARED

This function registers an inventory type.
This should be done at initialization.

tClass should be a table defining the inventory type.
	TODO better description here
	See _INV towards the bottom of this file for an idea of what a table like this would look like.

strName is a name to identify the inventory type by, such as "inv_bucket". This name will be used for two things:
	When creating an inventory, the name of an inventory type can be given to make an inventory.
	Allowing one class to inherit from another.

true is returned if the type is registered, and false otherwise.
]]--
function MODULE:RegisterType( tClass, strName )
	if !IF.Util:IsString( strName )	then ErrorNoHalt( "Itemforge Inventory: Couldn't register inventory type - type to register wasn't given / wasn't a string.\n" );	return false end
	if !tClass						then ErrorNoHalt( "Itemforge Inventory: Couldn't register inventory type \""..strName.."\" - name of type wasn't given!\n" );		return false end
	
	strName = string.lower( strName );
	if tClass.Base == nil then tClass.Base = BaseType; end
	
	tClass = IF.Base:RegisterClass( tClass, strName );
	if !tClass then return false end
	
	InvTypes[strName] = tClass;
	
	return true;
end

--[[
* SHARED

Returns the inventory type by name strName.

NOTE: If your inventory is based off of another inventory, you can access it's type by doing self["base_class"] (where self is your inventory,
	  and base_class is whatever it's based off of, like inv_rockit, base_inventory, whatever).
	  Don't modify the inventory-types. If you do, every currently spawned inventory with that inventory-type may change.

strName should be the name of the inventory type to get.

If the inventory type exists, returns it.
Otherwise, returns nil.
]]--
function MODULE:GetType( strName )
	if !IF.Util:IsString( strName ) then ErrorNoHalt( "Itemforge Inventory: Couldn't grab inventory type - name of type wasn't given!\n" ); return false end
	
	return InvTypes[ string.lower( strName ) ];
end

--[[
* SHARED

Searches the Inventories[] table for an empty slot.

This function will keep searching until:
	It finds an open slot.
	It has gone through the entire table once.

iFrom is an optional number describing where to start searching in the table.
	If this number is not given, is over the max number of inventories, or is under 1, it will be set to 1.

The index of an empty slot is returned if one is found,
or nil is returned if one couldn't be found.

TODO I'm not satisfied with the way this function works; consider reworking it sometime
]]--
function MODULE:FindEmptySlot( iFrom )
	--Wrap around to 1 if iFrom wasn't a number, was under zero, or was over the inventory limit
	if !IF.Util:IsNumber( iFrom ) || !IF.Util:IsInRange( iFrom, 1, self.MaxInventories ) then iFrom = 1; end
	
	local count = 0;
	while count < self.MaxInventories do
		if InventoryRefs[iFrom] == nil then return iFrom end
		count = count + 1;
		iFrom = iFrom + 1;
		if iFrom > self.MaxInventories then iFrom = 1 end
	end
	return nil;
end

--[[
* SHARED

Create an inventory of this type.
This should only be called on the server by a scripter.

Once the inventory is created, it will be floating around in the void (it has no presence in the game world; the inventory does not "belong" to anything)
You'll have to connect it to an entity or item, or simply leave it in the void.
I personally suggest doing one of the first three. Inventories in the void aren't really useful for much (players can't interact with them).

TODO CreateInventoryForItem, CreateInventoryForEntity

strType is an optional string, the name of type of inventory you want to create.
	If this is given, the new inventory will be the given type (e.g. "inv_bucket"). Inventory types are registered with IF.Inv:RegisterType().
	If no inventory type is given, the default inventory type is used instead.
plOwner is an optional player that is only used serverside.
	Giving a plOwner for an inventory tells Itemforge that this inventory and any updates regarding it should only sent to a given player.
	This is useful if you want to create a private inventory for a player.
	Keeping an inventory private means other players have no way of knowing what an inventory is carrying at any given time, clientside at least.
	All inventories exist serverside.
	If no plOwner is given (or plOwner is nil) then the inventory is public.
id is only required when creating inventories clientside.
	This is the inventory id to give the created inventory.
fullUpd is only used on the client.
	This will be true only if creating the inventory is part of a full update.
bPredict is an optional true/false that defaults to false on the server, and true on the client. If bPredict is:
	false, then if successful we'll register and return a new inventory. nil will be returned if unsuccessful for any reason.
	true, then if we determine the inventory can be created, a temporary inventory that can be used for further prediction tests will be returned. nil will be returned otherwise.
]]--
function MODULE:Create( strType, plOwner, id, fullUpd, bPredict )
	--If we're given an owner we need to validate it
	if !IF.Util:IsPlayer( plOwner ) then plOwner = nil end
	
	if !IF.Util:IsString( strType ) then	strType = BaseType;
	else									strType = string.lower( strType ); end
	
	if !IF.Base:ClassExists( strType ) then
		ErrorNoHalt( "Itemforge Inventory: Couldn't create inventory. \""..strType.."\" is not a registered inventory-type.\n" );
		return nil;
	elseif InvTypes[strType] == nil then
		ErrorNoHalt( "Itemforge Inventory: Couldn't create inventory. \""..strType.."\" is a registered class, but is not an inventory-type. Naming conflicts can cause this error.\n" );
		return nil;
	end
	
	if bPredict == nil then bPredict = CLIENT end
	
	--[[
	We need to find an ID for the soon-to-be created inventory.
	We'll either use an ID that is not in use at the moment, which is usually influenced by the number of inventories created so far
	or a requested ID likely sent from the server
	]]--
	local n;
	if SERVER || ( bPredict && !id ) then
		n = NextInventory;
		
		if InventoryRefs[n] != nil then
			n = self:FindEmptySlot( n + 1 );
			
			if n == nil then
				if !bPredict then ErrorNoHalt( "Itemforge Inventory: Couldn't create inventory - no free slots (all "..self.MaxInventories.." slots occupied)!\n" ); end
				return nil;
			end
		end
		
		if !bPredict then
			NextInventory = n + 1;
			if NextInventory > self.MaxInventories then NextInventory = 1 end
		end
	else
		if id == nil then ErrorNoHalt( "Itemforge Inventory: Could not create inventory clientside, the ID of the inventory to be created wasn't given!\n" ); return nil end
		n = id;
	end
	
	--[[
	When a full update on an inventory is being performed, Create is called before updating it.
	That way if the inventory doesn't exist it's created in time for the update.
	We only need to keep track of the number of inventories updated when all inventories are being updated.
	]]--
	if CLIENT && fullUpd == true && self.FullUpInProgress == true && !bPredict then
		self.FullUpCount = self.FullUpCount + 1;
		self.FullUpInventoriesUpdated[n] = true;
	end
	
	--Does the inventory exist already? No need to recreate it.
	--TODO possible bug here; what if a dead inventory clientside blocks new inventories with the same ID from being created?
	if InventoryRefs[n] then
		--We only need to bitch about this on the server. Full updates of an inventory clientside will tell the inventory to be created regardless of whether it exists or not. If it exists clientside we'll just ignore it.
		if SERVER && !bPredict then
			ErrorNoHalt( "Itemforge Inventory: Could not create inventory with id "..n..". An inventory with this ID already exists!\n" );
		end
		return nil;
	end
	
	if bPredict then n = 0 end
	
	local newInv = IF.Base:CreateObject( strType );
	if newInv == nil then return nil end
	
	newInv.ID = n;
	
	if !bPredict then
		if SERVER then newInv.Owner = plOwner; end

		InventoryRefs[n] = newInv;
		
		--TODO predicted inventories need to initialize too but not do any networking shit
		newInv:Initialize( plOwner );
		
		--We'll tell the clients to create and initialize the inventory too. If a plOwner was given to send inventory updates to exclusively, the inventory will only be created clientside on that player.
		if SERVER then self:CreateClientside( newInv, plOwner ) end
	end
	
	return newInv;
end

--[[
* SHARED

This will remove an existing inventory from the inventories collection.
inventory:Remove() calls this.

When this function is run, the OnRemove() hook on the inventory is triggered.

inv should be an existing inventory.
lastConnection is the last connection this inventory had to an item or entity.
	It's a table, with two members, .Type and .Obj.
		Type will be IFINV_CONTYPE_ITEM or IFINV_CONTYPE_ENT.
		Obj will be the entity or item the inventory was connected to.

true is returned if the inventory was successfully removed.
false is returned if the inventory is in the process of being removed.
]]--
function MODULE:Remove( inv, lastConnection )
	if !inv || !inv:IsValid()	then ErrorNoHalt( "Itemforge Inventory: Could not remove inventory - inventory doesn't exist!\n" ); return false end
	if inv.BeingRemoved			then return false;
	else						inv.BeingRemoved = true;
	end
	
	inv:Event( "OnRemove", nil, lastConnection );
	
	--[[
	Sever any connections to items or entities
	We sever them in this function rather than independently, saves bandwidth
	There's different serverside and clientside behavior for the sever functions.
	]]--
	for k, v in pairs( inv.ConnectedObjects ) do
		if v.Type		== IFINV_CONTYPE_ITEM	then inv:SeverItem( k, SERVER );
		elseif v.Type	== IFINV_CONTYPE_ENT	then inv:SeverEntity( k, SERVER );
		end
	end
		
	--Unregister any observers
	if CLIENT then inv:UnregisterAllObservers(); end
	
	--Remove the inventory from our collections.
	local id = inv:GetID();
	
	--[[
	Tell ALL clients to remove too
	Even if an inventory is private, it can change owners.
	It might have been public and then went private.
	To make sure the inventory is absolutely removed on all clients, we tell all clients to remove it.
	]]--
	if SERVER then self:RemoveClientside( id, nil ); end
	
	InventoryRefs[id] = nil;
end

--[[
* SHARED

This returns a reference to an inventory with the given ID.
For all effective purposes this is the same thing as returning the actual inventory,
except it doesn't hinder garbage collection,
and helps by warning the scripter of careless mistakes (still referencing an inventory after it's been deleted).

id should be the ID of the inventory to get.

This returns an inventory reference (a table) if successful,
or nil if there is no inventory with that ID.
]]--
function MODULE:Get( id )
	return InventoryRefs[id];
end

--[[
* SHARED

Returns a table of all inventories currently available to Itemforge.
Please note:
	This function copies the entire table of inventory references every time it is run.
	Do not run it all the time! That lags!
	If this function is run on the client, the client may not have every single inventory the server has,
	because of private inventories and lag. However, serverside this function will always return
	every single inventory, regardless of who owns it.

TODO possibly a more efficient alternative
]]--
function MODULE:GetAll()
	local t = {};

	for k, v in pairs( InventoryRefs ) do
		t[k] = v;
	end

	return t;
end

--[[
* SHARED

This function is used to determine if changing the amount of one or two stacks will break the weight capacity of an inventory.
The reason this function exists is because if the "will weight cap break" calculations are done seperately, this situation can arise:
	There is an inventory with a weight cap of 3000 grams.
	In this inventory, there are two seperate stacks of rocks; each rock in the stack weighs 100 grams.
	One stack has 20 rocks, another has 10 rocks.
	Or to put it another way, one stack weighs 2000 grams, another stack weighs 1000 grams.
	The total weight of these two stacks if 3000 grams (the weight cap of the inventory is maxed out)
	Lets say we want to merge these two piles into a single stack of 30 rocks.
	To do this, we add the second stack's items onto the first stack's items and remove the second stack.
	The merge would fail because we added 10 items onto the first stack before removing the second stack.
	Because the "will weight cap break" calculations were done seperately, it didn't know we were planning to remove the second stack.
	All it sees is that we wanted to have a stack of 30 rocks and a stack of 10 rocks, which would break the weight cap.
	This function solves this situation.

item1 is the first item.
amt1 is the new amount of the first item.
item2 is the second item.
amt2 is the new amount of the second item.

Returns false if no weight caps will break by changing the amounts of the items.
Returns true if any weight cap will break by changing the amounts of the items.
]]--
function MODULE:DoWeightCapsBreak( item1, amt1, item2, amt2 )
	local inv1 = item1 && item1:IsValid() && item1:GetContainer();
	local inv2 = item2 && item2:IsValid() && item2:GetContainer();
	
	--Neither item given is in an inventory (or no valid items were given)
	if !inv1 && !inv2 then
		return false;
	
	--Both items given are in the same inventory
	elseif inv1 == inv2 then
		local cap = inv1:GetWeightCapacity();
		if cap == 0 then return false end
		
		return ( inv1:GetWeightStored() + item1:GetWeight() * ( amt1 - item1:GetAmount() ) + item2:GetWeight() * ( amt2 - item2:GetAmount() ) > cap );

	--Both items are in inventories but not the same inventory
	elseif inv1 && inv2 then
		local cap1 = inv1:GetWeightCapacity();
		local cap2 = inv2:GetWeightCapacity();
		
		return ( cap1 != 0 && inv1:GetWeightStored() + item1:GetWeight() * ( amt1 - item1:GetAmount() ) > cap1 ) ||
			   ( cap2 != 0 && inv2:GetWeightStored() + item2:GetWeight() * ( amt2 - item2:GetAmount() ) > cap2 );
	
	--Only one item given was in an inventory
	else
		--The item we want to deal with is the one that was in an inventory
		local item, amt, inv;
		if		inv1	then	item, amt, inv = item1, amt1, inv1;
		elseif	inv2	then	item, amt, inv = item2, amt2, inv2;
		end
		
		local cap = inv:GetWeightCapacity();
		if cap == 0 then return false end
		
		return ( inv:GetWeightStored() + item:GetWeight() * ( amt - item:GetAmount() ) > cap );
	end
	
	return false;
end

--[[
* SHARED

Returns the name of the base inventory type (the class that all other inventory types are based off of).
]]--
function MODULE:GetBaseInventoryType()
	return BaseType;
end

--TEMPORARY
function MODULE:DumpInventoryRefs()
	dumpTable( InventoryRefs );
end

--TEMPORARY
function MODULE:DumpInventory( id )
	dumpTable( InventoryRefs[id]:GetTable() );
end




--Serverside
if SERVER then




--[[
* SERVER
* Internal

Asks the client to create an inventory clientside.
When the request to create the inventory arrives clientside, if the inventory already exists it is disregarded.

We'll send the owner of the inventory to the client as well.
Even though private inventories are only sent to their owners, this is so the client can identify if the inventory is public or private.

inv is an existing, valid inventory that needs to be created clientside.
pl is an optional argument that defaults to nil.
	If this is nil, every player will receive an instruction to create the inventory.
	If this is a player, only this player will be told to create the inventory.
		In the case of a public inventory, this can be used to send the inventory to a player who needs it (like a connecting player).
		If the inventory is private, pl can only be the owner. It will fail otherwise.
bFullUpd is an optional true/false that defaults to false.
	This should only be true if this item is being created as part of a full update.

true is returned if there are no errors.
false is returned otherwise.
]]--
function MODULE:CreateClientside( inv, pl, bFullUpd )
	if !inv or !inv:IsValid() then ErrorNoHalt( "Itemforge Inventory: Couldn't CreateClientside - Inventory given isn't valid!\n" ); return false end
	
	--Validate player
	if pl != nil then
		if		!IF.Util:IsPlayer( pl )		then ErrorNoHalt( "Itemforge Inventory: Couldn't CreateClientside - The player to send "..tostring( inv ).." to isn't a valid player!\n" );				return false;
		elseif	!inv:CanNetwork( pl )		then ErrorNoHalt( "Itemforge Inventory: Couldn't CreateClientside - Was asked to create "..tostring( inv ).." on a player other than the owner!\n" );	return false;
		end
	else
		return IF.Util:RunForEachPlayer( function( pl ) return self:CreateClientside( inv, pl, bFullUpd ) end );
	end
	
	--DEBUG
	Msg( "OUT: Message Type: "..IFINV_MSG_CREATE.." - Inventory: "..inv:GetID().." - Player: "..tostring( pl ).."\n" );
	
	umsg.Start( "ifinv", pl );
	umsg.Char( IFINV_MSG_CREATE );
	umsg.Short( inv:GetID() - 32768 );
	umsg.String( inv:GetType() );
	umsg.Bool( bFullUpd == true );
	umsg.End();
	
	return true;
end

--[[
* SERVER
* Internal

Asks the client to remove an inventory clientside.

invid is the ID of an inventory that needs to be removed clientside.
	We use invid here instead of inv because the inventory has probably already been removed serverside,
	and we would need to run :GetID() on a non-existent inventory in that case
pl is an optional player that defaults to nil.
	If pl isn't nil, this function will only tell that player to remove the inventory.
	Otherwise, all players are instructed to remove this inventory clientside.
]]--
function MODULE:RemoveClientside( invid, pl )
	if invid == nil then ErrorNoHalt( "Itemforge Inventory: Couldn't RemoveClientside... the inventory ID to remove wasn't given.\n" ); return false end
	
	--Validate player
	if pl != nil then	if !IF.Util:IsPlayer( pl ) then ErrorNoHalt( "Itemforge Inventory: Couldn't RemoveClientside - The player to remove the inventory from isn't a valid player!\n" ); return false; end
	else				return IF.Util:RunForEachPlayer( function( pl ) return self:RemoveClientside( invid, pl ) end );
	end
	
	--DEBUG
	Msg("OUT: Message Type: "..IFINV_MSG_REMOVE.." - Inventory: "..invid.." - Player: "..tostring( pl ).."\n");
	
	umsg.Start( "ifinv", pl );
	umsg.Char( IFINV_MSG_REMOVE );
	umsg.Short( invid - 32768 );
	umsg.End();
	
	return true;
end

--[[
* SERVER
* Internal

Sends a full update on an inventory, as requested by a client usually.
If the inventory doesn't exist serverside then instead of a full update, the client will be told to remove that inventory.
Full updates are bandwidth consuming and should not be used unless necessary.

invid is the ID of the inventory to send an update of.
	We use the ID because, as previously stated, it's possible the inventory doesn't exist on the server.
pl is the player to send the update of the inventory to.

This returns true if successful,
or false if not.
]]--
function MODULE:SendFullUpdate( invid, pl )
	if !invid then ErrorNoHalt( "Itemforge Inventory: Couldn't SendFullUpdate... the inventory ID wasn't given.\n" ); return false end
	
	--Validate player
	if pl != nil then	if !IF.Util:IsPlayer( pl ) then ErrorNoHalt( "Itemforge Inventory: Couldn't SendFullUpdate - The player to send "..tostring( inv ).." to isn't a valid player!\n" ); return false; end
	else				return IF.Util:RunForEachPlayer( function( pl ) return self:SendFullUpdate( invid, pl ) end );
	end
	
	local inv = self:Get( invid );
	--[[
	If the inventory doesn't exist, or if the player we're sending this to isn't the owner,
	we tell the client who requested the update to get rid of it.
	]]--
	if !inv || !inv:CanNetwork( pl ) then return self:RemoveClientside( invid, pl ) end
	
	return ( self:CreateClientside( inv, pl ) && inv:SendFullUpdate( pl ) );
end

--[[
* SERVER
* Internal

Creates all inventories applicable (the inventories that aren't private) as part of a full update to a given player clientside.

To do a full update on all items and inventories properly, all items should be created clientside first,
then all inventories, then full updates of all items, and then full updates of all inventories.

pl is the player to create inventories on clientside.
	This can be a player or nil to send to all players.

true is returned if the inventories were created on the given player, OR if no inventories need to be sent to the player (this happens when there are no inventories, or when there are only private inventories not owned by that player).
false is returned if the inventories could not be created on the given player.

If the given player was nil, this returns false if one of the players couldn't have the inventories sent to him.
]]--
function MODULE:StartFullUpdateAll( pl )
	--Validate player
	if pl != nil then	if !IF.Util:IsPlayer( pl ) then ErrorNoHalt( "Itemforge Inventory: Couldn't StartFullUpdateAll - The player to send inventories to isn't a valid player!\n" ); return false; end
	else				return IF.Util:RunForEachPlayer( function( pl ) return self:StartFullUpdateAll( pl ) end );
	end
	
	local tInvBuffer = {};
	for k, v in pairs( InventoryRefs ) do
		if v:CanNetwork( pl ) then table.insert( tInvBuffer, v ) end
	end
	
	local c = table.getn( tInvBuffer );
	
	if c > 0 then
		--DEBUG
		Msg( "OUT: Message Type: "..IFINV_MSG_STARTFULLUPALL.." - Inventory: "..c.." - Player: "..tostring( pl ).."\n" );
		
		umsg.Start( "ifinv", pl );
		umsg.Char( IFINV_MSG_STARTFULLUPALL );
		umsg.Short( c - 32768 );
		umsg.End();
		
		local bAllCreated = true;
		for i = 1, c do
			if !self:CreateClientside( tInvBuffer[i], pl, true ) then bAllCreated = false end
		end
		return bAllCreated;
	end
	return true;
end

--[[
* SERVER
* Internal

Sends a full update on all inventories applicable (the inventories that aren't private) as part of a full update to a given player clientside.

pl is the player to send full updates for inventories.
	This can be a player or nil to send to all players.

true is returned if full updates for the inventories were sent to the given player, OR if no inventories need to be updated for that player (this happens when there are no inventories, or when there are only private inventories not owned by that player).
false is returned if the full updates for the inventories could not be sent to the given player.

If the given player was nil, this returns false if one of the players couldn't have the inventory updates sent to him.
]]--
function MODULE:EndFullUpdateAll( pl )
	--Validate player
	if pl != nil then	if !IF.Util:IsPlayer( pl ) then ErrorNoHalt( "Itemforge Inventory: Couldn't EndFullUpdateAll - The player to send full updates of all items to isn't a valid player!\n" ); return false; end
	else				return IF.Util:RunForEachPlayer( function( pl ) return self:EndFullUpdateAll( pl ) end );
	end
	
	local c = #InventoryRefs;
	if c > 0 then
		for k, v in pairs( InventoryRefs ) do
			if v:CanNetwork( pl ) then v:SendFullUpdate( pl ); end
		end
		
		--DEBUG
		Msg( "OUT: Message Type: "..IFINV_MSG_ENDFULLUPALL.." - Inventory: 0 - Player: "..tostring( pl ).."\n" );
		
		umsg.Start( "ifinv", pl );
		umsg.Char( IFINV_MSG_ENDFULLUPALL );
		umsg.Short( -32768 );
		umsg.End();
	end
	return true;
end

--[[
* SERVER
* Internal

If a player leaves we need to cleanup private inventories
]]--
function MODULE:CleanupInvs( pl )
	for k, v in pairs( InventoryRefs ) do
		if v:GetOwner() == pl then
			v:SetOwner( nil );
		end
		
		--If the player is a connected object of an inventory...
		for i, c in pairs( v.ConnectedObjects ) do
			if c.Obj == pl then
				v.ConnectedEntityRemoved( pl, v );
			end
		end
		
	end
end

--[[
* SERVER
* Internal

Handles incoming "ifinv" (Itemforge Inventory) messages from the client
]]--
function MODULE:HandleIFINVMessages( pl, command, args )
	if !pl || !pl:IsValid() || !pl:IsPlayer()	then ErrorNoHalt( "Itemforge Inventory: Couldn't handle incoming message from client - Player given doesn't exist or wasn't player!\n" );			return false end
	if !args[1]									then ErrorNoHalt( "Itemforge Inventory: Couldn't handle incoming message from client "..tostring( pl ).." - message type wasn't received.\n" );		return false end
	if !args[2]									then ErrorNoHalt( "Itemforge Inventory: Couldn't handle incoming message from client "..tostring( pl ).." - item ID wasn't received.\n" );			return false end
	
	local msgType = tonumber( args[1] );
	local id = tonumber( args[2] ) + 32768;
	
	--DEBUG
	Msg( "IN:  Message Type: "..msgType.." - Inventory: "..id.." - Player: "..pl:Name().."\n" );
	
	if msgType == IFINV_MSG_REQFULLUP then
		--Send a full update of the inventory to the client.
		self:SendFullUpdate( id, pl );
	elseif msgType == IFINV_MSG_REQFULLUPALL then
		self:StartFullUpdateAll( pl );
		self:EndFullUpdateAll( pl );
	else
		ErrorNoHalt( "Itemforge Inventory: Unhandled IFINV message \""..msgType.."\"\n" );
		return false;
	end
	return true;
end

--We use a proxy here so we can make HandleIFINVMessages a method (:) instead of a regular function (.)
concommand.Add( "ifinv", function( pl, command, args ) return IF.Inv:HandleIFINVMessages( pl, command, args ) end );




--Clientside
else




--[[
* CLIENT
* Internal

Called when a full update has started.

iCount is the number of inventories we're expecting from the server
]]--
function MODULE:OnStartFullUpdateAll( iCount )
	self.FullUpInProgress = true;
	self.FullUpTarget = iCount;
end

--[[
* CLIENT
* Internal

Called when a full update has ended. Did we get them all?
]]--
function MODULE:OnEndFullUpdateAll()
	if self.FullUpCount < self.FullUpTarget then
		ErrorNoHalt( "Itemforge Inventory: Full inventory update only updated "..self.FullUpCount.." out of expected "..self.FullUpTarget.." inventories!\n" );
	end
	
	--Remove non-updated inventories
	for k, v in pairs( InventoryRefs ) do
		if self.FullUpInventoriesUpdated[k] != true then
			--DEBUG
			Msg( "Itemforge Inventory: Removing inventory "..k.." - only exists clientside\n" );
				
			v:Remove();
		end
	end
	
	self.FullUpInProgress = false;
	self.FullUpTarget = 0;
	self.FullUpCount = 0;
	self.FullUpInventoriesUpdated = {};
end

--[[
* CLIENT
* Internal

Handles incoming "ifinv" (Itemforge Inventory) messages from the server
]]--
function MODULE:HandleIFINVMessages( msg )
	--Message type decides what happens next.
	local msgType = msg:ReadChar();
	local id = msg:ReadShort() + 32768;
	
	if msgType == IFINV_MSG_CREATE then
		local type = msg:ReadString();
		local bFullUpRelated = msg:ReadBool();
		
		--Create the inventory clientside too. Use the ID provided by the server.
		self:Create( type, nil, id, bFullUpRelated, false );
	elseif msgType == IFINV_MSG_REMOVE then
		local inv = self:Get( id );
		if !inv then return false end
		
		--Remove the item clientside since it has been removed serverside. TODO, last connected object should be passed
		self:Remove( inv );
	elseif msgType == IFINV_MSG_STARTFULLUPALL then
		self:OnStartFullUpdateAll( id );
	elseif msgType == IFINV_MSG_ENDFULLUPALL then
		self:OnEndFullUpdateAll();
	elseif msgType == IFINV_MSG_INVFULLUP then
		local inv = self:Get( id );
		if !inv then return false end
		
		local iWeightCap = msg:ReadLong() + 2147483648;
		local iSizeLimit = msg:ReadLong() + 2147483648;
		local iMaxSlots = msg:ReadLong() + 2147483648;
		
		inv:RecvFullUpdate( iWeightCap, iSizeLimit, iMaxSlots );
	elseif msgType == IFINV_MSG_WEIGHTCAP then
		local inv = self:Get( id );
		if !inv then return false end
		
		local weightCap = msg:ReadLong() + 2147483648;
		
		inv:SetWeightCapacity( weightCap );
	elseif msgType == IFINV_MSG_SIZELIMIT then
		local inv = self:Get( id );
		if !inv then return false end
		
		local sizeLimit = msg:ReadLong() + 2147483648;
		
		inv:SetSizeLimit( sizeLimit );
	elseif msgType == IFINV_MSG_MAXSLOTS then
		local inv = self:Get( id );
		if !inv then return false end
		
		local maxSlots = msg:ReadLong() + 2147483648;
		
		inv:SetMaxSlots( maxSlots );
	elseif msgType == IFINV_MSG_CONNECTITEM then
		local inv = self:Get( id );
		if !inv then return false end
		
		local itemid = msg:ReadShort() + 32768;
		local item = IF.Items:Get( itemid );
		
		if !item || !item:IsValid() then ErrorNoHalt( "Itemforge Inventory: Tried to connect a non-existent item with ID "..itemid.." to "..tostring( inv )..".\n"); return false end
		
		local slot = msg:ReadShort() + 32768;

		inv:ConnectItem( item, nil, slot );
	elseif msgType == IFINV_MSG_CONNECTENTITY then
		local inv = self:Get( id );
		if !inv then return false end
		
		local eEntity = msg:ReadEntity();
		local slot = msg:ReadShort() + 32768;
		
		inv:ConnectEntity( eEntity, nil, slot );
	elseif msgType == IFINV_MSG_SEVERITEM then
		local inv = self:Get( id );
		if !inv then return false end
		
		local slot = msg:ReadShort() + 32768;
		inv:SeverItem( slot );
	elseif msgType == IFINV_MSG_SEVERENTITY then
		local inv = self:Get( id );
		if !inv then return false end
		
		local slot = msg:ReadShort() + 32768;
		inv:SeverEntity( slot );
	elseif msgType == IFINV_MSG_LOCK then
		local inv = self:Get( id );
		if !inv then return false end
		
		inv:Lock();
	elseif msgType == IFINV_MSG_UNLOCK then
		local inv = self:Get( id );
		if !inv then return false end
		
		inv:Unlock();
	else
		ErrorNoHalt( "Itemforge Inventory: Unhandled IFINV message \""..msgType.."\"\n" );
	end
end

--We use a proxy here so we can make HandleIFINVMessages a method (:) instead of a regular function (.)
usermessage.Hook( "ifinv", function( msg ) return IF.Inv:HandleIFINVMessages( msg ) end );




end











--[[
Base Inventory
SHARED

The Base Inventory contains functions and default values available to all inventories.
]]--

--[[
Non-Networked Vars
These vars are stored on the server, client, or both. However, if these vars change on one side, they aren't updated on the other side.
This section is good for things that don't change often but need to be known to both the client and server, such as the item's name.
]]--

_INV.Base				= "base_nw"						--Inventories are based off of base_nw, just like items
_INV.MaxSlots			= 0;							--How many slots for items does this inventory contain? If this is 0, there is no limit to the number of slots for items in an inventory.
_INV.WeightCapacity		= 0;							--The inventory can hold this much weight - set to 0 for infinite
_INV.SizeLimit			= 0;							--The inventory can hold items of this .Size or below. Setting to 0 will allow objects of any size to be placed in it.
_INV.RemoveOnSever		= true;							--Automatically remove this inventory when it no longer has any connected items/ents? If this is false, when an inventory loses all of it's connections, it won't be removed.
_INV.RemovalAction		= IFINV_RMVACT_SAMELOCATION;	--What this is set on determines what happens to the items in this inventory when the inventory is removed. The three possible values are IFINV_RMVACT_REMOVEITEMS, IFINV_RMVACT_VOIDITEMS, and IFINV_RMVACT_SAMELOCATION. An explanation for each of these is available at the top of this file.

--Don't modify these
_INV.ID					= 0;							--This is the ID of the inventory. It's assigned automatically.
_INV.Items				= nil;							--Collection of item references stored by this inventory. This can be sorted however you like. The index determines what position items are in in the GUI.
_INV.ItemsByID			= nil;							--This collection can be used to convert item IDs into the slot the item is stored in on this table. In this table, keys (also known as the indexes) are the Item's ID, and the values are the index the items are stored at in inventory.Items.
_INV.ConnectedObjects	= nil;							--These are the objects the inventory is connected with.
_INV.Locked				= false;						--If the inventory is locked, items can't be inserted into the inventory, and items in the inventory can't removed (unless forced), or interacted with by other players.
_INV.BeingRemoved		= false;						--This will be true if the inventory is being removed. If this is true, trying to remove the inventory (again) will have no effect.

if SERVER then

_INV.Owner				= nil;							--Updates to the inventory will only go to this player. If this is nil, updates will be sent to all players.

end




--[[
* SHARED

Removes this inventory (usually because the object the inventory is attached to has been removed)
If done serverside, informs the clients to do this as well.
]]--
function _INV:Remove( lastConnection )
	IF.Inv:Remove( self, lastConnection );
end

--[[
* SHARED

Set player who "owns" this inventory. Updates of the inventory will only be sent to this player (private inventory).
pl should be a player to send updates to, or nil if you want to send updates to all players (public inventory).
TODO need to check all network data to make sure it's respecting inventory owners
]]--
function _INV:SetOwner( pl )
	if pl != nil then
		if !IF.Util:IsPlayer( pl ) then return self:Error( "Cannot set owner. Given player wasn't a valid player!\n" ) end
	end
	
	local pOldOwner = self:GetOwner();
	
	--Record owner
	self.Owner = pl;
	
	--Create or remove the inventory clientside on certain players depending on owner change
	if pl != nil then
		
		if pOldOwner == nil then
			for k, v in pairs( player.GetAll() ) do
				if v != pl then IF.Inv:RemoveClientside( self:GetID(), v ) end
			end
			
		elseif pOldOwner != pl then
			IF.Inv:RemoveClientside( self:GetID(), pOldOwner );
			IF.Inv:SendFullUpdate( self:GetID(), pl );
		end
	
	elseif pOldOwner != nil then
		for k, v in pairs( player.GetAll() ) do
			if v != pOldOwner then IF.Inv:SendFullUpdate( self:GetID(), v ) end
		end
	end
	
	--Set owner of any items in this inventory
	for k, v in pairs( self.Items ) do
		v:SetOwner( pOldOwner, pl );
	end
end

--[[
* SHARED

Set weight capacity for this inventory in grams.
If called serverside, the clients are instructed to set the weight capacity as well.

Note: If the weight capacity changes to something smaller than the current total weight, (e.g. there are 2000000 grams in the inventory, but the weight capacity is set to 1000000 grams)
items will not be removed to compensate for the weight capacity changing.
Set to 0 to allow limitless weight to be stored.
]]--
function _INV:SetWeightCapacity( iCap, pl )
	if iCap == nil	then return self:Error( "Couldn't set weight capacity... amount to set wasn't given.\n" ) end
	if iCap < 0		then return self:Error( "Can't set weight capacity to negative values! (Set to 0 if you want the inventory to store an infinite amount of weight)\n" ) end
	
	if SERVER && pl != nil then
		if !IF.Util:IsPlayer( pl )					then return self:Error( "Cannot set weight capacity. Given player wasn't a valid player!\n" );
		elseif !self:CanNetwork( pl )				then return self:Error( "Cannot set weight capacity. Given player wasn't the owner of the inventory!\n" ) end
	end
	
	self.WeightCapacity = iCap;
	
	--Update weight clientside too
	if SERVER then
		--DEBUG
		Msg( "OUT: Message Type: "..IFINV_MSG_WEIGHTCAP.." - Inventory: "..self:GetID().." - Player: "..tostring( pl ).."\n" );
		
		umsg.Start( "ifinv", pl or self:GetOwner() );
		umsg.Char( IFINV_MSG_WEIGHTCAP );
		umsg.Short( self:GetID() - 32768 );
		umsg.Long( self:GetWeightCapacity() - 2147483648 );
		umsg.End();
	else
		self:Update();
	end
	
	return true;
end

--[[
* SHARED

Set size limit for this inventory.
If called serverside, the clients are instructed to set the size limit as well.

Item size limit can be used to restrict objects of certain sizes from entering the inventory.
	For example, maybe your backpack can hold a soda can, but can't hold a desk.
	On the other hand, maybe a trailer's inventory could hold a desk.

You can set the size limit to 0 to allow items of any size to be placed in the inventory.

Note: If the size limit changes, items will not be removed to compensate for the size limit changing.
	Example: Item with size 506 is in inventory, but size limit changes to 500.
	The item is not taken out because the size limit changed.
]]--
function _INV:SetSizeLimit( sizelimit, pl )
	if sizelimit == nil	then return self:Error( "Couldn't set size limit - sizelimit wasn't given.\n" ) end
	if sizelimit < 0	then return self:Error( "Can't set size limit to negative values! (Set to 0 to allow items of any size to be inserted)\n" ) end
	
	if SERVER && pl != nil then
		if !IF.Util:IsPlayer( pl )				then return self:Error( "Cannot set size limit. Given player wasn't a valid player!\n" );
		elseif !self:CanNetwork( pl )			then return self:Error( "Cannot set size limit. Given player wasn't the owner of the inventory!\n" ) end
	end
	
	self.SizeLimit = sizelimit;
	
	--Update size limit clientside too
	if SERVER then
		--DEBUG
		Msg( "OUT: Message Type: "..IFINV_MSG_SIZELIMIT.." - Inventory: "..self:GetID().." - Player: "..tostring(pl).."\n" );
		
		umsg.Start( "ifinv", pl or self:GetOwner() );
		umsg.Char( IFINV_MSG_SIZELIMIT );
		umsg.Short( self:GetID() - 32768 );
		umsg.Long( sizelimit - 2147483648 );
		umsg.End();
	else
		self:Update();
	end
	
	return true;
end

--[[
* SHARED

Set max slots for this inventory.

If called serverside, the clients are instructed to set the max slots as well.

A slot limit can be used to restrict how many items (or stacks of items) may be placed
in this inventory.
	For example, maybe a weapon rack can only hold four items?
NOTE: If the max slots changes, items will not be removed to compensate for the max slots changing.
WARNING: If an item is in, say, slot 7, and max slots is changed to 5, you'll open up the inventory and see a closed slot where item 7 is supposed to be.
]]--
function _INV:SetMaxSlots( max, pl )
	if max == nil	then return self:Error( "Couldn't set max number of slots... max wasn't given.\n" ) end
	if max < 0		then return self:Error( "Can't set max number of slots to negative values! (Set to 0 for infinite slots)\n" ) end
	
	if SERVER && pl != nil then
		if !pl:IsValid()						then return self:Error( "Cannot set max number of slots. Given player was invalid.\n" );
		elseif !pl:IsPlayer()					then return self:Error( "Cannot set max number of slots. Given player wasn't a player!\n" );
		elseif !self:CanNetwork(pl)				then return self:Error( "Cannot set max number of slots. Given player wasn't the owner of the inventory!\n" ) end
	end
	
	self.MaxSlots = max;
	
	--Update max slots clientside too
	if SERVER then
		--DEBUG
		Msg( "OUT: Message Type: "..IFINV_MSG_MAXSLOTS.." - Inventory: "..self:GetID().." - Player: "..tostring( pl ).."\n" );
		
		umsg.Start( "ifinv", pl or self:GetOwner() );
		umsg.Char( IFINV_MSG_MAXSLOTS );
		umsg.Short( self:GetID() - 32768 );
		umsg.Long( max - 2147483648 );
		umsg.End();
	else
		self:Update();
	end
	
	return true;
end

--[[
* SHARED

Returns this inventory's ID
]]--
function _INV:GetID()
	return self.ID;
end

--[[
* SHARED

Returns the name of the inventory-type this inventory uses.
]]--
function _INV:GetType()
	return self.ClassName;
end

--[[
* SHARED

Get the net-owner of this inventory.
This will return the player who owns it, or nil if this inventory isn't owned by anybody.
]]--
function _INV:GetOwner()
	return self.Owner;
end

--[[
* SHARED

Returns the size limit for this inventory.
]]--
function _INV:GetSizeLimit()
	return self.SizeLimit;
end

--[[
* SHARED

Get weight capacity for this inventory in grams.
]]--
function _INV:GetWeightCapacity()
	return self.WeightCapacity;
end

--[[
* SHARED

Returns the maximum number of slots that this inventory supports.
]]--
function _INV:GetMaxSlots()
	return self.MaxSlots;
end

--[[
* SHARED

Returns the total weight of all items stored in the inventory, in grams.
]]--
function _INV:GetWeightStored()
	local iTotalWeight = 0;
	for k, v in pairs( self.Items ) do
		if v:IsValid() then iTotalWeight = iTotalWeight + v:GetStackWeight(); end
	end
	return iTotalWeight;
end

--[[
* SHARED

Returns the amount of free weight storage left in the inventory.
]]--
function _INV:GetWeightFree()
	return self:GetWeightCapacity() - self:GetWeightStored();
end

--[[
* SHARED

Returns the position of the inventory in the world.
If you get the position of an inventory, it returns the position(s) of the inventory's connected object(s).
	So, if our item is in an inventory connected with a barrel entity, it returns the position of the barrel entity.
	If our inventory is connected with, lets say, two bags that share the same inventory, then it returns both the position of the first bag and the second (as a table).
	
	If this is a player's inventory, it returns the player's position.
	If our item is in a bottle inside of a crate in the world, it returns the crate's position.
	If our inventory isn't connected with anything, it returns nil.
]]--
function _INV:GetPos()
	for k, v in pairs( self.ConnectedObjects ) do
		if v.Obj:IsValid() then		return v.Obj:GetPos();
		else						--TODO cleanup
		end
	end
end

--[[
* SHARED

Locks the inventory.
If pl is given only locks for that player
]]--
function _INV:Lock( pl )
	if SERVER && pl != nil then
		if !pl:IsValid()						then return self:Error( "Cannot lock. Given player was invalid.\n" );
		elseif !pl:IsPlayer()					then return self:Error( "Cannot lock. Given player wasn't a player!\n" );
		elseif !self:CanNetwork( pl )			then return self:Error( "Cannot lock. Given player wasn't the owner of the inventory!\n" );
		end
	end
	
	local bWasLocked = false;
	if !self.Locked then
		self.Locked = true;
		self:Event( "OnLock" );
		bWasLocked = true;
	end
	
	if SERVER && ( bWasLocked || pl ) then
		--DEBUG
		Msg( "OUT: Message Type: "..IFINV_MSG_LOCK.." - Inventory: "..self:GetID().." - Player: "..tostring( pl ).."\n" );
		
		umsg.Start( "ifinv", pl or self:GetOwner() );
		umsg.Char( IFINV_MSG_LOCK );
		umsg.Short( self:GetID() - 32768 );
		umsg.End();
	end
end

--[[
* SHARED

Unlocks the inventory.
If pl is given only unlocks for that player
]]--
function _INV:Unlock( pl )
	
	if SERVER && pl != nil then
		if !pl:IsValid()						then return self:Error( "Cannot unlock. Given player was invalid.\n" );
		elseif !pl:IsPlayer()					then return self:Error( "Cannot unlock. Given player wasn't a player!\n" );
		elseif !self:CanNetwork( pl )			then return self:Error( "Cannot unlock. Given player wasn't the owner of the inventory!\n" ) end
	end
	
	local bWasUnlocked = false;
	if self.Locked then
		self.Locked = false;
		self:Event( "OnUnlock" );
		bWasUnlocked = true;
	end
	
	if SERVER && ( bWasUnlocked || pl ) then
		--DEBUG
		Msg( "OUT: Message Type: "..IFINV_MSG_UNLOCK.." - Inventory: "..self:GetID().." - Player: "..tostring( pl ).."\n" );
		
		umsg.Start( "ifinv", pl or self:GetOwner() );
		umsg.Char( IFINV_MSG_UNLOCK );
		umsg.Short( self:GetID() - 32768 );
		umsg.End();
	end
end

--[[
* SHARED

Returns true if the inventory is locked.
Returns false otherwise.
]]--
function _INV:IsLocked()
	return self.Locked;
end

--[[
* SHARED

The purpose of this function is to determine if the inventory is attached to a given item,
OR if the inventory is attached to an item inside of the given item.

This function returns true if either of the two conditions above are met. 

This function may sound somewhat complex.
Lets say you have a setup where:
	Barrel is an item, with an inventory attached to it.
	Bag is an item, with an inventory attached to it.
	Bag is in Barrel's Inventory.

Here's what that looks like in a hierarchy:

Barrel
|_Barrel Inventory
  |_Bag
    |_Bag Inventory

If we were to do BagInventory:IsBeneath(Barrel), it would return true, since
BagInventory is underneath Barrel in the containment hierarchy.
]]--
function _INV:IsBeneath( item )
	for k, v in pairs( self.ConnectedObjects ) do
		if v.Type == IFINV_CONTYPE_ITEM then
			if v.Obj == item then return true end
			local container = v.Obj:GetContainer();
			if container != nil && container:IsBeneath( item ) then return true end
		end
	end
	return false;
end

--[[
* SHARED

Returns the first item in the inventory (slot-wise), or nil if the inventory is empty.
]]--
function _INV:GetFirst()
	if self:IsEmpty() then return nil end
	local i = 1;
	while self.Items[i] == nil do
		i = i + 1;
	end
	return self.Items[i];
end

--[[
* SHARED

Returns the last item in the inventory (slot-wise), or nil if the inventory is empty.
]]--
function _INV:GetLast()
	if self:IsEmpty() then return nil end
	return self.Items[table.maxn( self.Items )];
end

--[[
* SHARED

Returns true if this inventory is empty. Returns false otherwise.
]]--
function _INV:IsEmpty()
	return ( table.maxn( self.Items ) == 0 );
end

--[[
* SHARED

Returns the number of items stored in this inventory.
]]--
function _INV:GetCount()
	local c = 0;
	for k, v in pairs( self.Items ) do c = c + 1; end
	return c;
end

--[[
* SHARED

Give this function an item ID and it will return the slot the item occupies in this inventory.
If the item isn't in the inventory, nil is returned.
]]--
function _INV:GetItemSlotByID( itemid )
	return self.ItemsByID[itemid];
end

--[[
* SHARED

Returns an item with the given slot in this inventory.
If there's no item in this inventory slot, nil is returned.
]]--
function _INV:GetItemBySlot( slot )
	if !self.Items[slot] then return nil end

	local item = self.Items[slot];
	if item:IsValid() then
		return self.Items[slot];
	else
		self.Items[slot] = nil;
		return nil;
	end
end

--[[
* SHARED

Returns an item with the given type in this inventory.
If there's no item with this type in the inventory (or there are errors), nil is returned.
If there are several items of this type in the inventory, then the first item found with this type is returned.
]]--
function _INV:GetItemByType( strItemtype )
	if !strItemtype then self:Error( "Can't find a specific item-type - the type of item to find wasn't given!\n" ); return nil end
	strItemtype = string.lower( strItemtype );
	
	for k, v in pairs( self.Items ) do
		if v:IsValid() then
			if v:GetType() == strItemtype then return v end
		else
			--INVALID - Item was removed but not taken out of inventory for some reason
			self:Error( "Found an item (slot "..k..") that no longer exists but is still recorded as being in this inventory.\n" );
		end
	end
	return nil;
end

--[[
* SHARED

Returns a table of items with the given type in this inventory.
Returns nil if there are errors.
]]--
function _INV:GetItemsByType( strItemtype )
	if !strItemtype then self:Error( "Can't find items of a specific item-type - the type of item to find wasn't given!\n" ); return nil end
	local strItemtype = string.lower( strItemtype );
	
	local tItems = {};
	for k, v in pairs( self.Items ) do
		if v:IsValid() then
			if v:GetType() == strItemtype then table.insert( tItems, v ) end
		else
			--INVALID - Item was removed but not taken out of inventory for some reason
			self:RemoveItem( k, true, false );
			self:Error( "Found an item (slot "..k..") that no longer exists but is still listed as being in this inventory\n" );
		end
	end
	
	return tItems;
end

--[[
* SHARED

Returns a table of all items in this inventory
]]--
function _INV:GetItems()
	local t = {};
	for k, v in pairs( self.Items ) do
		t[k] = v;
	end
	return t;
end

--[[
* SHARED

This function ties this inventory to an item.
If an inventory is connected with an item, it means that the inventory is a part of it.
If the item is removed, then the connection is severed.

An inventory can have several connected objects.
When an inventory loses all of it's connections, it's removed.
If there are items in the inventory at the time it's removed, it's items are moved to the same location as the last object it was connected with.

item should be an item.
pl is an optional player to connect the item on. If no player is given, it will connect the item on all players clientside.
	If the item is already connected, it will just tell this player to connect the item clientside.
slot is only required clientside.
	This should be a slot passed from the server.
	The connected item is stored here.

true is returned if the item was successfully connected.
false is returned otherwise.

TODO: Allow items/ents to connect serverside even if they can't connect clientside
]]--
function _INV:ConnectItem( item, pl, iSlot )
	if !IF.Util:IsItem( item ) then return self:Error( "Couldn't connect item - given item was invalid.\n" ) end
	
	if SERVER then

		--Validate player if one was given
		if pl != nil then
			if !IF.Util:IsPlayer( pl )	then return self:Error( "Couldn't connect "..tostring( item ).." - The player to connect this to clientside wasn't a valid player!\n" ) end
			if !self:CanNetwork( pl )	then return self:Error( "Couldn't connect "..tostring( item ).." - This inventory is not owned by the given player." ) end
		else
			pl = self:GetOwner();
		end
		
		--Check to see if this item is connected already... if it is, grab the connection slot it's in.
		iSlot = nil;
		for k, v in pairs( self.ConnectedObjects ) do
			if v.Obj == item then
				iSlot = k;
				break;
			end
		end

		--If the item isn't connected, connect
		if iSlot == nil then
			local newCon = {};
			newCon.Type = IFINV_CONTYPE_ITEM;
			newCon.Obj  = item;

			iSlot = table.insert( self.ConnectedObjects, newCon );

			item:ConnectInventory( self, iSlot );
		end

		--DEBUG
		Msg( "OUT: Message Type: "..IFINV_MSG_CONNECTITEM.." - Inventory: "..self:GetID().." - Player: "..tostring( pl ).."\n" );
	
		--Connect the item on the given player(s)
		umsg.Start( "ifinv", pl );
		umsg.Char( IFINV_MSG_CONNECTITEM );
		umsg.Short( self:GetID() - 32768 );
		umsg.Short( item:GetID() - 32768 );
		umsg.Short( iSlot - 32768 );
		umsg.End();

	else

		if !IF.Util:IsNumber( iSlot ) then return self:Error( "Couldn't connect item clientside - no connection slot was given.\n" ) end

		local newCon = {};
		newCon.Type = IFINV_CONTYPE_ITEM;
		newCon.Obj  = item;

		self.ConnectedObjects[iSlot] = newCon;

		item:ConnectInventory( self, iSlot );

	end

	return true;
end

--[[
* SHARED

This command is used to tie this inventory to an entity.
If an inventory is connected with an entity, it means that the inventory is a part of it.
If the entity is removed, then the connection is severed.

An inventory can have several connected objects.
When an inventory loses all of it's connections, it's removed.
If there are items in the inventory at the time it's removed, it's items are moved to the same location as the last object it was connected with.

ent should be an entity.
pl is an optional player to connect the entity on.
	If no player is given, it will connect the entity on all players clientside.
	If the entity is already connected, it will just tell this player to connect the entity clientside.
slot is only required clientside.
	This should be a slot passed from the server.
	The connected item is stored here.

true is returned if the item was successfully connected.
false is returned otherwise.

TODO: Allow items/ents to connect serverside even if they can't connect clientside
]]--
function _INV:ConnectEntity( eEntity, pl, iSlot )
	if !IF.Util:IsEntity( eEntity ) then return self:Error( "Couldn't connect entity - given entity was invalid.\n" ) end
	
	if SERVER then

		--Validate player if one was given
		if pl != nil then
			if !IF.Util:IsPlayer( pl )	then return self:Error( "Couldn't connect "..tostring( eEntity ).." - The player to connect this to clientside wasn't a valid player!\n" ); end
			if !self:CanNetwork( pl )	then return self:Error( "Couldn't connect "..tostring( eEntity ).." - This inventory is not owned by the given player." ) end
		else
			pl = self:GetOwner();
		end

		--Check to see if this item is connected already... if it is, grab the connection slot it's in.
		iSlot = nil;
		for k, v in pairs( self.ConnectedObjects ) do
			if v.Obj == eEntity then
				iSlot = k;
				break;
			end
		end

		--If the entity isn't connected, connect
		if iSlot == nil then
			local newCon = {};
			newCon.Type = IFINV_CONTYPE_ENT;
			newCon.Obj  = eEntity;

			iSlot = table.insert( self.ConnectedObjects, newCon );

			if !eEntity:IsPlayer() then eEntity:CallOnRemove( "ifinv_"..self:GetID().."_connect", self.ConnectedEntityRemoved, self ); end
			eEntity.ConnectionSlot = iSlot;
		end

		--DEBUG
		Msg( "OUT: Message Type: "..IFINV_MSG_CONNECTENTITY.." - Inventory: "..self:GetID().." - Player: "..tostring( pl ).."\n" );
		
		--Connect the entity on the given player(s)
		umsg.Start( "ifinv", pl );
		umsg.Char( IFINV_MSG_CONNECTENTITY );
		umsg.Short( self:GetID() - 32768 );
		umsg.Entity( eEntity );
		umsg.Short( iSlot - 32768 );
		umsg.End();

	else

		if !IF.Util:IsNumber( iSlot ) then return self:Error( "Couldn't connect entity clientside - no connection slot was given.\n" ) end

		local newCon = {};
		newCon.Type = IFINV_CONTYPE_ENT;
		newCon.Obj  = eEntity;

		self.ConnectedObjects[iSlot] = newCon;

		if !eEntity:IsPlayer() then eEntity:CallOnRemove( "ifinv_"..self:GetID().."_connect", self.ConnectedEntityRemoved, self ); end
		eEntity.ConnectionSlot = iSlot;
		

	end
	
	return true;
end

--[[
* SHARED

This command is used to untie this inventory from an item.

iSlot is a slot to sever.
bNotClient is an optional true/false that you can give.
	If this is true, we won't tell clients to sever the connection between the item and the inventory.
TODO recursive network send
TODO the connected objects need to be removed differently
]]--
function _INV:SeverItem( iSlot, bNotClient )
	if !IF.Util:IsNumber( iSlot )							then return self:Error( "Couldn't sever item - slot to sever wasn't given / wasn't a number.\n" )				end
	local con = self.ConnectedObjects[iSlot];
	if con == nil											then return self:Error( "Couldn't sever item - there is no connected object on slot "..iSlot..".\n" )			end
	if con.Type != IFINV_CONTYPE_ITEM						then return self:Error( "Couldn't sever item - the connected object on slot "..iSlot.." is not an item.\n" )		end
	
	--Break one-way connection between item and inventory, if the item is still valid
	local item = con.Obj;
	if item:IsValid() then item:SeverInventory( self ); end
	
	--Break one-way connection between inventory and item
	self.ConnectedObjects[iSlot] = nil;
	
	if SERVER then

		--If the last connection was removed, inventory fizzles (if the inventory fizzles we'll stop the function before it networks data, we can take care of the removal of attached objects via the inventory's removal both serverside and clientside)
		if #self.ConnectedObjects == 0 then
			self:Remove( con );
			return true;
		end
	
	

		if !bNotClient then
			--DEBUG
			Msg( "OUT: Message Type: "..IFINV_MSG_SEVERITEM.." - Inventory: "..self:GetID().." - Player: "..tostring( nil ).."\n" );
		
			umsg.Start( "ifinv", nil );
			umsg.Char( IFINV_MSG_SEVERITEM );
			umsg.Short( self:GetID() - 32768 );
			umsg.Short( iSlot - 32768 );
			umsg.End();
		end

	end
end

--[[
* SHARED

This command is used to untie this inventory from an entity.

iSlot is a slot to sever.
bNotClient is an optional true/false that you can give.
	If this is true, we won't tell clients to sever the connection between the entity and the inventory.
TODO recursive network send
TODO the connected objects need to be removed differently
]]--
function _INV:SeverEntity( iSlot, bNotClient )
	if !IF.Util:IsNumber( iSlot )							then return self:Error( "Couldn't sever entity - slot to sever wasn't given / wasn't a number.\n" )				end
	local con = self.ConnectedObjects[iSlot];
	if con == nil											then return self:Error( "Couldn't sever entity - there is no connected object on slot "..iSlot..".\n" ) end
	if con.Type != IFINV_CONTYPE_ENT						then return self:Error( "Couldn't sever entity - the connected object on slot "..iSlot.." is not an entity.\n" ) end
	
	--Break one-way connection between ent and inventory, if the item is still valid
	local eEntity = con.Obj;
	if eEntity:IsValid() then eEntity:RemoveCallOnRemove( "ifinv_"..self:GetID().."_connect" ); eEntity.ConnectionSlot = nil; end
	
	--Break one-way connection between inventory and ent
	self.ConnectedObjects[iSlot] = nil;
	
	if SERVER then

		--If the last connection was removed, inventory fizzles (if the inventory fizzles we'll stop the function before it networks data, we can take care of the removal of attached objects via the inventory's removal both serverside and clientside)
		if #self.ConnectedObjects == 0 then
			self:Remove( con );
			return true;
		end
	
		if !bNotClient then
			--DEBUG
			Msg( "OUT: Message Type: "..IFINV_MSG_SEVERENTITY.." - Inventory: "..self:GetID().." - Player: "..tostring( nil ).."\n" );
		
			umsg.Start( "ifinv", nil );
			umsg.Char( IFINV_MSG_SEVERENTITY );
			umsg.Short( self:GetID() - 32768 );
			umsg.Short( iSlot - 32768 );
			umsg.End();
		end

	end
end

--[[
* SHARED

Returns a table of all items connected (via ConnectItem) to this inventory.
]]--
function _INV:GetConnectedItems()
	local t = {};
	for k, v in pairs( self.ConnectedObjects ) do
		if v.Type == IFINV_CONTYPE_ITEM then
			table.insert( t, v.Obj );
		end
	end
	return t;
end

--[[
* SHARED

Returns a table of all entities connected (via ConnectEntity) to this inventory.
]]--
function _INV:GetConnectedEntities()
	local t = {};
	for k, v in pairs( self.ConnectedObjects ) do
		if v.Type == IFINV_CONTYPE_ENT then
			table.insert( t, v.Obj );
		end
	end
	return t;
end

--[[
* SHARED

Returns a string describing the connections the inventory has.
]]--
function _INV:GetConnectionString()
	--TODO possible bug here... #t does table.getn(t), which returns the largest consecutive integer index... if say, you had 1,2,3,4,5 and removed the 3, this would return 2 instead of the proper 4, I think...
	--TODO additionally, if there were two connections, and connected object 1 was removed, the below code would fail... clearly I need to fix this.
	local iCount = #self.ConnectedObjects;
	local strConnectedTo = "nothing";

	--Only one connection
	if iCount == 1 then
		strConnectedTo = tostring( self.ConnectedObjects[1].Obj );
	
	--Several connections
	elseif iCount > 1 then
		local iItemCount = #self:GetConnectedItems();
		local iEntCount  = #self:GetConnectedEntities();
		
		--Several items, no entities
		if iItemCount > 1 && iEntCount == 0 then
			if iItemCount < 5 then		strConnectedTo = IF.Util:CommaSeperatedList( self:GetConnectedItems(), true );
			else						strConnectedTo = iItemCount.." items";
			end
		--Several entities, no items
		elseif iItemCount == 0 && iEntCount > 1 then
			if iEntCount < 5 then		strConnectedTo = IF.Util:CommaSeperatedList( self:GetConnectedEntities(), true );
			else						strConnectedTo = iEntCount.." entities";
			end
		
		--Both entities and items, but only a few
		elseif iCount < 5 then
			strConnectedTo = tostring( self.ConnectedObjects[1].Obj );
			for i = 2, iCount do strConnectedTo = strConnectedTo..", "..tostring( self.ConnectedObjects[i].Obj ); end
		
		--Many entities and items
		else
			strConnectedTo = iItemCount.." items, "..iEntCount.." entities";
		end
	end
	return strConnectedTo;
end

--[[
* SHARED
* Event

When tostring() is used on this inventory, this function returns a string describing the inventory.
Format: "Inventory ID [COUNT items @ LOCATION]" 
Ex:     "Inventory 12 [20 items @ Player [1][theJ89] ]" (Inventory 12, storing 20 items, attached to Player 1: theJ89)
]]--
function _INV:ToString()
	return "Inventory "..self:GetID().." ["..self:GetCount().." "..IF.Util:Pluralize( "item", self:GetCount() ).." @ "..self:GetConnectionString().."]";
end

--[[
* SHARED
* Internal

Clears the record of all items currently in this inventory.
This will not manually remove each item.
NOTE: This only clears the record of any items in the inventory.
]]--
--[[
function _INV:RemoveAll()
	self.Items     = {};
	self.ItemsByID = {};
	if CLIENT then self:Update(); end
end
]]--



--Serverside
if SERVER then




--[[
* SERVER

Checks if inventory data can be sent to a player.
If we have an owner, then it's important to check who we're sending this to.
Inventory data cannot be sent to players (because the data needs to be private) other than the owner of the inventory, if the inventory is private.

pl can be a certain player or nil (to show that you want to send to everybody)

Returns true if it can, false otherwise
]]--
function _INV:CanNetwork( pl )
	local plOwner = self:GetOwner();
	return ( plOwner == nil || pl == plOwner );
end




end


--[[
INVENTORY EVENTS
]]--




--[[
* SHARED
* Event

Returns the title of the inventory.
This is displayed on the GUI when the inventory is opened on-screen.

By default, the inventory title is the name of the first connected object found.
You can override this to return whatever you like (as long as it's a string).

The advantage of doing this is when you have two or more inventories on a single
item (for example, a vending machine), you can give each inventory a different
title ("Products" and "Profits", for example).
]]--
function _INV:GetTitle()
	for k, v in pairs( self.ConnectedObjects ) do
		if v.Type == IFINV_CONTYPE_ITEM && v.Obj:IsValid() then
			return v.Obj:GetName();
		end
	end
	return "Inventory";
end

--[[
* SHARED
* Event

Called when moving an item in this inventory from one slot to another.

item is the item being moved.
iOldSlot is the slot the item is currently in.
iNewSlot is the slot the item wants to move to.

Return false to stop the item from moving, or return true to allow it to move.
]]--
function _INV:CanMoveItem( item, iOldSlot, iNewSlot )
	return true;
end

--[[
* SHARED
* Event

Called after an item in this inventory has been moved from one slot to another.

item is the item that moved.
iOldSlot was the slot the item was occupying before.
iNewSlot is the slot the item is now occupying.
]]--
function _INV:OnMoveItem( item, iOldSlot, iNewSlot )

end

--[[
* SHARED
* Event

Called when inserting an item into the inventory.
This can be used to stop an item from entering this inventory.

item is the item being inserted.
iSlot is the slot in the inventory that the item will be placed in.

Return false to stop the item from being inserted,
or true to allow it to be inserted.
]]--
function _INV:CanInsertItem( item, iSlot )
	return !self.Locked;
end

--[[
* SHARED
* Event

Called after an item has been inserted.

item is the item being inserted.
iSlot is the slot in the inventory that the item was placed in.
]]--
function _INV:OnInsertItem( item, iSlot )
end

--[[
* SHARED
* Event

Called when taking an item out of the inventory.

item is the item that wants to be taken out.
iSlot is the slot this item is occupying in this inventory.

Return true to allow the item to be taken out,
or false to stop the item from being taken out.
]]--
function _INV:CanRemoveItem( item, iSlot )
	return !self.Locked;
end

--[[
* SHARED
* Event

Called after an item has been taken out of the inventory.

item is the item that was taken out.
iSlot is the slot this item was in.
bForced will be true or false.
	If bForced is true, then the item HAD to come out (this inventory was removed, the item was removed, etc).
	If bForced is false, this was a normal removal (we just moved the item somewhere else)
]]--
function _INV:OnRemoveItem( item, iSlot, bForced )
end

--[[
* SHARED
* Event

Runs when the inventory becomes empty (contains 0 items)
TODO implement. Should run after initialization since it's empty at this time
]]--
function _INV:OnEmpty()

end

--[[
* SHARED
* Event

Runs when the inventory was empty and becomes non-empty (contains at least 1 item)
TODO implement.
]]--
function _INV:OnNonEmpty()

end

--[[
* SHARED
* Event

Runs when the inventory was partially full (#items < max # of slots) and becomes full (#items = max# of slots).
Note that if your inventory has an infinite # of slots this event will never call.
TODO implement.
Event potentially calls when max# of slots changes or #of items changes (insertion)
]]--
function _INV:OnFull()

end

--[[
* SHARED
* Event

Runs when the inventory was full (#items = max# of slots) and becomes partially full (#items < max # of slots).
Note that if your inventory has an infinite # of slots this event will never call.
TODO implement.
Event potentially calls when max# of slots changes or #of items changes (removal)
]]--
function _INV:OnNonFull()

end

--[[
* SHARED
* Event

Runs when the inventory had free weight (free weight > 0), but now has filled it's weight capacity (free weight = 0).

TODO implement.
Event potentially calls when weight limit changes or #of items changes (insertion)
]]--
function _INV:OnMaxWeight()

end

--[[
* SHARED
* Event

Runs when the inventory had filled it's weight capacity (free weight = 0), but now has free weight available (free weight > 0).

TODO implement.
Event potentially calls when weight limit changes or #of items changes (removal)
]]--
function _INV:OnFreeWeight()
end

--[[
* SHARED
* Event

Called after the inventory has been locked.
]]--
function _INV:OnLock()
end

--[[
* SHARED
* Event

Called after the inventory has been unlocked.
]]--
function _INV:OnUnlock()
end

--[[
* SHARED
* Event

Can a player interact with an item in this inventory?
When an item's CanPlayerInteract event is called, this function lets it's container
have a say in whether or not we can interact with it.

pl is the player who wants to interact with an item in this inventory.
item is the item being interacted with.

Return true to allow the player to interact with items in this inventory,
or false to stop players from interacting with items in this inventory.
]]--
function _INV:CanPlayerInteract( pl, item )
	--Can't interact with this inventory if it's locked, or if the player doesn't own it
	if self.Locked || ( SERVER && !self:CanNetwork( pl ) ) then return false end
	
	--Can't interact with this inventory if we can't interact with at least one of the inventory's
	--connected objects
	for k, v in pairs( self:GetConnectedItems() ) do
		if v:Event( "CanPlayerInteract", false, pl ) then
			return true;
		end
	end

	local vPlayerPos = pl:GetPos();
	for k, v in pairs( self:GetConnectedEntities() ) do
		if vPlayerPos:Distance( v:GetPos() ) <= 256 then return true end
	end

	return false;
end

--[[
* SHARED
* Event

Called prior to the inventory being removed
]]--
function _INV:OnRemove( lastConnection )
	--Deal with items in this inventory at the time of removal
	--Items will be taken care of serverside AND clientside (rather than just removing them serverside and individually removing each one clientside, we roll it all into one function here to save bandwidth/reduce lag)
	if SERVER then
		if self.RemovalAction == IFINV_RMVACT_REMOVEITEMS || !lastConnection then
			for k, v in pairs( self.Items ) do
				--Assert that items are still valid and still consider themselves part of this inventory
				if v:IsValid() && v:InInventory( self ) then
					v:Remove();
				end
			end
		elseif self.RemovalAction == IFINV_RMVACT_SAMELOCATION then
			--TODO THIS SUCKS, it should force removal of the items instead of unlocking it here
			self.Locked = false;
			if lastConnection.Type == IFINV_CONTYPE_ITEM then
				for k, v in pairs( self.Items ) do
					--Assert that items are still valid and still consider themselves part of this inventory
					if v:IsValid() && v:InInventory( self ) then
						v:ToSameLocationAs( lastConnection.Obj, true );
					end
				end
			elseif lastConnection.Type == IFINV_CONTYPE_ENT then
				for k, v in pairs( self.Items ) do
					--Assert that items are still valid and still consider themselves part of this inventory
					if v:IsValid() && v:InInventory( self ) then
						--TODO inventory's last connection was an entity
					end
				end
			end
		elseif self.RemovalAction == IFINV_RMVACT_VOIDITEMS then
			for k, v in pairs( self.Items ) do
				v:ToVoid( true, self, true );
			end
		end
	else
		if self.RemovalAction == IFINV_RMVACT_VOIDITEMS then
			for k, v in pairs( self.Items ) do
				v:ToVoid( true, self, nil, false );
			end
		end
	end
end




if SERVER then




--[[
* SERVER
* Event

Called when a full update is being sent. You can put some stuff here to send along with it if you like.
pl is the player who the full update is being sent to.
]]--
function _INV:OnSendFullUpdate( pl )
	
end




else




--[[
* CLIENT
* Event

Returns the icon this inventory uses.
This is displayed on the GUI when an inventory is opened on-screen (in the little circular thing at the top left on the ItemforgeInventory panel).
By default, the inventory icon is the icon of the first connected object found.
You can override this to return whatever you like (as long as it's a material or nil).
The advantage of doing this is when you have two or more inventories on a single item (like a refrigerator, for example) you can give each one a different icon.
]]--
function _INV:GetIcon()
	for k, v in pairs( self.ConnectedObjects ) do
		if v.Type == IFINV_CONTYPE_ITEM && v.Obj:IsValid() then
			return v.Obj:GetIcon();
		end
	end
	return nil;
end




end




--[[
INTERNAL METHODS
DO NOT OVERRIDE IN THIS SCRIPT OR OTHER SCRIPTS
These functions are called internally by Itemforge. There should be no reason for a scripter to call these.
]]--




--[[
* SHARED

This is called to initialize a newly created inventory.
]]--
function _INV:Initialize()
	self.Items = {};
	self.ItemsByID = {};
	self.ConnectedObjects = {};
end

--[[
* SHARED
* Internal

Adds an item into this inventory.

When this function is run, it triggers the CanInsertItem event, both clientside and serverside.
This event gives the inventory a chance to stop the item from being inserted.

The clients are instructed to add the item automatically by the Item's ToInventory function.
Use the item's ToInventory() function and pass this inventory's ID.

If the item is successfully inserted, the inventory's OnInsertItem event is triggered as well.

item is the item / stack of items to insert.
iSlotNum's use varies by what side it's on:
	Serverside, If a specific slot is requested, we'll try to add it there. If it doesn't work for some reason, we'll fail. This can be nil to accept any slot.
	Clientside, It's necessary to provide iSlotNum to prevent netsync errors.
bNoSplit is an optional true/false. If item is a stack that weighs too much to fit the all the items in this inventory, and bNoSplit is:
	false or not given, we'll determine how many items in the stack can fit in the inventory, and then split off that many items into a seperate stack.
	true, we'll return false (because we're basically saying we want the whole stack or no stack in there).
bPredict is an optional true/false that defaults to false on the server and true on the client. If bPredict is:
	false, we are actually inserting the item into this inventory.
	true, we are returning true/false if it is possible to insert the item into the inventory.

false is returned if the item could not be inserted for any reason.
Otherwise the slot for the item to use in the inventory is returned.
]]--
function _INV:InsertItem( item, iSlotNum, bNoSplit, bPredict )
	if !IF.Util:IsItem( item ) then return self:Error( "Couldn't insert item - given item was invalid.\n" ) end
	
	if bPredict == nil then bPredict = CLIENT end
	
	local itemid = item:GetID();
	
	--If the item is in this inventory already, we'll just return the slot it's in
	local s = self:GetItemSlotByID( itemid );
	if s != nil then return s end
			
	--Lets insert this item to a slot in this inventory.
	local i;
	if SERVER || bPredict then
		--Do we have a given slot?
		if iSlotNum then
			if self.Items[iSlotNum] == nil	then i = iSlotNum;			--Is the given slot open? If it is, we can insert/move the item to that slot.
			else								 return false;			--We can't insert/move into that slot, it's taken
			end
		--Lets search for an empty slot since no slot was given
		else
			i = self:GetFreeSlot();
			
			--If there are no free slots, fail
			if !i then return false end
		end
		
		
		--We're not trying to pull a loophole by putting an item into itself are we?
		--Also, is the item being inserted small enough to fit inside this inventory?
		if self:IsBeneath( item ) || ( self:GetSizeLimit() != 0 && item:GetSize() > self:GetSizeLimit() ) || !self:Event( "CanInsertItem", true, item, i ) then return false end

		--Can this inventory support the weight of all the items being inserted?
		--TODO Hard Weight Caps and Soft Weight Caps
		local iStackWeight = item:GetStackWeight();
		if self:GetWeightCapacity() != 0 && iStackWeight != 0 && ( self:GetWeightFree() - iStackWeight ) < 0 then
			--Since we don't have enough room, will you settle for moving part of the stack instead?
			if bNoSplit then return false end
			
			--How many items of this weight can fit in the inventory, if any?
			local iHowMany = math.floor( self:GetWeightFree() / item:GetWeight() );
			
			--If no items can fit, we'll just end it here.
			if iHowMany < 1 then return false end
				
			--The stack being moved to our inventory is 'item', so we'll create a stack with everything that _isn't_ moving to that inventory in the same location.
			--TODO I don't like this approach; it should split off a stack and move the new one instead
			local newStack = item:Split( item:GetAmount() - iHowMany, nil, bPredict );
			
			--If the new stack couldn't be created, we fail because it's been established that we can't fit the whole stack
			if !newStack then return false end
		end
	else
		if iSlotNum == nil then return self:Error( "Tried to add "..tostring( item ).." clientside, but iSlotNum was nil!\n" ) end
		i = iSlotNum;
	end
	
	
	--Send to void. False is returned in case of errors or if events stop the removal of the item from it's current medium.
	if !item:ToVoid( false, nil, true, bPredict ) then return false end
	
	if !bPredict then
		--Register the item in the inventory
		self.Items[i] = item;
		self.ItemsByID[itemid] = i;
		
		--OnInsertItem is called when an item enters the inventory
		self:Event( "OnInsertItem", nil, item, i );
		
		--Refresh any UI displaying this inventory
		if CLIENT then self:Update(); end
	end

	--Return slot item placed in
	return i;
end

--[[
* SHARED
* Internal

Moves an item in this inventory from one slot to another.

The Inventory's CanMoveItem event can stop the item from moving from one slot to another slot.
When an item is moved, the inventory's OnMoveItem event is triggered.

item is the item in this inventory to move.
	If the item is not in this inventory then an error message is generated.
iOldSlot is only required when moving items clientside.
	Clientside, both the item and the slot it's expected to be in are required to detect netsync errors.
iNewSlot is the slot to move the item to.
	If this slot is occupied, false is returned and if occuring clientside an error message is generated.
bPredict is an optional true/false that defaults to false on the server and true on the client. If bPredict is:
	false, then we are actually moving item from iOldSlot to iNewSlot.
	true, then we are simply predicting whether or not we can move the item.
]]--
function _INV:MoveItem( item, iOldSlot, iNewSlot, bPredict )
	if !IF.Util:IsItem( item )	then return self:Error( "Couldn't move item from one slot to another - item given was invalid!\n" ) end
	if !iNewSlot				then return self:Error( "Couldn't move "..tostring( item ).." from one slot to another - new slot wasn't given!\n" ) end
	
	if bPredict == nil then bPredict = CLIENT end
	
	local itemid = item:GetID();
	
	--Make sure that the given item is occupying a slot in this inventory (and that clientside this matches the old slot given)
	local s = self:GetItemSlotByID( itemid );
	if SERVER || bPredict then
		if !s then return self:Error( "Couldn't move "..tostring( item ).." from one slot to another - Wasn't in this inventory!\n" ) end
	else
		if !iOldSlot		then return self:Error( "Couldn't move "..tostring( item ).." from one slot to another - old slot wasn't given!\n" ) end
		if s != iOldSlot	then return self:Error( "Couldn't move "..tostring( item ).." from one slot to another - given item wasn't in given old slot! Netsync error?\n" ) end
	end
	
	--Can't move to anything but an empty slot
	if self:GetItemBySlot( iNewSlot ) != nil then
		if CLIENT && !bPredict then return self:Error( "Couldn't move "..tostring( item ).." from one slot to another - new slot has an item in it! Netsync error?\n" ) end
		return false;
	end
	
	--The CanMoveItem event gets to decide whether or not an item is allowed to move
	if ( SERVER || bPredict ) && !self:Event( "CanMoveItem", true, item, iOldSlot, iNewSlot ) then return false end
	
	if !bPredict then
		--Clear old slot
		self.Items[iOldSlot] = nil;
		
		--Register at new slot
		self.Items[iNewSlot] = item;
		self.ItemsByID[itemid] = iNewSlot;
		
		self:Event( "OnMoveItem", nil, item, iOldSlot, iNewSlot );
		
		--Refresh any UI displaying this inventory
		if CLIENT then self:Update(); end
	end
	
	return true;
end

--[[
* SHARED

Finds and returns the index of a free slot in this inventory, starting from the first slot.
Returns nil if all the slots are full.
]]--
function _INV:GetFreeSlot()
	--Finds the highest consecutive occupied index and returns the empty slot following it
	local n = #self.Items;
	local iHighestSlot = self:GetMaxSlots();
	
	if iHighestSlot == 0 || n != iHighestSlot then
		--Returns the empty slot following it
		return n + 1;
	end
	return nil;
end

--[[
* SHARED
* Internal

Takes an item out of the inventory. DO NOT CALL DIRECTLY - this is called automatically by other functions.
This function triggers the OnRemoveItem event. The item can be prevented from being taken out of the inventory serverside.

itemid is the ID of an item. We use the ID because it's possible the item no longer exists, and is being cleaned up.
If bForced is true, the OnRemoveItem event cannot stop the removal (bForced is usually set to true whenever the inventory's connected object is being removed, and items HAVE to be taken out)
bPredict is an optional true/false that defaults to false on the server and true on the client. If bPredict is:
	false, we are actually removing the item from this inventory.
	true, instead we are predicting whether or not we can remove the item from the inventory.

true is returned if the item was/can be removed successfully.
false is returned if the item cannot be removed (either due to an event or it can't be found in the inventory)
]]--
function _INV:RemoveItem( itemid, bForced, bPredict )
	if !IF.Util:IsNumber( itemid )	then return self:Error( "Cannot remove item... itemid wasn't given!\n" ) end
	if bForced	== nil				then bForced  = false	end
	if bPredict	== nil				then bPredict = CLIENT	end
	
	--[[
	This part is kind of tricky. This function can be used to take out an item, or clear the record of an item in this inventory.
	If it's the former, our CanRemoveItem event is called.
	CanRemoveItem exists on both the client and server. It's called on both, but the event can only stop it on the server, given that it wasn't forced.
	]]--	
	local iSlot = self:GetItemSlotByID( itemid );
	if iSlot == nil then return self:Error( "Tried to remove item "..itemid..", but it's not listed in this inventory.\n" ) end
	
	local item = IF.Items:Get( itemid );
	if !bForced && ( SERVER || bPredict ) && item && item:IsValid() && !self:Event( "CanRemoveItem", true, item, iSlot ) then return false end
	
	if !bPredict then
		self.Items[iSlot] = nil;
		self.ItemsByID[itemid] = nil;
		
		self:Event( "OnRemoveItem", nil, item, iSlot, bForced );
		
		--Update the inventory to tell the UI to refresh
		if CLIENT then self:Update(); end
	end
	
	return true;
end

--[[
* SHARED
* Internal
* Event

Connected entities will call this function if removed.
This function is written strangely for technical reasons.

eEntity is the entity that was removed.
self is this inventory.
]]--
function _INV.ConnectedEntityRemoved( eEntity, self )
	self:SeverEntity( eEntity.ConnectionSlot );
end


if SERVER then




--[[
* SERVER
* Internal

Sends a full update of this inventory to the given player.
This function calls the OnSendFullUpdate event.

TODO recursive send
]]--
function _INV:SendFullUpdate( pl )
	--Validate player
	if pl != nil then
		if !IF.Util:IsPlayer( pl )		then return self:Error( "Can't send full update - player given wasn't a valid player.\n" ) end
		if !self:CanNetwork( pl )		then return self:Error( "Can't send full update - player given wasn't the owner!\n" ) end
	else
		pl = self:GetOwner();
	end
	
	
	
	--DEBUG
	Msg( "OUT: Message Type: "..IFINV_MSG_INVFULLUP.." - Inventory: "..self:GetID().." - Player: "..tostring( pl ).."\n" );
	
	umsg.Start( "ifinv", pl );
	umsg.Char( IFINV_MSG_INVFULLUP );
	umsg.Short( self:GetID() - 32768 );
	umsg.Long( self:GetWeightCapacity() - 2147483648 );
	umsg.Long( self:GetSizeLimit() - 2147483648 );
	umsg.Long( self:GetMaxSlots() - 2147483648 );
	umsg.End();
	
	--Send connected objects
	for k, v in pairs( self.ConnectedObjects ) do
		if		v.Type == IFINV_CONTYPE_ITEM then	self:ConnectItem( v.Obj, pl );
		elseif	v.Type == IFINV_CONTYPE_ENT	 then	self:ConnectEntity( v.Obj, pl );
		end
	end
	
	--If we're locked tell that to the player(s)
	if self.Locked then	self:Lock( pl );
	else				self:Unlock( pl );
	end
	
	self:Event( "OnSendFullUpdate", nil, pl );
end




else




--[[
* CLIENT
* Internal

When a full update is received from the server, this function is called.
]]--
function _INV:RecvFullUpdate( iWeightCap, iSizeLimit, iMaxSlots )
	self:SetWeightCapacity( iWeightCap );
	self:SetSizeLimit( iSizeLimit );
	self:SetMaxSlots( iMaxSlots );
end




end