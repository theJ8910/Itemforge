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
local Templates={};											--Inventory templates. Templates are like item-types for inventories.
local Inventories={};										--Inventory collection - all inventories are stored here
local InventoryRefs={};										--Inventory references. One for every inventory. Allows us to pass this instead of the actual inventory. We can garbage collect removed inventories, giving some memory back to the game, while at the same time alerting scripters of careless mistakes (referencing an item after it's been removed)
local InventoryCount=0;										--Inventory count - there are this many inventories created so far. Used to assign IDs.

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


--TODO I want to make these more like items
--An inventory's metatable is set to this. This allows an inventory to use any inventory methods and default values defined here. It also allows it to use stuff from an inventory template.
local invmt={};
function invmt:__index(k)
	if k=="Template" then return _INV.Template end
	
	return self.Template[k] or _INV[k];
end




--[[
Inventory references indirectly reference an inventory.
By doing this, we can garbage collect any removed inventory properly (unless somebody hacks around it on purpose).
This function binds a newly created reference to a newly created inventory.
References have an internal inventory, "i", that can only be accessed from internal functions here.
References have internal functions "IsValid", and "Invalidate".
	Call inv:IsValid() on a reference to see if a reference is still good (inventory hasn't been deleted).
		This will return true if the inventory hasn't been removed, and false otherwise.
	Don't bother calling inv:Invalidate(). This is called by Itemforge after the inventory is removed.
		This will clear the internal inventory, "i". This makes any further reads/writes to the inventory (except for IsValid and Invalidate) fail.
]]--
local function BindReference(invref,inv,id)
	local i=inv;
	local id=id;
	
	local function invrefIsValid() return (i!=nil); end
	local function invrefInvalidate() i=nil; end
	local invrefmt={};
	
	--We want to forward reads to the inventory, so long as it's valid
	function invrefmt:__index(k)
		if k=="IsValid" then
			return invrefIsValid;
		elseif k=="Invalidate" then
			return invrefInvalidate;
		elseif i!=nil then
			return i[k];
		else
			ErrorNoHalt("Itemforge Inventories: Couldn't reference \""..tostring(k).."\" on removed inventory (used to be Inventory "..id..")\n");
		end
	end
	
	--We want to forward writes to the inventory, so long as it's valid
	function invrefmt:__newindex(k,v)
		if i!=nil then
			i[k]=v;
		else
			ErrorNoHalt("Itemforge Inventories: Couldn't set \""..tostring(k).."\" to \""..tostring(v).."\" on removed inventory (used to be Inventory "..id..")\n");
			return false;
		end
	end
	
	--[[
	When tostring() is performed on an inventory reference, returns a string containing some information about the inventory.
	Format: "Inventory ID [COUNT items]" 
	Ex:     "Inventory 12 [20 items]" (Inventory 12, storing 20 items)
	Ex:		"Inventory 9 [invalid]" (used to be Inventory 9, invalid/has been removed/no longer exists)
	]]--
	function invrefmt:__tostring()
		if i!=nil then
			return "Inventory "..self:GetID().." ["..self:GetCount().." items]";
		else
			return "Inventory "..id.." [invalid]";
		end
	end
	
	setmetatable(invref,invrefmt);
end

--Initilize Inventory module
function MODULE:Initialize()
end

--Clean up the inventory module. Currently I have this done prior to a refresh. It will remove any inventories.
function MODULE:Cleanup()
	--[[
	for k,v in pairs(Inventories) do
		v:Remove();
	end
	]]--
	
	Templates=nil;
	Inventories=nil;
	InventoryRefs=nil;
	InventoryCount=nil;
end

--[[
This function registers a template for inventories to use.
strName is a name to identify the template by, such as "BucketInventory"
template should be a table defining the template.
true is returned if the template is registered, and false otherwise.
]]--
function MODULE:RegisterTemplate(strName,template)
	if !strName then ErrorNoHalt("Itemforge Inventories: Couldn't register inventory template - name to register under wasn't given!\n"); return false end
	if !template then ErrorNoHalt("Itemforge Inventories: Couldn't register inventory template \""..strName.."\" - template wasn't given!\n"); return false end
	if Templates[strName] then ErrorNoHalt("Itemforge Inventories: Couldn't register inventory \""..strName.."\" - there's already a template registered with this name!\n"); return false end
	
	Templates[strName]=template;
	template.Name=strName;
	return true;
end

--[[
Returns a registered template.
strName should be the name of the template to get.
Returns nil if no template by this name exists.
]]--
function MODULE:GetTemplate(strName)
	if !strName then ErrorNoHalt("Itemforge Inventories: Couldn't grab inventory template - name of template wasn't given!\n"); return false end
	return Templates[strName];
end

--[[
Create a new inventory.
template is an optional argument which the name of a template registered with IF.Inv:RegisterTemplate() to set for the inventory.
	The template is similiar to an item-type for an inventory.
	An inventory can use everything contained in a template including everything inside of _INV.
	Anything in the template will override _INV (allowing you to set events for the inventory, for example) - see the default template _INV towards the bottom of this file.
owner is an optional argument only used serverside that can be used to instruct that this inventory and any updates regarding it are only sent to the given player
	This is useful if you want to create an inventory for a player.
	Keeping an inventory private means other players have no way of knowing what an inventory is carrying at any given time, clientside at least.
	All inventories exist serverside.
id is only necessary clientside. Serverside, an ID will be picked automatically.
fullUpd also only applies clientside - if this is true, it will indicate that the creation of the inventory is being performed as part of a full update.

If everything goes fine, a reference to the newly created inventory is returned. Otherwise, nil is returned.
]]--
function MODULE:Create(template,owner,id,fullUpd)
	--If we're given an owner we need to validate it
	if owner!=nil then
		if !owner:IsValid() then ErrorNoHalt("Itemforge Inventories: Couldn't create an inventory owned by the given player - the player given no longer exists.\n"); return nil
		elseif !owner:IsPlayer() then ErrorNoHalt("Itemforge Inventories: Couldn't create an inventory owned by the given player - the entity given isn't a player!\n"); return nil end
	end
	
	local templateToUse;
	if template then
		templateToUse=self:GetTemplate(template);
		if !templateToUse then ErrorNoHalt("Itemforge Inventories: Couldn't create inventory with given template. There is no registered template by the name \""..template.."\".\n"); return nil end
	else
		templateToUse=nil;
	end 
	
	
	--We need to give an ID to the newly created inventory - we'll either use a unique ID based off of the number of inventories created so far or the ID sent from the server
	local n=0;
	if SERVER then
		n=InventoryCount+1;
		if n>=self.MaxInventories then ErrorNoHalt("Itemforge Inventories: Couldn't create inventory - max inventories reached ("..self.MaxInventories..")!\n"); return nil end
		InventoryCount=n;
	else
		if id==nil then ErrorNoHalt("Itemforge Inventories: Could not create inventory clientside, the ID of the inventory to be created wasn't given!\n"); return nil end
		n=id;
	end
	
	--[[
	When a full update on an inventory is being performed, Create is called before updating it.
	That way if the inventory doesn't exist it's created in time for the update.
	We only need to keep track of the number of inventories updated when all inventories are being updated.
	]]--
	if CLIENT && fullUpd==true && self.FullUpInProgress==true then
		self.FullUpCount=self.FullUpCount+1;
		self.FullUpInventoriesUpdated[n]=true;
	end
	
	--Does the inventory exist already? No need to recreate it.
	if Inventories[n] then
		--We only need to bitch about this on the server. Full updates of an inventory clientside will tell the inventory to be created regardless of whether it exists or not. If it exists clientside we'll just ignore it.
		if SERVER then
			ErrorNoHalt("Itemforge Inventories: Could not create inventory with id "..n..". An inventory with this ID already exists!\n");
		end
		return nil;
	end
	
	--Creating the new inventory after validating everything else
	local newInv={};
	newInv.Template=templateToUse;
	newInv.ID=n;
	if SERVER then newInv.Owner=owner; end
	setmetatable(newInv,invmt);		--This new inventory inherits default inventory functions and values
	
	--Register the new inventory
	Inventories[n]=newInv;
	
	--Create an inventory reference
	local newref={};
	BindReference(newref,newInv,n);
	
	--Register the inventory reference too
	InventoryRefs[n]=newref;
	
	--Inventories will be initialized right after being created
	newref:Initialize();
	
	--Tell clients to create the inventory too. If an owner was given to send inventory updates to exclusively, the inventory will only be created clientside on that player.
	if SERVER then self:CreateClientside(newref,owner) end
	
	return newref;
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
	if !inv || !inv:IsValid() then ErrorNoHalt("Itemforge Inventories: Could not remove inventory - inventory doesn't exist!\n"); return false end
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
	
	Inventories[id]=nil;
	InventoryRefs[id]=nil;
end



--[[
--Get an existing inventory by ID. Will return nil if this inventory doesn't exist.
--Will produce errors in the console if an inventory is missing.
function MODULE:GetInventory(id)
	if id==nil then ErrorNoHalt("Itemforge Inventories: Tried to get inventory, but ID is nil!\n"); return nil end
	local inventory=Inventories[id];
	if inventory==nil then ErrorNoHalt("Itemforge Inventories: Inventory with ID "..id.." doesn't exist.\n"); return nil end
	return inventory;
end

--Get an existing inventory by ID. Will return nil if this inventory doesn't exist.
--Will not produce errors in the console if an inventory is missing.
function MODULE:GetInventoryNoComplaints(id)
	if id==nil then return nil end
	local inventory=Inventories[id];
	if inventory==nil then return nil end
	return inventory;
end
]]--



--[[
This returns a reference to an inventory with the given ID.
For all effective purposes this is the same thing as returning the actual inventory,
except it doesn't hinder garbage collection,
and helps by warning the scripter of careless mistakes (still referencing an inventory after it's been deleted).
]]--
function MODULE:Get(id)
	return InventoryRefs[id] or InventoryRefs[0];
end

--[[
This returns a list of all inventories
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
function MODULE:DumpInventories()
	dumpTable(Inventories);
end

--TEMPORARY
function MODULE:DumpInventoryRefs()
	dumpTable(InventoryRefs);
end

--TEMPORARY
function MODULE:DumpInventory(id)
	dumpTable(Inventories[id]);
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
	if !inv or !inv:IsValid() then ErrorNoHalt("Itemforge Inventories: Couldn't CreateClientside - Inventory given isn't valid!\n"); return false end
	
	--Validate player
	if pl!=nil then
		if !pl:IsValid() then ErrorNoHalt("Itemforge Inventories: Couldn't CreateClientside - The player to send inventory "..inv:GetID().." to isn't valid!\n"); return false;
		elseif !pl:IsPlayer() then ErrorNoHalt("Itemforge Inventories: Couldn't CreateClientside - The player to send inventory "..inv:GetID().." to isn't a player!\n"); return false;
		elseif !inv:CanSendInventoryData(pl) then ErrorNoHalt("Itemforge Inventories: Couldn't CreateClientside - Was asked to create inventory "..inv:GetID().." on a player other than the owner!\n"); return false; end
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
	umsg.String(inv:GetTemplateName());
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
	if invid==nil then ErrorNoHalt("Itemforge Inventories: Couldn't RemoveClientside... the inventory ID to remove wasn't given.\n"); return false end
	
	--Validate player
	if pl!=nil then
		if !pl:IsValid() then ErrorNoHalt("Itemforge Inventories: Couldn't RemoveClientside - The player to remove the inventory from isn't valid!\n"); return false;
		elseif !pl:IsPlayer() then ErrorNoHalt("Itemforge Inventories: Couldn't RemoveClientside - The player to remove the inventory from isn't a player!\n"); return false; end
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
	if !invid then ErrorNoHalt("Itemforge Inventories: Couldn't SendFullUpdate... the inventory ID wasn't given.\n"); return false end
	
	--Validate player
	if pl!=nil then
		if !pl:IsValid() then ErrorNoHalt("Itemforge Inventories: Couldn't SendFullUpdate - The player to send inventory "..inv:GetID().." to isn't valid!\n"); return false;
		elseif !pl:IsPlayer() then ErrorNoHalt("Itemforge Inventories: Couldn't SendFullUpdate - The player to send inventory "..inv:GetID().." to isn't a player!\n"); return false; end
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
		if !pl:IsValid() then ErrorNoHalt("Itemforge Inventories: Couldn't start full update - The player to send inventories to isn't valid!\n"); return false;
		elseif !pl:IsPlayer() then ErrorNoHalt("Itemforge Inventories: Couldn't start full update - The player to send inventories to isn't a player!\n"); return false; end
	
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
		if !pl:IsValid() then ErrorNoHalt("Itemforge Inventories: Couldn't EndFullUpdate - The player to send inventory "..inv:GetID().." to isn't valid!\n"); return false;
		elseif !pl:IsPlayer() then ErrorNoHalt("Itemforge Inventories: Couldn't EndFullUpdate - The player to send inventory "..inv:GetID().." to isn't a player!\n"); return false; end
	
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
		if k!=0 && v:GetOwner()==pl then
			v:SetOwner(nil);
		end
	end
end

--Handles incoming "ifinv" messages from client
function MODULE:HandleIFINVMessages(pl,command,args)
	if !pl || !pl:IsValid() || !pl:IsPlayer() then ErrorNoHalt("Itemforge Inventories: Couldn't handle incoming message from client - Player given doesn't exist or wasn't player!\n"); return false end
	if !args[1] then ErrorNoHalt("Itemforge Inventories: Couldn't handle incoming message from client - message type wasn't received.\n"); return false end
	if !args[2] then ErrorNoHalt("Itemforge Inventories: Couldn't handle incoming message from client - item ID wasn't received.\n"); return false end
	
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
		ErrorNoHalt("Itemforge Inventories: Unhandled IFINV message \""..msgType.."\"\n");
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
		Msg("Itemforge Inventories: Full inventory update only updated "..self.FullUpCount.." out of expected "..self.FullUpTarget.." inventories!\n");
	end
	
	--Remove non-updated inventories
	for k,v in pairs(InventoryRefs) do
		if k!=0 then
			if self.FullUpInventoriesUpdated[k]!=true then
				--DEBUG
				Msg("Itemforge Inventories: Removing inventory "..k.." - only exists clientside\n");
				
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
		local template=msg:ReadString();
		if template=="" then template=nil end
		local fullUpd=msg:ReadBool();
		
		--Create the inventory clientside too. Use the ID and player provided by the server.
		self:Create(template,nil,id,fullUpd);
	elseif msgType==IFINV_MSG_REMOVE then
		local inv=self:Get(id);
		if !inv:IsValid() then return false end
		
		--Remove the item clientside since it has been removed serverside. TODO, last connected object should be passed
		self:Remove(inv);
	elseif msgType==IFINV_MSG_STARTFULLUPALL then
		self:OnStartFullUpdateAll(id-1);	 --We subtract 1 from the count. This is what we wanted, as one of the invs is a null inventory reference and won't be updated.
	elseif msgType==IFINV_MSG_ENDFULLUPALL then
		self:OnEndFullUpdateAll();
	elseif msgType==IFINV_MSG_INVFULLUP then
		local inv=self:Get(id);
		if !inv:IsValid() then return false end
		
		local weightCap=msg:ReadLong()+2147483648;
		local sizeLimit=msg:ReadLong()+2147483648;
		local maxSlots=msg:ReadLong()+2147483648;
		
		inv:RecvFullUpdate(weightCap,sizeLimit,maxSlots);
	elseif msgType==IFINV_MSG_WEIGHTCAP then
		local inv=self:Get(id);
		if !inv:IsValid() then return false end
		
		local weightCap=msg:ReadLong()+2147483648;
		
		inv:SetWeightCapacity(weightCap);
	elseif msgType==IFINV_MSG_SIZELIMIT then
		local inv=self:Get(id);
		if !inv:IsValid() then return false end
		
		local sizeLimit=msg:ReadLong()+2147483648;
		
		inv:SetSizeLimit(sizeLimit);
	elseif msgType==IFINV_MSG_MAXSLOTS then
		local inv=self:Get(id);
		if !inv:IsValid() then return false end
		
		local maxSlots=msg:ReadLong()+2147483648;
		
		inv:SetMaxSlots(maxSlots);
	elseif msgType==IFINV_MSG_CONNECTITEM then
		local inv=self:Get(id);
		if !inv:IsValid() then return false end
		
		local itemid=msg:ReadShort()+32768;
		local item=IF.Items:Get(itemid);
		
		if !item || !item:IsValid() then ErrorNoHalt("Itemforge Inventories: Tried to connect a non-existent item with ID "..itemid.." to inventory "..id..".\n"); return false end
		
		local slot=msg:ReadShort()+32768;

		inv:ConnectItem(item,slot);
	elseif msgType==IFINV_MSG_CONNECTENTITY then
		local inv=self:Get(id);
		if !inv:IsValid() then return false end
		
		local ent=msg:ReadEntity();
		local slot=msg:ReadShort()+32768;
		
		inv:ConnectEntity(ent,slot);
	elseif msgType==IFINV_MSG_SEVERITEM then
		local inv=self:Get(id);
		if !inv:IsValid() then return false end
		
		local slot=msg:ReadShort()+32768;
		inv:SeverItem(slot);
	elseif msgType==IFINV_MSG_SEVERENTITY then
		local inv=self:Get(id);
		if !inv:IsValid() then return false end
		
		local slot=msg:ReadShort()+32768;
		inv:SeverEntity(slot);
	elseif msgType==IFINV_MSG_LOCK then
		local inv=self:Get(id);
		if !inv:IsValid() then return false end
		
		inv:Lock();
	elseif msgType==IFINV_MSG_UNLOCK then
		local inv=self:Get(id);
		if !inv:IsValid() then return false end
		
		inv:Unlock();
	else
		ErrorNoHalt("Itemforge Inventories: Unhandled IFINV message \""..msgType.."\"\n");
	end
end

--We use a proxy here so we can make HandleIFINVMessages a method (:) instead of a regular function (.)
usermessage.Hook("ifinv",function(msg) return IF.Inv:HandleIFINVMessages(msg) end);




end











--[[
Inventory Template
SHARED

The inventory template contains functions and default values available to all inventories.
]]--

--[[
Variables
This is a listing of vars that are stored on the server, client, or both.
Whatever these variables are set to are defaults, which can be overridden by a template or an inventory.
]]--

_INV.Template={};								--Template is a table that contains events and values dealing with the inventory. Take a look at _INV - it's the default template for an inventory. The inventory will have access to any functions or events in the template. Using a template can be good if your inventory is connected with a specific type of item and has specific rules that need to be followed (for example, a bucket might hold water, but a cloth bag can't)
_INV.Template.Name="";
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
		if !pl:IsValid() then ErrorNoHalt("Itemforge Inventories: Cannot set owner on "..tostring(self)..". Given player was invalid.\n"); return false
		elseif !pl:IsPlayer() then ErrorNoHalt("Itemforge Inventories: Cannot set owner on "..tostring(self)..". Given player wasn't a player!\n"); return false end
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
Set weight capacity for this inventory in kg. If called serverside, the clients are instructed to set the weight capacity as well.
Note: If the weight capacity changes to something smaller than the current total weight, (ex: there are 2000kg in the inventory, but the weight capacity is set to 1000kg)
items will not be removed to compensate for the weight capacity changing.
Set to 0 to allow limitless weight to be stored.
]]--
function _INV:SetWeightCapacity(cap,pl)
	if cap==nil then ErrorNoHalt("Itemforge Inventories: Couldn't set weight capacity on inventory "..self:GetID().."... amount to set wasn't given.\n"); return false end
	if cap<0 then ErrorNoHalt("Itemforge Inventories: Can't set weight capacity on inventory "..self:GetID().." to negative values! (Set to 0 if you want the inventory to store an infinite amount of weight)\n"); return false end
	
	if SERVER && pl!=nil then
		if !pl:IsValid() then ErrorNoHalt("Itemforge Inventories: Cannot set weight capacity. Given player was invalid.\n"); return false
		elseif !pl:IsPlayer() then ErrorNoHalt("Itemforge Inventories: Cannot set weight capacity. Given player wasn't a player!\n"); return false
		elseif SERVER && !self:CanSendInventoryData(pl) then ErrorNoHalt("Itemforge Inventories: Cannot set weight capacity on inventory "..self:GetID()..". Given player wasn't the owner of the inventory!\n"); return false end
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
	if sizelimit==nil then ErrorNoHalt("Itemforge Inventories: Couldn't set size limit on inventory "..self:GetID().."... sizelimit wasn't given.\n"); return false end
	if sizelimit<0 then ErrorNoHalt("Itemforge Inventories: Can't set size limit on inventory "..self:GetID().." to negative values! (Set to 0 to allow items of any size to be inserted)\n"); return false end
	
	if SERVER && pl!=nil then
		if !pl:IsValid() then ErrorNoHalt("Itemforge Inventories: Cannot set size limit on inventory "..self:GetID()..". Given player was invalid.\n"); return false
		elseif !pl:IsPlayer() then ErrorNoHalt("Itemforge Inventories: Cannot set size limit on inventory "..self:GetID()..". Given player wasn't a player!\n"); return false
		elseif !self:CanSendInventoryData(pl) then ErrorNoHalt("Itemforge Inventories: Cannot set size limit on inventory "..self:GetID()..". Given player wasn't the owner of the inventory!\n"); return false end
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
	if max==nil then ErrorNoHalt("Itemforge Inventories: Couldn't set max number of slots on inventory "..self:GetID().."... max wasn't given.\n"); return false end
	if max<0 then ErrorNoHalt("Itemforge Inventories: Can't set max number of slots on inventory "..self:GetID().." to negative values! (Set to 0 for infinite slots)\n"); return false end
	
	if SERVER && pl!=nil then
		if !pl:IsValid() then ErrorNoHalt("Itemforge Inventories: Cannot set max number of slots on inventory "..self:GetID()..". Given player was invalid.\n"); return false
		elseif !pl:IsPlayer() then ErrorNoHalt("Itemforge Inventories: Cannot set max number of slots on inventory "..self:GetID()..". Given player wasn't a player!\n"); return false
		elseif !self:CanSendInventoryData(pl) then ErrorNoHalt("Itemforge Inventories: Cannot set max number of slots on inventory "..self:GetID()..". Given player wasn't the owner of the inventory!\n"); return false end
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

--Returns the name this template is using. Will return "" if no template is set.
function _INV:GetTemplateName()
	if self.Template then
		return self.Template.Name;
	end
	return "";
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
	If our inventory is connected with, lets say, two bags that share the same inventory, then it returns both the positon of the first bag and the second (as a table).
	
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
		if !pl:IsValid() then ErrorNoHalt("Itemforge Inventories: Cannot lock "..tostring(self)..". Given player was invalid.\n"); return false
		elseif !pl:IsPlayer() then ErrorNoHalt("Itemforge Inventories: Cannot lock "..tostring(self)..". Given player wasn't a player!\n"); return false
		elseif !self:CanSendInventoryData(pl) then ErrorNoHalt("Itemforge Inventories: Cannot lock "..tostring(self)..". Given player wasn't the owner of the inventory!\n"); return false end
	end
	
	self.Locked=true;
	if SERVER then
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
		if !pl:IsValid() then ErrorNoHalt("Itemforge Inventories: Cannot unlock "..tostring(self)..". Given player was invalid.\n"); return false
		elseif !pl:IsPlayer() then ErrorNoHalt("Itemforge Inventories: Cannot unlock "..tostring(self)..". Given player wasn't a player!\n"); return false
		elseif !self:CanSendInventoryData(pl) then ErrorNoHalt("Itemforge Inventories: Cannot unlock "..tostring(self)..". Given player wasn't the owner of the inventory!\n"); return false end
	end
	
	self.Locked=false;
	if SERVER then
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
	if !sItemtype then ErrorNoHalt("Itemforge Inventories: Can't find a specific item-type in inventory "..self:GetID().." - the type of item to find wasn't given!\n"); return nil end
	sItemtype=string.lower(sItemtype);
	
	for k,v in pairs(self.Items) do
		if v:IsValid() then
			if v:GetType()==sItemtype then return v end
		else
			--INVALID - Item was removed but not taken out of inventory for some reason
			ErrorNoHalt("Itemforge Inventories: Found an item in inventory "..self:GetID().." (slot "..k..") that no longer exists but is still recorded as being in this inventory.\n");
		end
	end
	return nil;
end

--[[
Returns a table of items with the given type in this inventory.
Returns nil if there are errors.
]]--
function _INV:GetItemsByType(sItemtype)
	if !sItemtype then ErrorNoHalt("Itemforge Inventories: Can't find items of a specific item-type in inventory "..self:GetID().." - the type of item to find wasn't given!\n"); return nil end
	local sItemtype=string.lower(sItemtype);
	
	local items={};
	for k,v in pairs(self.Items) do
		if v:IsValid() then
			if v:GetType()==sItemtype then table.insert(items,v) end
		else
			--INVALID - Item was removed but not taken out of inventory for some reason
			self:RemoveItem(k,true,false);
			ErrorNoHalt("Itemforge Inventories: Found an item in inventory "..self:GetID().." (slot "..k..") that no longer exists but is still listed as being in this inventory\n");
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
	if !item || !item:IsValid() then ErrorNoHalt("Itemforge Inventories: Couldn't connect item to inventory "..self:GetID().."... item given was invalid.\n"); return false end
	
	--Validate player if one was given
	if pl!=nil then
		if !pl:IsValid() then ErrorNoHalt("Itemforge Inventories: Couldn't connect "..tostring(item).." to inventory "..self:GetID().." - The player to connect this to clientside wasn't a player!\n"); return false;
		elseif !pl:IsPlayer() then ErrorNoHalt("Itemforge Inventories: Couldn't connect "..tostring(item).." to inventory "..self:GetID().." - The player to connect this to clientside wasn't a player!\n"); return false; end
	end
	
	--We'll connect the item on either the given player or the inventory owner.
	local who=pl or self:GetOwner();
	
	if !self:CanSendInventoryData(who) then ErrorNoHalt("Itemforge Inventories: Couldn't connect "..tostring(item).." to inventory "..self:GetID().." clientside - player(s) given were not the owners!\n"); return false end
	
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
	if !ent || !ent:IsValid() then ErrorNoHalt("Itemforge Inventories: Couldn't connect entity to inventory "..self:GetID().."... entity given was invalid.\n"); return false end
	
	--Validate player
	if pl!=nil then
		if !pl:IsValid() then ErrorNoHalt("Itemforge Inventories: Couldn't connect entity "..ent:EntIndex().." to inventory "..self:GetID().." - The player to connect this to clientside wasn't a player!\n"); return false;
		elseif !pl:IsPlayer() then ErrorNoHalt("Itemforge Inventories: Couldn't connect entity "..ent:EntIndex().." to inventory "..self:GetID().." - The player to connect this to clientside wasn't a player!\n"); return false; end
	end
	
	--We'll connect the item on either the given player or the inventory owner.
	local who=pl or self:GetOwner();
	
	if !self:CanSendInventoryData(who) then ErrorNoHalt("Itemforge Inventories: Couldn't connect entity to inventory "..self:GetID().." clientside - player(s) given were not the owners!\n"); return false end
	
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
		ent:CallOnRemove("ifinv_"..self:GetID().."_connect",self.ConnectedEntityRemoved,self);
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
	if !slot then ErrorNoHalt("Itemforge Inventories: Couldn't sever item from inventory "..self:GetID().." - slot to sever wasn't given.\n"); return false end
	if !self.ConnectedObjects[slot] then ErrorNoHalt("Itemforge Inventories: Couldn't sever item from inventory "..self:GetID().."... there is no connected object on slot "..slot..".\n"); return false end
	if self.ConnectedObjects[slot].Type!=IFINV_CONTYPE_ITEM then ErrorNoHalt("Itemforge Inventories: Couldn't sever item from inventory "..self:GetID().."... the connected object on slot "..slot.." is not an item.\n"); return false end
	
	
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
	if !slot then ErrorNoHalt("Itemforge Inventories: Couldn't sever entity from inventory "..self:GetID().." - slot to sever wasn't given.\n"); return false end
	if !self.ConnectedObjects[slot] then ErrorNoHalt("Itemforge Inventories: Couldn't sever entity from inventory "..self:GetID().."... there is no connected object on slot "..slot..".\n"); return false end
	if self.ConnectedObjects[slot].Type!=IFINV_CONTYPE_ENT then ErrorNoHalt("Itemforge Inventories: Couldn't sever entity from inventory "..self:GetID().."... the connected object on slot "..slot.." is not an entity.\n"); return false end
	
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
	if !panel || !panel:IsValid() then ErrorNoHalt("Itemforge Inventories: Couldn't bind panel to inventory "..self:GetID().." - a valid panel was not given.\n"); return false end
	
	--Make sure we're not binding an already bound panel
	for k,v in pairs(self.BoundPanels) do
		if panel==v then return false; end
	end
	
	if !panel:InventoryBind(self) then end
	
	--Insert this panel into our collection of bound panels
	table.insert(self.BoundPanels,panel);
end

--Unbind a panel bound to this inventory.
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
Can a player interact with an item in this inventory?
When an item's CanPlayerInteract event is called, this function lets it's container have a say in whether or not we can interact with it.

player is the player who wants to interact with an item in this inventory.
item is the item being interacted with.

Return true to allow the player to interact with items in this inventory,
or false to stop players from interacting with items in this inventory.
]]--
function _INV:CanPlayerInteract(player,item)
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
		if !pl:IsValid() then ErrorNoHalt("Itemforge Inventories: Can't send full update of inventory "..self:GetID().." - player given wasn't valid.\n"); return false
		elseif !pl:IsPlayer() then ErrorNoHalt("Itemforge Inventories: Can't send full update of inventory "..self:GetID().." - player given wasn't a player!\n"); return false end
	end
	
	if !self:CanSendInventoryData(pl) then ErrorNoHalt("Itemforge Inventories: Can't send full update: Full update of inventory "..self:GetID().." was going to be sent to a player other than the owner!\n"); return false end
	
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
	
	--If we're locked tell that player
	if self.Locked then
		self:Lock(pl);
	else
		self:Unlock(pl);
	end
	
	local s,r=pcall(self.OnSendFullUpdate,self,pl);
	if !s then ErrorNoHalt(r.."\n") end
end

--[[
Calls an event on the inventory.
If there is an error calling the event, a non-halting error message is generated and a default value is returned.

sEventName is a string which should be the name of the event to call (EX: "CanRemoveItem", "OnInsertItem", etc)
vDefaultReturn is what will be returned in case of errors calling the hook.
... - You can pass arguments to the hook here

This function returns two values: vReturn,bSuccess
	vReturn will be what the event returned, or if there were errors, then it will be vDefaultReturn.
	bSuccess will be true if the event was called successfully or false if there were errors.
]]--
function _INV:Event(sEventName,vDefaultReturn,...)
	local f=self[sEventName];
	if !f then ErrorNoHalt("Itemforge Inventories: "..sEventName.." ("..tostring(self)..") failed: This event does not exist.\n"); return vDefaultReturn,false end
		
	local s,r=pcall(f,self,...);
	if !s then ErrorNoHalt("Itemforge Inventories: "..sEventName.." ("..tostring(self)..") failed: "..r.."\n"); return vDefaultReturn,false end
	
	return r,true;
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
	if !item || !item:IsValid() then ErrorNoHalt("Itemforge Inventories: Couldn't add item to inventory "..self:GetID().."... item given was invalid.\n"); return false end
	
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
		if slotnum==nil then ErrorNoHalt("Itemforge Inventories: Tried to add "..tostring(item).." clientside, but slotnum was nil!\n"); return false end
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
	if !item || !item:IsValid() then ErrorNoHalt("Itemforge Inventories: Couldn't move item in "..tostring(self).." from one slot to another - Item given was invalid!\n"); return false end
	if !newslot then ErrorNoHalt("Itemforge Inventories: Couldn't move "..tostring(item).." in "..tostring(self).." from one slot to another - new slot wasn't given!\n"); return false end
	
	if bPredict==nil then bPredict=CLIENT end
	
	local itemid=item:GetID();
	
	--Make sure that the given item is occupying a slot in this inventory (and that clientside this matches the old slot given)
	local s=self:GetItemSlotByID(itemid);
	if SERVER || bPredict then
		if !s then ErrorNoHalt("Itemforge Inventories: Couldn't move "..tostring(item).." from one slot to another - Wasn't in "..tostring(self).."!\n"); return false end
	else
		if !oldslot then ErrorNoHalt("Itemforge Inventories: Couldn't move "..tostring(item).." in "..tostring(self).." from one slot to another - old slot wasn't given!\n"); return false end
		if s!=oldslot then ErrorNoHalt("Itemforge Inventories: Couldn't move "..tostring(item).." in "..tostring(self).." from one slot to another - given item wasn't in given old slot! Netsync error?\n"); return false end
	end
	
	--Can't move to anything but an empty slot
	if self:GetItemBySlot(newslot)!=nil then
		if CLIENT && !bPredict then ErrorNoHalt("Itemforge Inventories: Couldn't move "..tostring(item).." in "..tostring(self).." from one slot to another - new slot has an item in it! Netsync error?\n") end
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
	if !itemid then ErrorNoHalt("Itemforge Inventories: Cannot remove item from "..tostring(self).."... itemid wasn't given!\n"); return false end
	if forced==nil then forced=false end
	if bPredict==nil then bPredict=CLIENT end
	
	--[[
	This part is kind of tricky. This function can be used to take out an item, or clear the record of an item in this inventory.
	If it's the former, our OnRemoveItem event is called.
	OnRemoveItem exists on both the client and server. It's called on both, but the event can only stop it on the server, given that it wasn't forced.
	]]--	
	local slot=self:GetItemSlotByID(itemid);
	if slot==nil then ErrorNoHalt("Itemforge Inventories: Tried to remove item "..itemid.." from "..tostring(self)..", but it's not listed there.\n"); return false end
	
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

--Connected entities will call this function if removed
function _INV.ConnectedEntityRemoved(ent,self)
	self:SeverEntity(ent:GetTable().ConnectionSlot);
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
	if !slot then ErrorNoHalt("Itemforge Inventories: Couldn't sever item from inventory "..self:GetID().." - slot to sever wasn't given.\n"); return false end
	if !self.ConnectedObjects[slot] then ErrorNoHalt("Itemforge Inventories: Couldn't sever item from inventory "..self:GetID().."... there is no connected object on slot "..slot..".\n"); return false end
	if self.ConnectedObjects[slot].Type!=IFINV_CONTYPE_ITEM then ErrorNoHalt("Itemforge Inventories: Couldn't sever item from inventory "..self:GetID().."... the connected object on slot "..slot.." is not an item.\n"); return false end
	
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
	if !slot then ErrorNoHalt("Itemforge Inventories: Couldn't sever entity from inventory "..self:GetID().." - slot to sever wasn't given.\n"); return false end
	if !self.ConnectedObjects[slot] then ErrorNoHalt("Itemforge Inventories: Couldn't sever entity from inventory "..self:GetID().."... there is no connected object on slot "..slot..".\n"); return false end
	if self.ConnectedObjects[slot].Type!=IFINV_CONTYPE_ENT then ErrorNoHalt("Itemforge Inventories: Couldn't sever entity from inventory "..self:GetID().."... the connected object on slot "..slot.." is not an entity.\n"); return false end
	
	local ent=self.ConnectedObjects[slot].Obj;
	if ent:IsValid() then ent:RemoveCallOnRemove("ifinv_"..self:GetID().."_connect") end
	
	self.ConnectedObjects[slot]=nil;
end




end