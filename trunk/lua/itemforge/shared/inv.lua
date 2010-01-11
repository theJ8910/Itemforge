--[[
Itemforge Inventory Module
SHARED

This implements inventories. It keeps track of inventories and syncs them.
TODO turn ifs into elseifs in respect to player validation
TODO allow inventories to reuse IDs like items
TODO allow inventories to have "soft weight caps" like fallout 3 (weight cap can be set and exceeded)
TODO when sending updates about connected items/entities check that they are still valid (I bound an inventory to a bot and after kicking him, had a null player bound to the inventory)
]]--

MODULE.Name="Inv";											--Our module will be stored at IF.Inv
MODULE.Disabled=false;										--Our module will be loaded
MODULE.MaxInventories=65535;								--How many unique inventories can exist at a single time?

if CLIENT then

MODULE.FullUpInProgress=false;								--If this is true a full update is being recieved from the server
MODULE.FullUpTarget=0;										--Whenever a full update starts, this is how many inventories need to be sent from the server.
MODULE.FullUpCount=0;										--Every time an inventory is created while a full update is being recieved, this number is increased by 1.
MODULE.FullUpInventoriesUpdated={};							--Every time an inventory is created while a full update is being recieved, FullUpInventoriesUpdated[Inventory ID] is set to true.

end

--These are local on purpose. I'd like people to use the Get function, and not grab the inventories directly from the table.
local BaseType="base_inv";									--This is the undisputed absolute base inventory-type. All inventories inherit from this type of inventory.
local InvTypes={};											--Registered inventory types are stored here.
local InventoryRefs={};										--Inventory references. One for every inventory. Allows us to pass this instead of the actual inventory. We can garbage collect removed inventories, giving some memory back to the game, while at the same time alerting scripters of careless mistakes (referencing an item after it's been removed)
local NextInventory=1;										--This is a pointer of types, that records where the next inventory will be made. IDs are assigned based on this number. This only serves as a starting point to search for a free ID. If this slot is taken then it will search through the entire inventory array once to look for a free slot.

--Itemforge Inventory (IFINV) Message (-128 to 127. Uses char in usermessage)
IFINV_MSG_CREATE			=	-128;	--(Server > Client) Sync create inventory clientside
IFINV_MSG_REMOVE			=	-127;	--(Server > Client) Sync remove inventory clientside
IFINV_MSG_REQFULLUP			=	-126;	--(Client > Server) Client requests full update of an inventory
IFINV_MSG_REQFULLUPALL		=	-125;	--(Client > Server) Client requests full update of all inventories (joining player)
IFINV_MSG_STARTFULLUPALL	=	-124;	--(Server > Client) This message tells the client that a full update of all inventories is going to being sent and how many to expect.
IFINV_MSG_ENDFULLUPALL		=	-123;   --(Server > Client) This message tells the client the full update of all inventories has finished.
IFINV_MSG_INVFULLUP			=	-122;	--(Server > Client) A full update on an inventory is being sent. This sends basic data about the inventory.
IFINV_MSG_WEIGHTCAP			=	-121;	--(Server > Client) The weight capacity of the inventory has changed serverside. Sync to client.
IFINV_MSG_SIZELIMIT			=	-120;	--(Server > Client) The size limit of the inventory has changed serverside. Sync to client.
IFINV_MSG_MAXSLOTS			=	-119;	--(Server > Client) The max number of slots was changed. Sync to client.
IFINV_MSG_CONNECTITEM		=	-118;	--(Server > Client) The inventory has connected itself with an item. Have client connect too.
IFINV_MSG_CONNECTENTITY		=	-117;	--(Server > Client) The inventory has connected itself with an entity. Have client connect too.
IFINV_MSG_SEVERITEM			=	-116;	--(Server > Client) The inventory is severing itself from an item. Have client sever as well.
IFINV_MSG_SEVERENTITY		=	-115;	--(Server > Client) The inventory is severing itself from an entity. Have client sever too.
IFINV_MSG_LOCK				=	-114;	--(Server > Client) The inventory has been locked serverside. Have client lock too.
IFINV_MSG_UNLOCK			=	-113;	--(Server > Client) The inventory has been unlocked serverside. Have client unlock too.

--Itemforge Inventory (IFINV) Connection Type.
IFINV_CONTYPE_ITEM			=1;			--Inventory connected to an item.
IFINV_CONTYPE_ENT			=2;			--Inventory connected to an entity.

--Itemforge Inventory Removal Actions... when an inventory is removed, the items should be:
IFINV_RMVACT_REMOVEITEMS	=	1;		--Removed along with the inventory
IFINV_RMVACT_VOIDITEMS		=	2;		--Voided (just take them out of the inventory and leave them in the void)
IFINV_RMVACT_SAMELOCATION	=	3;		--Sent to the same location as the item/entity this inventory was attached to before it was removed (in the case of multiple attachments at the time of removal, sends them to the same location as the first available connected object)

--Methods and default values for all inventories are stored here.
local _INV={};

--Initilize Inventory module
function MODULE:Initialize()
	self:RegisterType(_INV,BaseType);
end

--Clean up the inventory module. Currently I have this done prior to a refresh. It will remove any inventories.
function MODULE:Cleanup()
	Templates=nil;
	Inventories=nil;
	InventoryRefs=nil;
	InventoryCount=nil;
end

--[[
This function registers an inventory type. This should be done at initialization.

tClass should be a table defining the inventory type.
	TODO better description here
	See _INV towards the bottom of this file for an idea of what a table like this would look like.

sName is a name to identify the inventory type by, such as "inv_bucket". This name will be used for two things:
	When creating an inventory, the name of an inventory type can be given to make an inventory.
	Allowing one class to inherit from another.

true is returned if the type is registered, and false otherwise.
]]--
function MODULE:RegisterType(tClass,sName)
	if !sName then ErrorNoHalt("Itemforge Inventory: Couldn't register inventory type - name to register under wasn't given!\n"); return false end
	if !tClass then ErrorNoHalt("Itemforge Inventory: Couldn't register inventory type \""..sName.."\" - name of type wasn't given!\n"); return false end
	
	sName=string.lower(sName);
	if tClass.Base==nil then tClass.Base=BaseType; end
	
	if !IF.Base:RegisterClass(tClass,sName) then return false end
	
	--TODO What if inventory types are reloaded
	InvTypes[sName]=tClass;
	
	return true;
end

--[[
Returns a registered inventory type.
sName should be the name of the inventory type to get.
Returns nil if no inventory type by this name exists.
]]--
function MODULE:GetType(sName)
	if !sName then ErrorNoHalt("Itemforge Inventory: Couldn't grab inventory type - name of type wasn't given!\n"); return false end
	
	return InvTypes[string.lower(strName)];
end

--TODO I'm not satisfied with the way this function works; consider reworking it sometime
--[[
Searches the Inventories[] table for an empty slot.
iFrom is an optional number describing where to start searching in the table.
	If this number is not given, is over the max number of inventories, or is under 1, it will be set to 1.
This function will keep searching until:
	It finds an open slot.
	It has gone through the entire table once.
The index of an empty slot is returned if one is found, or nil is returned if one couldn't be found.
]]--
function MODULE:FindEmptySlot(iFrom)
	--Wrap around to 1 if iFrom wasn't given or was under zero or was over the inventory limit
	if !iFrom || iFrom>self.MaxInventories || iFrom<1 then iFrom=1; end
	
	local count=0;
	while count<self.MaxInventories do
		if InventoryRefs[iFrom]==nil then return iFrom end
		count=count+1;
		iFrom=iFrom+1;
		if iFrom>self.MaxInventories then iFrom=1 end
	end
	return nil;
end

--[[
Create a new inventory.
sType is an optional string, the name of an inventory-type.
	If this is given, the new inventory will be the given type (e.g. "inv_bucket"). Inventory types are registered with IF.Inv:RegisterType().
	If no inventory type is given, the default inventory type is used.
pOwner is an optional player that is only used serverside.
	Giving a pOwner for an inventory tells Itemforge that this inventory and any updates regarding it should only sent to a given player.
	This is useful if you want to create a private inventory for a player.
	Keeping an inventory private means other players have no way of knowing what an inventory is carrying at any given time, clientside at least.
	All inventories exist serverside.
	If no pOwner is given (or pOwner is nil) then the inventory is public.
id is only necessary clientside. Serverside, an ID will be picked automatically.
fullUpd also only applies clientside - if this is true, it will indicate that the creation of the inventory is being performed as part of a full update.
bPredict is an optional true/false that defaults to false on the server, and true on the client. If bPredict is:
	false, then if successful we'll register and return a new inventory. nil will be returned if unsuccessful for any reason.
	true, then if we determine the inventory can be created, a temporary inventory that can be used for further prediction tests will be returned. nil will be returned otherwise.
]]--
function MODULE:Create(sType,pOwner,id,fullUpd,bPredict)
	--If we're given an owner we need to validate it
	if pOwner!=nil then
		if !pOwner:IsValid() then ErrorNoHalt("Itemforge Inventory: Couldn't create an inventory owned by the given player - the player given no longer exists.\n"); return nil
		elseif !pOwner:IsPlayer() then ErrorNoHalt("Itemforge Inventory: Couldn't create an inventory owned by the given player - the entity given isn't a player!\n"); return nil end
	end
	
	if !sType then sType=BaseType;
	else sType=string.lower(sType); end
	
	if !IF.Base:ClassExists(sType) then
		ErrorNoHalt("Itemforge Inventory: Couldn't create inventory. \""..sType.."\" is not a registered.");
		return nil;
	elseif InvTypes[sType]==nil then
		ErrorNoHalt("Itemforge Inventory: Couldn't create inventory. \""..sType.."\" is a registered class, but is not an inventory-type. Naming conflicts can cause this error.");
		return nil;
	end
	
	if bPredict==nil then bPredict=CLIENT end
	
	--[[
	We need to find an ID for the soon-to-be created inventory.
	We'll either use an ID that is not in use at the moment, which is usually influenced by the number of inventories created so far
	or a requested ID likely sent from the server
	]]--
	local n;
	if SERVER || (bPredict && !id) then
		n=NextInventory;
		
		if InventoryRefs[n]!=nil then
			n=self:FindEmptySlot(n+1);
			
			if n==nil then
				if !bPredict then ErrorNoHalt("Itemforge Inventory: Couldn't create inventory - no free slots (all "..self.MaxInventories.." slots occupied)!\n"); end
				return nil;
			end
		end
		
		if !bPredict then
			NextInventory=n+1;
			if NextInventory>self.MaxInventories then NextInventory=1 end
		end
	else
		if id==nil then ErrorNoHalt("Itemforge Inventory: Could not create inventory clientside, the ID of the inventory to be created wasn't given!\n"); return nil end
		n=id;
	end
	
	--[[
	When a full update on an inventory is being performed, Create is called before updating it.
	That way if the inventory doesn't exist it's created in time for the update.
	We only need to keep track of the number of inventories updated when all inventories are being updated.
	]]--
	if CLIENT && fullUpd==true && self.FullUpInProgress==true && !bPredict then
		self.FullUpCount=self.FullUpCount+1;
		self.FullUpInventoriesUpdated[n]=true;
	end
	
	--Does the inventory exist already? No need to recreate it.
	--TODO possible bug here; what if a dead item clientside blocks new items with the same ID from being created?
	if InventoryRefs[n] then
		--We only need to bitch about this on the server. Full updates of an inventory clientside will tell the inventory to be created regardless of whether it exists or not. If it exists clientside we'll just ignore it.
		if SERVER && !bPredict then
			ErrorNoHalt("Itemforge Inventory: Could not create inventory with id "..n..". An inventory with this ID already exists!\n");
		end
		return nil;
	end
	
	if bPredict then n=0 end
	
	local newInv=IF.Base:CreateObject(sType);
	if !newInv then return nil end
	
	newInv.ID=n;
	if SERVER then newInv.Owner=pOwner; end
	if !bPredict then
		InventoryRefs[n]=newInv;
		
		--TODO predicted inventories need to initialize too but not do any networking shit
		newInv:Initialize(owner);
		
		--We'll tell the clients to create and initialize the inventory too. If a pOwner was given to send inventory updates to exclusively, the inventory will only be created clientside on that player.
		if SERVER then self:CreateClientside(newInv,pOwner) end
	end
	
	return newInv;
end

--[[
This will remove an existing inventory from the inventories collection. inventory:Remove() calls this.
inv should be an existing inventory.
lastConnection is the last connection this inventory had to an item or entity.
	It's a table, with two members, .Type and .Obj.
		Type will be IFINV_CONTYPE_ITEM or IFINV_CONTYPE_ENT.
		Obj will be the entity or item the inventory was connected to.
This function calls the inventory's OnRemove event.
True is returned if the item is removed successfully. False is returned if the item couldn't be removed, or if the item is already being removed.
]]--
function MODULE:Remove(inv,lastConnection)
	if !inv || !inv:IsValid() then ErrorNoHalt("Itemforge Inventory: Could not remove inventory - inventory doesn't exist!\n"); return false end
	if inv.BeingRemoved then return false;
	else inv.BeingRemoved=true;
	end
	
	local s,r=pcall(inv.OnRemove,inv,lastConnection);
	if !s then ErrorNoHalt(r.."\n"); r=false end
	
	--[[
	Sever any connections to items or entities
	We sever them in this function rather than independently, saves bandwidth
	There's different serverside and clientside behavior for the sever functions.
	]]--
	if SERVER then
		for k,v in pairs(inv.ConnectedObjects) do
			if v.Type==IFINV_CONTYPE_ITEM then
				inv:SeverItem(k,true);
			elseif v.Type==IFINV_CONTYPE_ENT then
				inv:SeverEntity(k,true);
			end
		end
	else
		for k,v in pairs(inv.ConnectedObjects) do
			if v.Type==IFINV_CONTYPE_ITEM then
				inv:SeverItem(k);
			elseif v.Type==IFINV_CONTYPE_ENT then
				inv:SeverEntity(k);
			end
		end
		
		--Unbind any bound panels
		inv:UnbindAllPanels();
	end
	
	--Remove the inventory from our collections.
	local id=inv:GetID();
	
	--[[
	Tell ALL clients to remove too
	Even if an inventory is private, it can change owners.
	It might have been public and then went private.
	To make sure the inventory is absolutely removed on all clients, we tell all clients to remove it.
	]]--
	if SERVER then self:RemoveClientside(id,nil); end
	
	InventoryRefs[id]=nil;
end

--[[
This returns a reference to an inventory with the given ID.
For all effective purposes this is the same thing as returning the actual inventory,
except it doesn't hinder garbage collection,
and helps by warning the scripter of careless mistakes (still referencing an inventory after it's been deleted).
]]--
function MODULE:Get(id)
	return InventoryRefs[id];
end

--[[
This returns a table containing references to all inventories
]]--
function MODULE:GetAll()
	local t={};
	for k,v in pairs(InventoryRefs) do
		if k!=0 then
			t[k]=v;
		end
	end
	return t;
end

--[[
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

i1 is the first item.
a1 is the new amount of the first item.
i2 is the second item.
a2 is the new amount of the second item.

Returns false if no weight caps will break by changing the amounts of the items.
Returns true if any weight cap will break by changing the amounts of the items.
]]--
function MODULE:DoWeightCapsBreak(i1,a1,i2,a2)
	local c1=i1 && i1:IsValid() && i1:GetContainer();
	local c2=i2 && i2:IsValid() && i2:GetContainer();
	
	--Neither item given is in an inventory (or no valid items were given)
	if !c1 && !c2 then
		return false;
	
	--Both items given are in the same inventory
	elseif c1==c2 then	
		local cap=c1:GetWeightCapacity();
		if cap==0 then return false end
		
		return (c1:GetWeightStored() + i1:GetWeight()*(a1-i1:GetAmount()) + i2:GetWeight()*(a2-i2:GetAmount()) > cap);
	--Both items are in inventories but not the same inventory
	elseif c1 && c2 then
		local cap1=c1:GetWeightCapacity();
		local cap2=c2:GetWeightCapacity();
		
		return (cap1!=0 && c1:GetWeightStored() + i1:GetWeight()*(a1-i1:GetAmount()) > cap1) || (cap2!=0 && c2:GetWeightStored() + i2:GetWeight()*(a2-i2:GetAmount()) > cap2);
	--Only one item given was in an inventory
	else
		--The item we want to deal with is the one that was in an inventory
		local i,c,a;
		if c1 then		i,c,a=i1,c1,a1;
		elseif c2 then	i,c,a=i2,c2,a2;
		end
		
		local cap=c:GetWeightCapacity();
		if cap==0 then return false end
		
		return (c:GetWeightStored() + i:GetWeight()*(a-i:GetAmount()) > cap);
	end
	
	return false;
end

--TEMPORARY
function MODULE:DumpInventoryRefs()
	dumpTable(InventoryRefs);
end

--TEMPORARY
function MODULE:DumpInventory(id)
	dumpTable(InventoryRefs[id]:GetTable());
end




--Serverside
if SERVER then




--[[
Asks the client to create an inventory clientside
inv is an existing inventory that needs to be created clientside.
pl is an optional argument (that can be nil). This is here for two purposes: In the case of a public inventory, this can be used to send the inventory to a player who needs it (like a connecting player). In the case of a private inventory, it's so only the owner receives the command to create the inventory.
If the inventory is private, pl can only be the owner. It will fail otherwise.
We'll send the owner of the inventory to the client as well. Even though private inventories are only sent to their owners, this is so the client can identify if the inventory is public or private.
]]--
function MODULE:CreateClientside(inv,pl,fullUpd)
	if !inv or !inv:IsValid() then ErrorNoHalt("Itemforge Inventory: Couldn't CreateClientside - Inventory given isn't valid!\n"); return false end
	
	--Validate player
	if pl!=nil then
		if !pl:IsValid() then ErrorNoHalt("Itemforge Inventory: Couldn't CreateClientside - The player to send inventory "..inv:GetID().." to isn't valid!\n"); return false;
		elseif !pl:IsPlayer() then ErrorNoHalt("Itemforge Inventory: Couldn't CreateClientside - The player to send inventory "..inv:GetID().." to isn't a player!\n"); return false;
		elseif !inv:CanSendInventoryData(pl) then ErrorNoHalt("Itemforge Inventory: Couldn't CreateClientside - Was asked to create inventory "..inv:GetID().." on a player other than the owner!\n"); return false; end
	else
		local allSuccess=true;
		for k,v in pairs(player.GetAll()) do
			if !self:CreateClientside(inv,v,fullUpd) then allSuccess=false end
		end
		return allSuccess;
	end
	
	--DEBUG
	Msg("OUT: Message Type: "..IFINV_MSG_CREATE.." - Inventory: "..inv:GetID().." - Player: "..tostring(pl).."\n");
	
	umsg.Start("ifinv",pl);
	umsg.Char(IFINV_MSG_CREATE);
	umsg.Short(inv:GetID()-32768);
	umsg.String(inv:GetType());
	umsg.Bool(fullUpd==true);
	umsg.End();
	
	return true;
end

--[[
Asks the client to remove an inventory clientside.
invid is the ID of an inventory to remove - not the actual inventory.
We use invid here instead of inv because the inventory has probably already been removed serverside, and we would need to run :GetID() on a non-existent inventory in that case
pl is optional - it can be used to ask a certain player to remove an inventory. If this is nil, all players will be asked to remove the inventory.
]]--
function MODULE:RemoveClientside(invid,pl)
	if invid==nil then ErrorNoHalt("Itemforge Inventory: Couldn't RemoveClientside... the inventory ID to remove wasn't given.\n"); return false end
	
	--Validate player
	if pl!=nil then
		if !pl:IsValid() then ErrorNoHalt("Itemforge Inventory: Couldn't RemoveClientside - The player to remove the inventory from isn't valid!\n"); return false;
		elseif !pl:IsPlayer() then ErrorNoHalt("Itemforge Inventory: Couldn't RemoveClientside - The player to remove the inventory from isn't a player!\n"); return false; end
	end
	
	--DEBUG
	Msg("OUT: Message Type: "..IFINV_MSG_REMOVE.." - Inventory: "..invid.." - Player: "..tostring(pl).."\n");
	
	umsg.Start("ifinv",pl);
	umsg.Char(IFINV_MSG_REMOVE);
	umsg.Short(invid-32768);
	umsg.End();
	
	return true;
end

--[[
Sends a full update on an inventory, as requested by a client usually.
If the inventory doesn't exist serverside then instead of a full update, the client will be told to remove that inventory.
Full updates are bandwidth consuming and should not be used unless necessary.
invid is the ID of the inventory to send an update of. We use the ID because, as previously stated, it's possible the inventory doesn't exist on the server.
pl is the player to send the update of the inventory to.
This returns true if successful, or false if not.
]]--
function MODULE:SendFullUpdate(invid,pl)
	if !invid then ErrorNoHalt("Itemforge Inventory: Couldn't SendFullUpdate... the inventory ID wasn't given.\n"); return false end
	
	--Validate player
	if pl!=nil then
		if !pl:IsValid() then ErrorNoHalt("Itemforge Inventory: Couldn't SendFullUpdate - The player to send inventory "..inv:GetID().." to isn't valid!\n"); return false;
		elseif !pl:IsPlayer() then ErrorNoHalt("Itemforge Inventory: Couldn't SendFullUpdate - The player to send inventory "..inv:GetID().." to isn't a player!\n"); return false; end
	end
	
	local inv=self:Get(invid);
	--[[
	If the inventory doesn't exist, or if the player we're sending this to isn't the owner,
	we tell the client who requested the update to get rid of it.
	]]--
	if !inv:IsValid() || !inv:CanSendInventoryData(pl) then
		self:RemoveClientside(invid,pl);
		
		return true;
	end
	
	self:CreateClientside(inv,pl);
	inv:SendFullUpdate(pl);
	return true;
end

--[[
Creates all inventories applicable (the inventories that aren't private) as part of a full update on a given player clientside.
pl is the player to create inventories on clientside. This can be a player or nil to send to all players
To do a full update on all items and inventories properly, all items should be created clientside first, then all inventories, then full updates of all items, and then full updates of all inventories.
True is returned if all the inventories were created on the given player. True is also returned if there were no inventories to send to the player.
If the given player was nil, this returns false if one of the players couldn't have all the inventories sent to him for some reason.
]]--
function MODULE:StartFullUpdateAll(pl)
	--Validate player
	if pl!=nil then
		if !pl:IsValid() then ErrorNoHalt("Itemforge Inventory: Couldn't start full update - The player to send inventories to isn't valid!\n"); return false;
		elseif !pl:IsPlayer() then ErrorNoHalt("Itemforge Inventory: Couldn't start full update - The player to send inventories to isn't a player!\n"); return false; end
	
	--pl is nil so we'll create the inventories clientside on each player individually
	else
		local allSuccess=true;
		for k,v in pairs(player.GetAll()) do
			if !self:StartFullUpdateAll(v) then allSuccess=false end
		end
		return allSuccess;
	end
	
	local invBuffer={};
	for k,v in pairs(InventoryRefs) do
		if k!=0 && v:CanSendInventoryData(pl) then table.insert(invBuffer,v) end
	end
	
	local c=table.getn(invBuffer);
	
	if c>0 then
		--DEBUG
		Msg("OUT: Message Type: "..IFINV_MSG_STARTFULLUPALL.." - Inventory: "..table.getn(invBuffer).." - Player: "..tostring(pl).."\n");
		
		umsg.Start("ifinv",pl);
		umsg.Char(IFINV_MSG_STARTFULLUPALL);
		umsg.Short(c-32768);
		umsg.End();
		
		local allCreated=true;
		for i=1,c do
			if !self:CreateClientside(invBuffer[i],pl,true) then allCreated=false end
		end
		return allCreated;
	end
	return true;
end

--Sends a full update on all inventories from the server
function MODULE:EndFullUpdateAll(pl)
	--Validate player
	if pl!=nil then
		if !pl:IsValid() then ErrorNoHalt("Itemforge Inventory: Couldn't EndFullUpdate - The player to send inventory "..inv:GetID().." to isn't valid!\n"); return false;
		elseif !pl:IsPlayer() then ErrorNoHalt("Itemforge Inventory: Couldn't EndFullUpdate - The player to send inventory "..inv:GetID().." to isn't a player!\n"); return false; end
	
	--pl is nil so we'll send full updates of the inventories clientside on each player individually
	else
		local allSuccess=true;
		for k,v in pairs(player.GetAll()) do
			if !self:EndFullUpdateAll(v) then allSuccess=false end
		end
		return allSuccess;
	end
	
	local c=#InventoryRefs;
	if c>0 then
		for k,v in pairs(InventoryRefs) do
			if k!=0 && v:CanSendInventoryData(pl) then v:SendFullUpdate(pl); end
		end
		
		--DEBUG
		Msg("OUT: Message Type: "..IFINV_MSG_ENDFULLUPALL.." - Inventory: 0 - Player: "..tostring(pl).."\n");
		
		umsg.Start("ifinv",pl);
		umsg.Char(IFINV_MSG_ENDFULLUPALL);
		umsg.Short(-32768);
		umsg.End();
		
		return true;
	end
	return true;
end

--If a player leaves we need to cleanup private inventories
function MODULE:CleanupInvs(pl)
	for k,v in pairs(InventoryRefs) do
		if v:GetOwner()==pl then
			v:SetOwner(nil);
		end
		
		--If the player is a connected object of an inventory...
		for i,c in pairs(v.ConnectedObjects) do
			if c.Obj==pl then
				print(v);
				v.ConnectedEntityRemoved(pl,v);
			end
		end
		
	end
end

--Handles incoming "ifinv" messages from client
function MODULE:HandleIFINVMessages(pl,command,args)
	if !pl || !pl:IsValid() || !pl:IsPlayer() then ErrorNoHalt("Itemforge Inventory: Couldn't handle incoming message from client - Player given doesn't exist or wasn't player!\n"); return false end
	if !args[1] then ErrorNoHalt("Itemforge Inventory: Couldn't handle incoming message from client - message type wasn't received.\n"); return false end
	if !args[2] then ErrorNoHalt("Itemforge Inventory: Couldn't handle incoming message from client - item ID wasn't received.\n"); return false end
	
	local msgType=tonumber(args[1]);
	local id=tonumber(args[2])+32768;
	
	--DEBUG
	Msg("IN:  Message Type: "..msgType.." - Inventory: "..id.." - Player: "..pl:Name().."\n");
	
	if msgType==IFINV_MSG_REQFULLUP then
		--Send a full update of the inventory to the client.
		self:SendFullUpdate(id,pl);
	elseif msgType==IFINV_MSG_REQFULLUPALL then
		self:StartFullUpdateAll(pl);
		self:EndFullUpdateAll(pl);
	else
		ErrorNoHalt("Itemforge Inventory: Unhandled IFINV message \""..msgType.."\"\n");
		return false;
	end
	return true;
end

--We use a proxy here so we can make HandleIFINVMessages a method (:) instead of a regular function (.)
concommand.Add("ifinv",function(pl,command,args) return IF.Inv:HandleIFINVMessages(pl,command,args) end);



--Clientside
else




--Called when a full update has started - We're expecting a certain number of inventories from the server
function MODULE:OnStartFullUpdateAll(count)
	self.FullUpInProgress=true;
	self.FullUpTarget=count;
end

--Called when a full update has ended. Did we get them all?
function MODULE:OnEndFullUpdateAll()
	if self.FullUpCount<self.FullUpTarget then
		Msg("Itemforge Inventory: Full inventory update only updated "..self.FullUpCount.." out of expected "..self.FullUpTarget.." inventories!\n");
	end
	
	--Remove non-updated inventories
	for k,v in pairs(InventoryRefs) do
		if k!=0 then
			if self.FullUpInventoriesUpdated[k]!=true then
				--DEBUG
				Msg("Itemforge Inventory: Removing inventory "..k.." - only exists clientside\n");
				
				v:Remove();
			end
		end
	end
	
	self.FullUpInProgress=false;
	self.FullUpTarget=0;
	self.FullUpCount=0;
	self.FullUpInventoriesUpdated={};
end

function MODULE:HandleIFINVMessages(msg)
	--Message type depends what happens next.
	local msgType=msg:ReadChar();
	local id=msg:ReadShort()+32768;
	
	if msgType==IFINV_MSG_CREATE then
		local type=msg:ReadString();
		local fullUpd=msg:ReadBool();
		
		--Create the inventory clientside too. Use the ID provided by the server.
		self:Create(type,nil,id,fullUpd,false);
	elseif msgType==IFINV_MSG_REMOVE then
		local inv=self:Get(id);
		if !inv then return false end
		
		--Remove the item clientside since it has been removed serverside. TODO, last connected object should be passed
		self:Remove(inv);
	elseif msgType==IFINV_MSG_STARTFULLUPALL then
		self:OnStartFullUpdateAll(id-1);	 --We subtract 1 from the count. This is what we wanted, as one of the invs is a null inventory reference and won't be updated.
	elseif msgType==IFINV_MSG_ENDFULLUPALL then
		self:OnEndFullUpdateAll();
	elseif msgType==IFINV_MSG_INVFULLUP then
		local inv=self:Get(id);
		if !inv then return false end
		
		local weightCap=msg:ReadLong()+2147483648;
		local sizeLimit=msg:ReadLong()+2147483648;
		local maxSlots=msg:ReadLong()+2147483648;
		
		inv:RecvFullUpdate(weightCap,sizeLimit,maxSlots);
	elseif msgType==IFINV_MSG_WEIGHTCAP then
		local inv=self:Get(id);
		if !inv then return false end
		
		local weightCap=msg:ReadLong()+2147483648;
		
		inv:SetWeightCapacity(weightCap);
	elseif msgType==IFINV_MSG_SIZELIMIT then
		local inv=self:Get(id);
		if !inv then return false end
		
		local sizeLimit=msg:ReadLong()+2147483648;
		
		inv:SetSizeLimit(sizeLimit);
	elseif msgType==IFINV_MSG_MAXSLOTS then
		local inv=self:Get(id);
		if !inv then return false end
		
		local maxSlots=msg:ReadLong()+2147483648;
		
		inv:SetMaxSlots(maxSlots);
	elseif msgType==IFINV_MSG_CONNECTITEM then
		local inv=self:Get(id);
		if !inv then return false end
		
		local itemid=msg:ReadShort()+32768;
		local item=IF.Items:Get(itemid);
		
		if !item || !item:IsValid() then ErrorNoHalt("Itemforge Inventory: Tried to connect a non-existent item with ID "..itemid.." to inventory "..id..".\n"); return false end
		
		local slot=msg:ReadShort()+32768;

		inv:ConnectItem(item,slot);
	elseif msgType==IFINV_MSG_CONNECTENTITY then
		local inv=self:Get(id);
		if !inv then return false end
		
		local ent=msg:ReadEntity();
		local slot=msg:ReadShort()+32768;
		
		inv:ConnectEntity(ent,slot);
	elseif msgType==IFINV_MSG_SEVERITEM then
		local inv=self:Get(id);
		if !inv then return false end
		
		local slot=msg:ReadShort()+32768;
		inv:SeverItem(slot);
	elseif msgType==IFINV_MSG_SEVERENTITY then
		local inv=self:Get(id);
		if !inv then return false end
		
		local slot=msg:ReadShort()+32768;
		inv:SeverEntity(slot);
	elseif msgType==IFINV_MSG_LOCK then
		local inv=self:Get(id);
		if !inv then return false end
		
		inv:Lock();
	elseif msgType==IFINV_MSG_UNLOCK then
		local inv=self:Get(id);
		if !inv then return false end
		
		inv:Unlock();
	else
		ErrorNoHalt("Itemforge Inventory: Unhandled IFINV message \""..msgType.."\"\n");
	end
end

--We use a proxy here so we can make HandleIFINVMessages a method (:) instead of a regular function (.)
usermessage.Hook("ifinv",function(msg) return IF.Inv:HandleIFINVMessages(msg) end);




end











--[[
Base Inventory
SHARED

The Base Inventory contains functions and default values available to all inventories.
]]--

--[[
Variables
This is a listing of vars that are stored on the server, client, or both.
Whatever these variables are set to are defaults, which can be overridden by a derived inventory class or by individual inventories themself.
]]--

_INV.Base="base_nw"								--Inventories are based off of base_nw, just like items
_INV.ID=0;										--This is the ID of the inventory. It's assigned automatically.
_INV.Items=nil;									--Collection of item references stored by this inventory. This can be sorted however you like. The index determines what position items are in in the GUI.
_INV.ItemsByID=nil;								--This collection can be used to convert item IDs into the slot the item is stored in on this table. In this table, keys (also known as the indexes) are the Item's ID, and the values are the index the items are stored at in inventory.Items.
_INV.ConnectedObjects=nil;						--These are the objects the inventory is connected with.
_INV.MaxSlots=0;								--How many slots for items does this inventory contain? If this is 0, there is no limit to the number of slots for items in an inventory.
_INV.WeightCapacity=0;							--The inventory can hold this much weight - set to 0 for infinite
_INV.SizeLimit=0;								--The inventory can hold items of this .Size or below. Setting to 0 will allow objects of any size to be placed in it.
_INV.RemoveOnSever=true;						--Automatically remove this inventory when it no longer has any connected items/ents? If this is false, when an inventory loses all of it's connections, it won't be removed.
_INV.RemovalAction=IFINV_RMVACT_SAMELOCATION;	--What this is set on determines what happens to the items in this inventory when the inventory is removed. The three possible values are IFINV_RMVACT_REMOVEITEMS, IFINV_RMVACT_VOIDITEMS, and IFINV_RMVACT_SAMELOCATION. An explanation for each of these is available at the top of this file.
_INV.Locked=false;								--If the inventory is locked, items can't be inserted into the inventory, and items in the inventory can't removed (unless forced), or interacted with by other players.
_INV.BeingRemoved=false;						--This will be true if the inventory is being removed. If this is true, trying to remove the inventory (again) will have no effect.

if SERVER then

_INV.Owner=nil;									--Updates to the inventory will only go to this player. If this is nil, updates will be sent to all players.

else

_INV.BoundPanels=nil;							--A panel that displays information about this inventory can bind itself to this inventory. Whenever the inventory updates itself, the panel's Update() function is called.

end




--[[
Removes this inventory (usually because the object the inventory is attached to has been removed)
If done serverside, informs the clients to do this as well.
]]--
function _INV:Remove(lastConnection)
	IF.Inv:Remove(self,lastConnection);
end

--[[
Set player who "owns" this inventory. Updates of the inventory will only be sent to this player (private inventory).
pl should be a player to send updates to, or nil if you want to send updates to all players (public inventory).
TODO need to check all network data to make sure it's respecting inventory owners
]]--
function _INV:SetOwner(pl)
	if pl!=nil then
		if !pl:IsValid()		then return self:Error("Cannot set owner. Given player was invalid.\n");
		elseif !pl:IsPlayer()	then return self:Error("Cannot set owner. Given player wasn't a player!\n") end
	end
	
	local oldOwner=self:GetOwner();
	
	--Record owner
	self.Owner=pl;
	
	--Create or remove the inventory clientside on certain players depending on owner change
	if pl!=nil then
		
		if oldOwner==nil then
			for k,v in pairs(player.GetAll()) do
				if v!=pl then IF.Inv:RemoveClientside(self:GetID(),v) end
			end
			
		elseif oldOwner!=pl then
			IF.Inv:RemoveClientside(self:GetID(),oldOwner)
			IF.Inv:SendFullUpdate(self:GetID(),pl)
		end
	
	elseif oldOwner!=nil then
		for k,v in pairs(player.GetAll()) do
			if v!=oldOwner then IF.Inv:SendFullUpdate(self:GetID(),v) end
		end
	end
	
	--Set owner of any items in this inventory
	for k,v in pairs(self.Items) do
		v:SetOwner(oldOwner,pl);
	end
end

--[[
Set weight capacity for this inventory in grams. If called serverside, the clients are instructed to set the weight capacity as well.
Note: If the weight capacity changes to something smaller than the current total weight, (e.g. there are 2000000 grams in the inventory, but the weight capacity is set to 1000000 grams)
items will not be removed to compensate for the weight capacity changing.
Set to 0 to allow limitless weight to be stored.
]]--
function _INV:SetWeightCapacity(cap,pl)
	if cap==nil		then return self:Error("Couldn't set weight capacity... amount to set wasn't given.\n") end
	if cap<0		then return self:Error("Can't set weight capacity to negative values! (Set to 0 if you want the inventory to store an infinite amount of weight)\n") end
	
	if SERVER && pl!=nil then
		if !pl:IsValid()								then return self:Error("Cannot set weight capacity. Given player was invalid.\n");
		elseif !pl:IsPlayer()							then return self:Error("Cannot set weight capacity. Given player wasn't a player!\n");
		elseif SERVER && !self:CanSendInventoryData(pl) then return self:Error("Cannot set weight capacity. Given player wasn't the owner of the inventory!\n") end
	end
	
	self.WeightCapacity=cap;
	
	--Update weight clientside too
	if SERVER then
		--DEBUG
		Msg("OUT: Message Type: "..IFINV_MSG_WEIGHTCAP.." - Inventory: "..self:GetID().." - Player: "..tostring(pl).."\n");
		
		umsg.Start("ifinv",pl or self:GetOwner());
		umsg.Char(IFINV_MSG_WEIGHTCAP);
		umsg.Short(self:GetID()-32768);
		umsg.Long(self:GetWeightCapacity()-2147483648);
		umsg.End();
	else
		self:Update();
	end
	
	return true;
end

--[[
Set size limit for this inventory. If called serverside, the clients are instructed to set the size limit as well.
Item size limit can be used to restrict objects of certain sizes from entering the inventory. For example, maybe your backpack can hold a soda can, but can't hold a desk. On the other hand, maybe a trailer's inventory could hold a desk.
Note: If the size limit changes, items will not be removed to compensate for the size limit changing.
Example: Item with size 506 is in inventory, but size limit changes to 500. The item is not taken out because the size limit changed.
]]--
function _INV:SetSizeLimit(sizelimit,pl)
	if sizelimit==nil	then return self:Error("Couldn't set size limit... sizelimit wasn't given.\n") end
	if sizelimit<0		then return self:Error("Can't set size limit to negative values! (Set to 0 to allow items of any size to be inserted)\n") end
	
	if SERVER && pl!=nil then
		if !pl:IsValid()						then return self:Error("Cannot set size limit. Given player was invalid.\n");
		elseif !pl:IsPlayer()					then return self:Error("Cannot set size limit. Given player wasn't a player!\n");
		elseif !self:CanSendInventoryData(pl)	then return self:Error("Cannot set size limit. Given player wasn't the owner of the inventory!\n") end
	end
	
	self.SizeLimit=sizelimit;
	
	--Update size limit clientside too
	if SERVER then
		--DEBUG
		Msg("OUT: Message Type: "..IFINV_MSG_SIZELIMIT.." - Inventory: "..self:GetID().." - Player: "..tostring(pl).."\n");
		
		umsg.Start("ifinv",pl or self:GetOwner());
		umsg.Char(IFINV_MSG_SIZELIMIT);
		umsg.Short(self:GetID()-32768);
		umsg.Long(sizelimit-2147483648);
		umsg.End();
	else
		self:Update();
	end
	
	return true;
end

--[[
Set max slots for this inventory. If called serverside, the clients are instructed to set the max slots as well.
A slot limit can be used to restrict how many items (or stacks of items) may be placed in this inventory. For example, maybe a weapon rack can only hold four items?
NOTE: If the max slots changes, items will not be removed to compensate for the max slots changing.
WARNING: If an item is in, say, slot 7, and max slots is changed to 5, you'll open up the inventory and see a closed slot where item 7 is supposed to be.
]]--
function _INV:SetMaxSlots(max,pl)
	if max==nil		then return self:Error("Couldn't set max number of slots... max wasn't given.\n") end
	if max<0		then return self:Error("Can't set max number of slots to negative values! (Set to 0 for infinite slots)\n") end
	
	if SERVER && pl!=nil then
		if !pl:IsValid()						then return self:Error("Cannot set max number of slots. Given player was invalid.\n");
		elseif !pl:IsPlayer()					then return self:Error("Cannot set max number of slots. Given player wasn't a player!\n");
		elseif !self:CanSendInventoryData(pl)	then return self:Error("Cannot set max number of slots. Given player wasn't the owner of the inventory!\n") end
	end
	
	self.MaxSlots=max;
	
	--Update max slots clientside too
	if SERVER then
		--DEBUG
		Msg("OUT: Message Type: "..IFINV_MSG_MAXSLOTS.." - Inventory: "..self:GetID().." - Player: "..tostring(pl).."\n");
		
		umsg.Start("ifinv",pl or self:GetOwner());
		umsg.Char(IFINV_MSG_MAXSLOTS);
		umsg.Short(self:GetID()-32768);
		umsg.Long(max-2147483648);
		umsg.End();
	else
		self:Update();
	end
	
	return true;
end

--Returns this inventory's ID
function _INV:GetID()
	return self.ID;
end

--Returns the name of the inventory-type this inventory uses.
function _INV:GetType()
	return self.ClassName;
end

--[[
Get the owner of this inventory.
This will return the player who owns it, or nil if this inventory isn't owned by anybody.
]]--
function _INV:GetOwner()
	return self.Owner;
end

--Returns the size limit for this inventory.
function _INV:GetSizeLimit()
	return self.SizeLimit;
end

--Get weight capacity for this inventory in kg.
function _INV:GetWeightCapacity()
	return self.WeightCapacity;
end

--Returns the maximum number of slots that this inventory supports.
function _INV:GetMaxSlots()
	return self.MaxSlots;
end

--Returns the total weight of all items stored in the inventory
function _INV:GetWeightStored()
	local totalweight=0;
	for k,v in pairs(self.Items) do
		if v:IsValid() then totalweight=totalweight+v:GetStackWeight(); end
	end
	return totalweight;
end

--Returns the amount of free weight storage left in the inventory.
function _INV:GetWeightFree()
	return self:GetWeightCapacity()-self:GetWeightStored();
end

--[[
Returns the position of the inventory in the world
If you get the position of an inventory, it returns the position(s) of the inventory's connected object(s).
	So, if our item is in an inventory connected with a barrel entity, it returns the position of the barrel entity.
	If our inventory is connected with, lets say, two bags that share the same inventory, then it returns both the position of the first bag and the second (as a table).
	
	If this is a player's inventory, it returns the player's position.
	If our item is in a bottle inside of a crate in the world, it returns the crate's position.
	If our inventory isn't connected with anything, it returns nil.
]]--
function _INV:GetPos()
	for k,v in pairs(self.ConnectedObjects) do
		if v.Obj:IsValid() then
			return v.Obj:GetPos()
		else
			--TODO cleanup
		end
	end
	return nil;
end

--[[
Locks the inventory.
If pl is given only locks for that player
]]--
function _INV:Lock(pl)
	if SERVER && pl!=nil then
		if !pl:IsValid()						then return self:Error("Cannot lock. Given player was invalid.\n");
		elseif !pl:IsPlayer()					then return self:Error("Cannot lock. Given player wasn't a player!\n");
		elseif !self:CanSendInventoryData(pl)	then return self:Error("Cannot lock. Given player wasn't the owner of the inventory!\n") end
	end
	
	local bWasLocked=false;
	if !self.Locked then
		self.Locked=true;
		self:Event("OnLock");
		bWasLocked=true;
	end
	
	if SERVER && (bWasLocked || pl) then
		--DEBUG
		Msg("OUT: Message Type: "..IFINV_MSG_LOCK.." - Inventory: "..self:GetID().." - Player: "..tostring(pl).."\n");
		
		umsg.Start("ifinv",pl or self:GetOwner());
		umsg.Char(IFINV_MSG_LOCK);
		umsg.Short(self:GetID()-32768);
		umsg.End();
	end
end

--[[
Unlocks the inventory.
If pl is given only unlocks for that player
]]--
function _INV:Unlock(pl)
	
	if SERVER && pl!=nil then
		if !pl:IsValid()						then return self:Error("Cannot unlock. Given player was invalid.\n");
		elseif !pl:IsPlayer()					then return self:Error("Cannot unlock. Given player wasn't a player!\n");
		elseif !self:CanSendInventoryData(pl)	then return self:Error("Cannot unlock. Given player wasn't the owner of the inventory!\n") end
	end
	
	local bWasUnlocked=false;
	if self.Locked then
		self.Locked=false;
		self:Event("OnUnlock");
		bWasUnlocked=true;
	end
	
	if SERVER && (bWasUnlocked || pl) then
		--DEBUG
		Msg("OUT: Message Type: "..IFINV_MSG_UNLOCK.." - Inventory: "..self:GetID().." - Player: "..tostring(pl).."\n");
		
		umsg.Start("ifinv",pl or self:GetOwner());
		umsg.Char(IFINV_MSG_UNLOCK);
		umsg.Short(self:GetID()-32768);
		umsg.End();
	end
end

--[[
Returns true if the inventory is locked.
Returns false otherwise.
]]--
function _INV:IsLocked()
	return self.Locked;
end

--[[
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
function _INV:IsBeneath(item)
	for k,v in pairs(self.ConnectedObjects) do
		if v.Type==IFINV_CONTYPE_ITEM then
			if v.Obj==item then return true end
			local container=v.Obj:GetContainer();
			if container!=nil && container:IsBeneath(item) then return true end
		end
	end
	return false;
end

--[[
Returns the first item in the inventory (slot-wise), or nil if the inventory is empty.
]]--
function _INV:GetFirst()
	if self:IsEmpty() then return nil end
	local i=1;
	while self.Items[i]==nil do
		i=i+1;
	end
	return self.Items[i];
end

--[[
Returns the last item in the inventory (slot-wise), or nil if the inventory is empty.
]]--
function _INV:GetLast()
	if self:IsEmpty() then return nil end
	return self.Items[table.maxn(self.Items)];
end

--[[
Returns true if this inventory is empty. Returns false otherwise.
]]--
function _INV:IsEmpty()
	if table.maxn(self.Items)==0 then return true; end
	return false;
end

--[[
Returns the number of items stored in this inventory.
]]--
function _INV:GetCount()
	local c=0;
	for k,v in pairs(self.Items) do c=c+1; end
	return c;
end

--[[
Give this function an item ID and it will return the slot the item occupies in this inventory.
If the item isn't in the inventory, nil is returned.
]]--
function _INV:GetItemSlotByID(itemid)
	return self.ItemsByID[itemid];
end

--[[
Returns an item with the given slot in this inventory.
If there's no item in this inventory slot, nil is returned.
]]--
function _INV:GetItemBySlot(slot)
	if self.Items[slot] then
		local item=self.Items[slot];
		if item:IsValid() then
			return self.Items[slot];
		else
			self.Items[slot]=nil;
			return nil;
		end
	end
	return nil;
end

--[[
Returns an item with the given type in this inventory.
If there's no item with this type in the inventory (or there are errors), nil is returned.
If there are several items of this type in the inventory, then the first item found with this type is returned.
]]--
function _INV:GetItemByType(sItemtype)
	if !sItemtype then self:Error("Can't find a specific item-type - the type of item to find wasn't given!\n"); return nil end
	sItemtype=string.lower(sItemtype);
	
	for k,v in pairs(self.Items) do
		if v:IsValid() then
			if v:GetType()==sItemtype then return v end
		else
			--INVALID - Item was removed but not taken out of inventory for some reason
			self:Error("Found an item (slot "..k..") that no longer exists but is still recorded as being in this inventory.\n");
		end
	end
	return nil;
end

--[[
Returns a table of items with the given type in this inventory.
Returns nil if there are errors.
]]--
function _INV:GetItemsByType(sItemtype)
	if !sItemtype then self:Error("Can't find items of a specific item-type - the type of item to find wasn't given!\n"); return nil end
	local sItemtype=string.lower(sItemtype);
	
	local items={};
	for k,v in pairs(self.Items) do
		if v:IsValid() then
			if v:GetType()==sItemtype then table.insert(items,v) end
		else
			--INVALID - Item was removed but not taken out of inventory for some reason
			self:RemoveItem(k,true,false);
			self:Error("Found an item (slot "..k..") that no longer exists but is still listed as being in this inventory\n");
		end
	end
	
	return items;
end

--[[
Returns a table of all items in this inventory
]]--
function _INV:GetItems()
	local t={};
	for k,v in pairs(self.Items) do
		t[k]=v;
	end
	return t;
end

--Returns a table of all items connected (via ConnectItem) to this inventory.
function _INV:GetConnectedItems()
	local t={};
	for k,v in pairs(self.ConnectedObjects) do
		if v.Type==IFINV_CONTYPE_ITEM then
			table.insert(t,v.Obj);
		end
	end
	return t;
end

--Returns a table of all entities connected (via ConnectEntity) to this inventory.
function _INV:GetConnectedEntities()
	local t={};
	for k,v in pairs(self.ConnectedObjects) do
		if v.Type==IFINV_CONTYPE_ENT then
			table.insert(t,v.Obj);
		end
	end
	return t;
end

--[[
Returns a string describing the connections the inventory has.
]]--
function _INV:GetConnectionString()
	local count=#self.ConnectedObjects;
	local connectedTo="nothing";
	--Only one connection
	if count==1 then
		if self.ConnectedObjects[1].Type==IFINV_CONTYPE_ITEM then
			connectedTo=tostring(self.ConnectedObjects[1].Obj);
		elseif self.ConnectedObjects[1].Type==IFINV_CONTYPE_ENT then
			connectedTo=tostring(self.ConnectedObjects[1].Obj);
		end
	
	--Several connections
	elseif count>1 then
		local itemCount=#self:GetConnectedItems();
		local entCount=#self:GetConnectedEntities();
		
		--Several items, no entities
		if itemCount>1 && entCount==0 then
			if itemCount < 5 then
				local items=self:GetConnectedItems();
				connectedTo=tostring(items[1]);
				for i=2,itemCount do connectedTo=connectedTo..", "..tostring(items[i]); end
			else
				connectedTo=itemCount.." items";
			end
		--Several entities, no items
		elseif itemCount==0 && entCount>1 then
			if entCount < 5 then
				local entities=self:GetConnectedEntities();
				connectedTo=tostring(entities[1]);
				for i=2,entCount do connectedTo=connectedTo..", "..tostring(entities[i]); end
			else
				connectedTo=itemCount.." entities";
			end
		
		--Both entities and items, but only a few
		elseif count < 5 then
			connectedTo=tostring(self.ConnectedObjects[1].Obj);
			for i=2,count do connectedTo=connectedTo..", "..tostring(self.ConnectedObjects[i].Obj); end
		
		--Many entities and items
		else
			connectedTo=itemCount.." items, "..entCount.." entities";
		end
	end
	return connectedTo;
end

--[[
When tostring() is used on this inventory, this function returns a string describing the inventory.
Format: "Inventory ID [COUNT items @ LOCATION]" 
Ex:     "Inventory 12 [20 items @ Player [1][theJ89] ]" (Inventory 12, storing 20 items, attached to Player 1: theJ89)
]]--
function _INV:ToString()
	return "Inventory "..self:GetID().." ["..self:GetCount().." items @ "..self:GetConnectionString().."]";
end

--[[
Clears the record of all items currently in this inventory. This will not manually remove each item. You shouldn't need to call this function.
NOTE: This only clears the record of any items in the inventory.
]]--
--[[
function _INV:RemoveAll()
	self.Items={};
	self.ItemsByID={};
	if CLIENT then self:Update(); end
end
]]--



--Serverside
if SERVER then




--[[
Checks if inventory data can be sent to a player.
If we have an owner, then it's important to check who we're sending this to.
Inventory data cannot be sent to players (because the data needs to be private) other than the owner of the inventory, if the inventory is private.
pl can be a certain player or nil (to show that you want to send to everybody)
Returns true if it can, false otherwise
]]--
function _INV:CanSendInventoryData(pl)
	local owner=self:GetOwner();
	if owner!=nil && pl!=owner then
		return false;
	end
	return true;
end

--[[
This command is used to tie this inventory to an item.
If an inventory is connected with an item, it means that the inventory is a part of it. If the item is removed, then the connection is severed.
An inventory can have several connected objects.
When an inventory loses all of it's connections, it's removed.
If there are items in the inventory at the time it's removed, it's items are moved to the same location as the last object it was connected with.

item should be an item.
pl is an optional player to connect the item on. If no player is given, it will connect the item on all players clientside. If the item is already connected, it will just tell this player to connect the item clientside.
TODO: Allow items/ents to connect serverside even if they can't connect clientside
]]--
function _INV:ConnectItem(item,pl)
	if !item || !item:IsValid() then return self:Error("Couldn't connect item... item given was invalid.\n") end
	
	--Validate player if one was given
	if pl!=nil then
		if !pl:IsValid()		then return self:Error("Couldn't connect "..tostring(item).." - The player to connect this to clientside was invalid!\n");
		elseif !pl:IsPlayer()	then return self:Error("Couldn't connect "..tostring(item).." - The player to connect this to clientside wasn't a player!\n") end
	end
	
	--We'll connect the item on either the given player or the inventory owner.
	local who=pl or self:GetOwner();
	
	if !self:CanSendInventoryData(pl) then return self:Error("Couldn't connect "..tostring(item).." - player(s) given were not the owners of this inventory!\n") end
	
	--Check to see if this item is connected already... if it is, grab the connection slot it's in.
	local i=0;
	for k,v in pairs(self.ConnectedObjects) do
		if v.Obj==item then
			i=k;
			break;
		end
	end
	
	--If the item isn't connected, connect
	if i==0 then
		local newCon={};
		newCon.Type=IFINV_CONTYPE_ITEM;
		newCon.Obj=item;
		
		i=table.insert(self.ConnectedObjects,newCon);
		item:ConnectInventory(self,i);
	end
	
	--DEBUG
	Msg("OUT: Message Type: "..IFINV_MSG_CONNECTITEM.." - Inventory: "..self:GetID().." - Player: "..tostring(pl or self:GetOwner()).."\n");
	
	--Connect the item on the given player(s)
	umsg.Start("ifinv",who);
	umsg.Char(IFINV_MSG_CONNECTITEM);
	umsg.Short(self:GetID()-32768);
	umsg.Short(item:GetID()-32768);
	umsg.Short(i-32768);
	umsg.End();
	
	return true;
end

--[[
This command is used to tie this inventory to an entity.
If an inventory is connected with an entity, it means that the inventory is a part of it. If the entity is removed, then the connection is severed.
An inventory can have several connected objects.
When an inventory loses all of it's connections, it's removed.
If there are items in the inventory at the time it's removed, it's items are moved to the same location as the last object it was connected with.

ent should be an entity.
pl is an optional player to connect the entity on. If no player is given, it will connect the entity on all players clientside. If the entity is already connected, it will just tell this player to connect the item clientside.
TODO: Nil recursively connects on every connected player
TODO: Allow items/ents to connect serverside even if they can't connect clientside
]]--
function _INV:ConnectEntity(ent,pl)
	if !ent || !ent:IsValid() then return self:Error("Couldn't connect entity... entity given was invalid.\n") end
	
	--Validate player
	if pl!=nil then
		if !pl:IsValid()		then return self:Error("Couldn't connect "..tostring(ent).." - The player to connect this to clientside wasn't a player!\n");
		elseif !pl:IsPlayer()	then return self:Error("Couldn't connect "..tostring(ent).." - The player to connect this to clientside wasn't a player!\n"); end
	end
	
	--We'll connect the item on either the given player or the inventory owner.
	local who=pl or self:GetOwner();
	
	if !self:CanSendInventoryData(who) then return self:Error("Couldn't connect entity - player(s) given were not the owners of this inventory!\n") end
	
	--Check to see if this ent is connected already... if it is, grab the connection slot it's in.
	local i=0;
	
	for k,v in pairs(self.ConnectedObjects) do
		if v.Obj==ent then
			i=k;
			break;
		end
	end
	
	--If the entity isn't connected, connect
	if i==0 then
		local newCon={};
		newCon.Type=IFINV_CONTYPE_ENT;
		newCon.Obj=ent;
		
		i=table.insert(self.ConnectedObjects,newCon);
		if !ent:IsPlayer() then ent:CallOnRemove("ifinv_"..self:GetID().."_connect",self.ConnectedEntityRemoved,self); end
		ent.ConnectionSlot=i;
	end
	
	--DEBUG
	Msg("OUT: Message Type: "..IFINV_MSG_CONNECTENTITY.." - Inventory: "..self:GetID().." - Player: "..tostring(pl).."\n");
		
	--Send inventory data to given player(s)
	umsg.Start("ifinv",who);
	umsg.Char(IFINV_MSG_CONNECTENTITY);
	umsg.Short(self:GetID()-32768);
	umsg.Entity(ent);
	umsg.Short(i-32768);
	umsg.End();
	
	return true;
end

--[[
This command is used to untie this inventory from an item.
slot is a slot to sever.
bNotClient is an optional true/false that you can give. If this is true, we won't tell clients to sever the connection between the item and the inventory.
]]--
function _INV:SeverItem(slot,bNotClient)
	if !slot												then return self:Error("Couldn't sever item - slot to sever wasn't given.\n") end
	if !self.ConnectedObjects[slot]							then return self:Error("Couldn't sever item... there is no connected object on slot "..slot..".\n") end
	if self.ConnectedObjects[slot].Type!=IFINV_CONTYPE_ITEM then return self:Error("Couldn't sever item... the connected object on slot "..slot.." is not an item.\n") end
	
	--Break one-way connection between item and inventory, if the item is still valid
	local item=self.ConnectedObjects[slot].Obj;
	if item:IsValid() then item:SeverInventory(self); end
	
	local thisCon=self.ConnectedObjects[slot];
	
	--Break one-way connection between inventory and item
	self.ConnectedObjects[slot]=nil;
	
	--If the last connection was removed, inventory fizzles (if the inventory fizzles we'll stop the function before it networks data, we can take care of the removal of attached objects via the inventory's removal both serverside and clientside)
	if table.getn(self.ConnectedObjects)==0 then
		self:Remove(thisCon);
		return true;
	end
	
	if !bNotClient then
		--DEBUG
		Msg("OUT: Message Type: "..IFINV_MSG_SEVERITEM.." - Inventory: "..self:GetID().." - Player: "..tostring(nil).."\n");
		
		umsg.Start("ifinv",nil);
		umsg.Char(IFINV_MSG_SEVERITEM);
		umsg.Short(self:GetID()-32768);
		umsg.Short(slot-32768);
		umsg.End();
	end
end

--[[
This command is used to untie this inventory from an entity.
ent is the ent to sever. This is only necessary serverside, to confirm that the ent is in the inventory and to find the slot to send to the client.
slot is an optional true/false that you can give. If this is true, we won't tell clients to sever the connection between the entity and the inventory.
]]--
function _INV:SeverEntity(slot,bNotClient)
	if !slot												then return self:Error("Couldn't sever entity - slot to sever wasn't given.\n") end
	if !self.ConnectedObjects[slot]							then return self:Error("Couldn't sever entity... there is no connected object on slot "..slot..".\n") end
	if self.ConnectedObjects[slot].Type!=IFINV_CONTYPE_ENT	then return self:Error("Couldn't sever entity... the connected object on slot "..slot.." is not an entity.\n") end
	
	local ent=self.ConnectedObjects[slot].Obj;
	if ent:IsValid() then ent:RemoveCallOnRemove("ifinv_"..self:GetID().."_connect"); ent.ConnectionSlot=nil; end
	
	local thisCon=self.ConnectedObjects[slot];
	self.ConnectedObjects[slot]=nil;
	
	--Last connection removed, inventory fizzles
	if table.getn(self.ConnectedObjects)==0 then
		self:Remove(thisCon);
		return true;
	end
	
	if !bNotClient then
		--DEBUG
		Msg("OUT: Message Type: "..IFINV_MSG_SEVERENTITY.." - Inventory: "..self:GetID().." - Player: "..tostring(nil).."\n");
		
		umsg.Start("ifinv",nil);
		umsg.Char(IFINV_MSG_SEVERENTITY);
		umsg.Short(self:GetID()-32768);
		umsg.Short(slot-32768);
		umsg.End();
	end
end




--Clientside
else




--[[
This function is called whenever an update occurs to the inventory(it's created, an item is added, an item removed, item inside of this inventory weight/amount changes, etc).
This should be called whenever the UI needs to be updated.
]]--
function _INV:Update()
	for k,v in pairs(self.BoundPanels) do
		if v:IsValid() then v:InventoryUpdate(self);
		else self.BoundPanels[k]=nil;
		end
	end
end

--Bind a panel to this inventory. This will add it to this inventory's list of connected panels. Whenever the inventory :Update()s itself, the bound panel will be alerted.
function _INV:BindPanel(panel)
	if !panel || !panel:IsValid() then return self:Error("Itemforge Inventory: Couldn't bind panel - a valid panel was not given.\n") end
	
	--Make sure we're not binding an already bound panel
	for k,v in pairs(self.BoundPanels) do
		if panel==v then return false; end
	end
	
	if !panel:InventoryBind(self) then end
	
	--Insert this panel into our collection of bound panels
	table.insert(self.BoundPanels,panel);
end

--Unbind a panel bound from this inventory.
function _INV:UnbindPanel(panel)
	--Find this panel first in our collection..
	for k,v in pairs(self.BoundPanels) do
		--If we make a match...
		if panel==v then
			self.BoundPanels[k]=nil;										--Then remove this panel from our collection
			if panel.InventoryUnbind then panel:InventoryUnbind(self); end	--Tell it that the inventory unlinked it
			
			return true;
		end
	end
	return false;
end

--Unbind all panels (inventory removed most likely)
function _INV:UnbindAllPanels()
	for k,v in pairs(self.BoundPanels) do
		--Tell each panel that the inventory unlinked it
		if v:IsValid() && v.InventoryUnbind then v:InventoryUnbind(self); end
	end
	
	--Set it to an empty table, clear all connections
	self.BoundPanels={};
	
	return true;
end








end


--[[
INVENTORY EVENTS
]]--




--[[
Returns the title of the inventory.
This is displayed on the GUI when the inventory is opened on-screen.
By default, the inventory title is the name of the first connected object found.
You can override this to return whatever you like (as long as it's a string).
The advantage of doing this is when you have two or more inventories on a single item (for example, a vending machine), you can give each inventory a different title ("Products" and "Profits", for example).
]]--
function _INV:GetTitle()
	for k,v in pairs(self.ConnectedObjects) do
		if v.Type==IFINV_CONTYPE_ITEM && v.Obj:IsValid() then
			return v.Obj:GetName();
		end
	end
	return "Inventory";
end

--[[
Called when moving an item in this inventory from one slot to another.
item is the item being moved.
oldslot is the slot the item is currently in.
newslot is the slot the item wants to move to.
Return false to stop the item from moving, or return true to allow it to move.
]]--
function _INV:CanMoveItem(item,oldslot,newslot)
	return true;
end

--[[
Called after an item in this inventory has been moved from one slot to another.
item is the item being moved.
oldslot was the slot the item was occupying before.
newslot is the slot the item is now occupying.
]]--
function _INV:OnMoveItem(item,oldslot,newslot)

end

--[[
Called when inserting an item into the inventory.
This can be used to stop an item from entering this inventory.
item is the item being inserted.
slot is the slot in the inventory that the item will be placed in.
Return false to stop the item from being inserted, or true to allow it to be inserted.
]]--
function _INV:CanInsertItem(item,slot)
	return !self.Locked;
end

--[[
Called after an item has been inserted.
item is the item being inserted.
slot is the slot in the inventory that the item was placed in.
]]--
function _INV:OnInsertItem(item,slot)
end

--[[
Called when taking an item out of the inventory.
item is the item that wants to be taken out.
slot is the slot this item is occupying in this inventory.
Return true to allow the item to be taken out, or false to stop the item from being taken out.
]]--
function _INV:CanRemoveItem(item,slot)
	return !self.Locked;
end

--[[
Called after an item has been taken out of the inventory.
item is the item that was taken out.
slot is the slot this item was in.
forced will be true or false.
	If forced is true, then the item HAD to come out (this inventory was removed, the item was removed, etc).
	If forced is false, this was a normal removal (we just moved the item somewhere else)
]]--
function _INV:OnRemoveItem(item,slot,forced)
end

--[[
Called after the inventory has been locked.
]]--
function _INV:OnLock()
end

--[[
Called after the inventory has been unlocked.
]]--
function _INV:OnUnlock()
end

--[[
Can a player interact with an item in this inventory?
When an item's CanPlayerInteract event is called, this function lets it's container have a say in whether or not we can interact with it.

player is the player who wants to interact with an item in this inventory.
item is the item being interacted with.

Return true to allow the player to interact with items in this inventory,
or false to stop players from interacting with items in this inventory.
]]--
function _INV:CanPlayerInteract(player,item)
	--Can't interact with this inventory if the player doesn't own it
	if SERVER && !self:CanSendInventoryData(player) then return false end
	
	--Can't interact with this inventory if we can't interact with the inventory's connected objects
	for k,v in pairs(self:GetConnectedItems()) do
		if !v:Event("CanPlayerInteract",false,player) then return false end
	end
	return !self.Locked;
end

--Called prior to the inventory being removed
function _INV:OnRemove(lastConnection)
	--Deal with items in this inventory at the time of removal
	--Items will be taken care of serverside AND clientside (rather than just removing them serverside and individually removing each one clientside, we roll it all into one function here to save bandwidth/reduce lag)
	if SERVER then
		if self.RemovalAction==IFINV_RMVACT_REMOVEITEMS || !lastConnection then
			for k,v in pairs(self.Items) do
				--Assert that items are still valid and still consider themselves part of this inventory
				if v:IsValid() && v:InInventory(self) then
					v:Remove();
				end
			end
		elseif self.RemovalAction==IFINV_RMVACT_SAMELOCATION then
			--TODO THIS SUCKS, it should force removal of the items instead of unlocking it here
			self.Locked=false;
			if lastConnection.Type==IFINV_CONTYPE_ITEM then
				for k,v in pairs(self.Items) do
					--Assert that items are still valid and still consider themselves part of this inventory
					if v:IsValid() && v:InInventory(self) then
						v:ToSameLocationAs(lastConnection.Obj,true);
					end
				end
			elseif lastConnection.Type==IFINV_CONTYPE_ENT then
				for k,v in pairs(self.Items) do
					--Assert that items are still valid and still consider themselves part of this inventory
					if v:IsValid() && v:InInventory(self) then
						--TODO inventory's last connection was an entity
					end
				end
			end
		elseif self.RemovalAction==IFINV_RMVACT_VOIDITEMS then
			for k,v in pairs(self.Items) do
				v:ToVoid(true,self,true);
			end
		end
	else
		if self.RemovalAction==IFINV_RMVACT_VOIDITEMS then
			for k,v in pairs(self.Items) do
				v:ToVoid(true,self,nil,false);
			end
		end
	end
end




if SERVER then




--[[
Called when a full update is being sent. You can put some stuff here to send along with it if you like.
pl is the player who the full update is being sent to.
]]--
function _INV:OnSendFullUpdate(pl)
	
end




else




--[[
Returns the icon of the inventory.
This is displayed on the GUI when an inventory is opened on-screen (in the little circular thing at the top left on ItemforgeInventory)
By default, the inventory icon is the icon of the first connected object found.
You can override this to return whatever you like (as long as it's a material or nil).
The advantage of doing this is when you have two or more inventories on a single item (like a refridgerator, for example) you can give each one a different icon.
]]--
function _INV:GetIcon()
	for k,v in pairs(self.ConnectedObjects) do
		if v.Type==IFINV_CONTYPE_ITEM && v.Obj:IsValid() then
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




--This is called to initialize a newly created inventory.
function _INV:Initialize()
	self.Items={};
	self.ItemsByID={};
	self.ConnectedObjects={};
	if CLIENT then
		self.BoundPanels={};
	end
end

--[[
Sends a full update of this inventory to the given player
This function calls the OnSendFullUpdate event. You can 
]]--
function _INV:SendFullUpdate(pl)
	--Validate player
	if pl!=nil then
		if !pl:IsValid()				then return self:Error("Can't send full update - player given wasn't valid.\n");
		elseif !pl:IsPlayer()			then return self:Error("Can't send full update - player given wasn't a player!\n") end
	end
	
	if !self:CanSendInventoryData(pl)	then return self:Error("Can't send full update: Given player(s) were not the owner!\n") end
	
	--DEBUG
	Msg("OUT: Message Type: "..IFINV_MSG_INVFULLUP.." - Inventory: "..self:GetID().." - Player: "..tostring(pl).."\n");
	
	umsg.Start("ifinv",pl);
	umsg.Char(IFINV_MSG_INVFULLUP);
	umsg.Short(self:GetID()-32768);
	umsg.Long(self:GetWeightCapacity()-2147483648);
	umsg.Long(self:GetSizeLimit()-2147483648);
	umsg.Long(self:GetMaxSlots()-2147483648);
	umsg.End();
	
	--Send connected objects
	for k,v in pairs(self.ConnectedObjects) do
		if v.Type==IFINV_CONTYPE_ITEM then
			self:ConnectItem(v.Obj,pl);
		elseif v.Type==IFINV_CONTYPE_ENT then
			self:ConnectEntity(v.Obj,pl);
		end
	end
	
	--If we're locked tell that to the player(s)
	if self.Locked then	self:Lock(pl);
	else				self:Unlock(pl);
	end
	
	self:Event("OnSendFullUpdate",nil,pl);
end

--[[
Adds an item into this inventory.
DO NOT CALL DIRECTLY - this is called automatically by other functions.

When this function is run, it triggers the OnInsertItem event, both clientside and serverside.
Serverside, the OnInsertItem event can stop the item from being inserted.

item is the item/stack of items to insert.

slotnum's use varies by what side it's on:
	Serverside, If a specific slot is requested, we'll try to add it there. If it doesn't work for some reason, we'll fail. This can be nil to accept any slot.
	Clientside, It's necessary to provide slotnum to prevent netsync errors.
bNoSplit is an optional true/false. If item is a stack that weighs too much to fit the all the items in this inventory, and bNoSplit is:
	false or not given, we'll determine how many items in the stack can fit in the inventory, and then split off that many items into a seperate stack.
	true, we'll return false (because we're basically saying we want the whole stack or no stack in there).
bPredict is an optional true/false that defaults to false on the server and true on the client. If bPredict is:
	false, we are actually inserting the item into this inventory.
	true, we are returning true/false if it is possible to insert the item into the inventory.

The clients are instructed to add the item automatically by the Item's ToInventory function.
Use the item's ToInventory() function and pass this inventory's ID.
False is returned if the item could not be inserted for any reason, otherwise the slot for the item to use in the inventory is returned.
]]--
function _INV:InsertItem(item,slotnum,bNoSplit,bPredict)
	if !item || !item:IsValid() then return self:Error("Couldn't add item... given item was invalid.\n") end
	
	if bPredict==nil then bPredict=CLIENT end
	
	local itemid=item:GetID();
	
	--If the item is in this inventory already, we'll just return the slot it's in
	local s=self:GetItemSlotByID(itemid);
	if s!=nil then return s end
			
	--Lets insert this item to a slot in this inventory.
	local i=1;
	if SERVER || bPredict then
		--Do we have a given slot?
		if slotnum then
			--Is the given slot open? If it is, we can insert/move the item to that slot.
			if self.Items[slotnum]==nil then
				i=slotnum;
			--We can't insert/move into that slot, it's taken
			else
				return false;
			end
		--Lets search for an empty slot since no slot was given
		else
			i=self:GetFreeSlot();
			
			--If there are no free slots, fail
			if !i then return false end
		end
		
		
		--We're not trying to pull a loophole by putting an item into itself are we?
		--Also, is the item being inserted small enough to fit inside this inventory?
		if self:IsBeneath(item) || (self:GetSizeLimit()!=0 && item:GetSize()>self:GetSizeLimit()) || !self:Event("CanInsertItem",true,item,i) then return false end

		--Can this inventory support the weight of all the items being inserted?
		--TODO Hard Weight Caps and Soft Weight Caps
		if self:GetWeightCapacity()!=0 && (self:GetWeightFree()-item:GetStackWeight())<0 then
			--Since we don't have enough room, will you settle for moving part of the stack instead?
			if bNoSplit then return false end
			
			--How many items of this weight can fit in the inventory, if any?
			local howMany=math.floor(self:GetWeightFree()/item:GetWeight());
			
			--If no items can fit, we'll just end it here.
			if howMany<1 then return false end
				
			--The stack being moved to our inventory is 'item', so we'll create a stack with everything that _isn't_ moving to that inventory in the same location.
			--TODO I don't like this approach; it should split off a stack and move the new one instead
			local newStack=item:Split(item:GetAmount()-howMany,nil,bPredict);
			
			--If the new stack couldn't be created, we fail because it's been established that we can't fit the whole stack
			if !newStack then return false end
		end
	else
		if slotnum==nil then return self:Error("Tried to add "..tostring(item).." clientside, but slotnum was nil!\n") end
		i=slotnum;
	end
	
	
	--Send to void. False is returned in case of errors or if events stop the removal of the item from it's current medium.
	if !item:ToVoid(false,nil,true,bPredict) then return false end
	
	if !bPredict then
		--Register the item in the inventory
		self.Items[i]=item;
		self.ItemsByID[itemid]=i;
		
		--OnInsertItem is called when an item enters the inventory
		self:Event("OnInsertItem",nil,item,i);
		
		--Refresh any UI displaying this inventory
		if CLIENT then self:Update(); end
	end
	--Return slot item placed in
	return i;
end

--[[
Moves an item in this inventory from one slot to another.
DO NOT CALL DIRECTLY - this is called automatically by other functions.

The Inventory's CanMoveItem event can stop the item from moving from one slot to another slot.
When an item is moved, the inventory's OnMoveItem event is triggered.

item is the item in this inventory to move. If the item is not in this inventory then an error message is generated.
oldslot is only required when moving items clientside. Clientside, both the item and the slot it's expected to be in are required to detect netsync errors.
newslot is the slot to move the item to. If this slot is occupied, false is returned and if occuring clientside an error message is generated.
bPredict is an optional true/false that defaults to false on the server and true on the client. If bPredict is:
	false, then we are actually moving item from oldslot to newslot.
	true, then we are simply predicting whether or not we can move the item.
]]--
function _INV:MoveItem(item,oldslot,newslot,bPredict)
	if !item || !item:IsValid() then return self:Error("Couldn't move item from one slot to another - item given was invalid!\n") end
	if !newslot					then return self:Error("Couldn't move "..tostring(item).." from one slot to another - new slot wasn't given!\n") end
	
	if bPredict==nil then bPredict=CLIENT end
	
	local itemid=item:GetID();
	
	--Make sure that the given item is occupying a slot in this inventory (and that clientside this matches the old slot given)
	local s=self:GetItemSlotByID(itemid);
	if SERVER || bPredict then
		if !s then return self:Error("Couldn't move "..tostring(item).." from one slot to another - Wasn't in this inventory!\n") end
	else
		if !oldslot		then return self:Error("Couldn't move "..tostring(item).." from one slot to another - old slot wasn't given!\n") end
		if s!=oldslot	then return self:Error("Couldn't move "..tostring(item).." from one slot to another - given item wasn't in given old slot! Netsync error?\n") end
	end
	
	--Can't move to anything but an empty slot
	if self:GetItemBySlot(newslot)!=nil then
		if CLIENT && !bPredict then return self:Error("Couldn't move "..tostring(item).." from one slot to another - new slot has an item in it! Netsync error?\n") end
		return false;
	end
	
	--The CanMoveItem event gets to decide whether or not an item is allowed to move
	if (SERVER || bPredict) && !self:Event("CanMoveItem",true,item,oldslot,newslot) then return false end
	
	if !bPredict then
		--Clear old slot
		self.Items[oldslot]=nil;
		
		--Register at new slot
		self.Items[newslot]=item;
		self.ItemsByID[itemid]=newslot;
		
		self:Event("OnMoveItem",nil,item,oldslot,newslot);
		
		--Refresh any UI displaying this inventory
		if CLIENT then self:Update(); end
	end
	
	return true;
end

--[[
Finds a free slot in this inventory, starting from the first slot.
]]--

function _INV:GetFreeSlot()
	--Finds the highest consecutive occupied index and returns the empty slot following it
	local n=table.getn(self.Items);
	local max=self:GetMaxSlots();
	
	--[[
	for i=1,max do
		if self.Items[i]==nil then return i end
	end
	return nil;

	local i=1;
	while self.Items[i]!=nil do
		i=i+1;
	end
	return i;
	]]--
	
	if max==0 || n!=max then
		--Returns the empty slot following it
		return n+1;
	end
	return nil;
end

--[[
Takes an item out of the inventory. DO NOT CALL DIRECTLY - this is called automatically by other functions.
This function triggers the OnRemoveItem event. The item can be prevented from being taken out serverside.

itemid is the ID of an item. We use the ID because it's possible the item no longer exists, and is being cleaned up.
If forced is true, the OnRemoveItem event cannot stop the removal (forced is usually set to true whenever the inventory's connected object is being removed, and items HAVE to be taken out)
bPredict is an optional true/false that defaults to false on the server and true on the client. If bPredict is:
	false, we are actually removing the item from this inventory.
	true, instead we are predicting whether or not we can remove the item from the inventory.

True is returned if the item was/can be removed successfully.
False is returned if the item cannot be removed (either due to an event or it can't be found in the inventory)
]]--
function _INV:RemoveItem(itemid,forced,bPredict)
	if !itemid then return self:Error("Cannot remove item... itemid wasn't given!\n") end
	if forced==nil then forced=false end
	if bPredict==nil then bPredict=CLIENT end
	
	--[[
	This part is kind of tricky. This function can be used to take out an item, or clear the record of an item in this inventory.
	If it's the former, our OnRemoveItem event is called.
	OnRemoveItem exists on both the client and server. It's called on both, but the event can only stop it on the server, given that it wasn't forced.
	]]--	
	local slot=self:GetItemSlotByID(itemid);
	if slot==nil then return self:Error("Tried to remove item "..itemid..", but it's not listed in this inventory.\n") end
	
	local item=IF.Items:Get(itemid);
	if !forced && (SERVER || bPredict) && item && item:IsValid() && !self:Event("CanRemoveItem",true,item,slot) then return false end
	
	if !bPredict then
		self.Items[slot]=nil;
		self.ItemsByID[itemid]=nil;
		
		self:Event("OnRemoveItem",nil,item,slot,forced)
		
		--Update the inventory to tell the UI to refresh
		if CLIENT then self:Update(); end
	end
	
	return true;
end

--Connected entities will call this function if removed
function _INV.ConnectedEntityRemoved(ent,self)
	self:SeverEntity(ent:GetTable().ConnectionSlot);
end


if SERVER then




--




else




--[[
When a full update is received from the server, this function is called.
]]--
function _INV:RecvFullUpdate(weightCap,sizeLimit,maxSlots)
	self:SetWeightCapacity(weightCap);
	self:SetSizeLimit(sizeLimit);
	self:SetMaxSlots(maxSlots);
end

--[[
This command is used to tie this inventory to an item.
If an inventory is connected with an item, it means that the inventory is a part of it. If the item is removed, then the connection is severed.
An inventory can have several connected objects.
When an inventory loses all of it's connections, it's removed.
If there are items in the inventory at the time it's removed, it's items are moved to the same location as the last object it was connected with.

item should be an item.
slot is a required slot passed from the server. The connected item is stored here. If no player is given, it will connect the item on all players clientside. If the item is already connected, it will just tell this player to connect the item clientside.
]]--
function _INV:ConnectItem(item,slot)
	local newCon={};
	newCon.Type=IFINV_CONTYPE_ITEM;
	newCon.Obj=item;
		
	self.ConnectedObjects[slot]=newCon;
	item:ConnectInventory(self,slot);
	
	return true;
end

--[[
This command is used to tie this inventory to an entity.
If an inventory is connected with an entity, it means that the inventory is a part of it. If the entity is removed, then the connection is severed.
An inventory can have several connected objects.
When an inventory loses all of it's connections, it's removed.
If there are items in the inventory at the time it's removed, it's items are moved to the same location as the last object it was connected with.

ent should be an entity.
pl is an optional player to connect the entity on. If no player is given, it will connect the entity on all players clientside. If the entity is already connected, it will just tell this player to connect the item clientside.
]]--
function _INV:ConnectEntity(ent,slot)
	local newCon={};
	newCon.Type=IFINV_CONTYPE_ENT;
	newCon.Obj=ent;
	
	self.ConnectedObjects[slot]=newCon;
	
	return true;
end

--[[
This command is used to untie this inventory from an item.

slot is a required slot number that should be given automatically by the server.
]]--
function _INV:SeverItem(slot)
	if !slot												then return self:Error("Couldn't sever item - slot to sever wasn't given.\n") end
	if !self.ConnectedObjects[slot]							then return self:Error("Couldn't sever item... there is no connected object on slot "..slot..".\n") end
	if self.ConnectedObjects[slot].Type!=IFINV_CONTYPE_ITEM then return self:Error("Couldn't sever item... the connected object on slot "..slot.." is not an item.\n") end
	
	--Break one-way connection between item and inventory
	local item=self.ConnectedObjects[slot].Obj;
	if item:IsValid() then item:SeverInventory(self); end
	
	--Break one-way connection between inventory and item
	self.ConnectedObjects[slot]=nil;
end

--[[
This command is used to untie this inventory from an entity.

slot is a required slot number that should be given automatically by the server.
]]--
function _INV:SeverEntity(slot)
	if !slot												then return self:Error("Couldn't sever entity - slot to sever wasn't given.\n") end
	if !self.ConnectedObjects[slot]							then return self:Error("Couldn't sever entity... there is no connected object on slot "..slot..".\n") end
	if self.ConnectedObjects[slot].Type!=IFINV_CONTYPE_ENT	then return self:Error("Couldn't sever entity... the connected object on slot "..slot.." is not an entity.\n") end
	
	local ent=self.ConnectedObjects[slot].Obj;
	if ent:IsValid() then ent:RemoveCallOnRemove("ifinv_"..self:GetID().."_connect") end
	
	self.ConnectedObjects[slot]=nil;
end




end