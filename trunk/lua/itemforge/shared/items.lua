--[[
Itemforge Items Module
SHARED

This module implements items. The purpose of this module is to load item types, keep track of created items and item types,
handle inheritence between item types, handle networking of items between client and server, and much, much more.

theJ89's BUG list
BUG  Shotgun reload loop is failing when trying to reload from a stack of 1 items
BUG  net_fakelag 500 produces noticable problems with weapons. *sigh*
BUG  Weapons should have networked, predicted ammo counters instead of using :GetAmount() from the current ammo. This should fix the "dry fire on last shot clientside" bug with ranged weapons.
BUG  sometimes the view model does not change; this has been noticed when picking up one item, dropping it, and picking up a separate item
BUG  apparently related to the view model having it's model changed through Lua, viewmodel animations do not play until Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK) is called.
BUG  SWEP pickup issues (Give player weapon but he doesn't pick it up); waiting on garry for this
BUG	 Odd bug noticed; may be related to entity owner, entity collision group, or damage. Sometimes while in the world an item loses its collision, player can walk through it, can't use it, etc.
BUG  fix bug with SetNetOwner; is complaining about non-existent inventories table 
BUG  when updates are being sent to connecting players, the server often complains about not being able to index something on removed items... what is this about?
BUG  the new reusable IDs may interfere with full-update checks - If an old item 5 (lets pretend it's a crowbar) exists clientside and a new item 5 (lets say it's a base_ranged) is created, then it needs to override. This may be troublesome.
BUG  Possibly PVS related or something - players will often see other players holding nothing. Items like the lantern stop working during lag spikes. Lantern light sticks until the local player observes the player holding the lantern.
BUG  Sometimes players see bullets fired from other players... wierd!
BUG  Debug module is reporting message -114 is undefined for some clients
BUG  Wiremod is erroring some clients with message: Lua Error: entities\itemforge_item\shared.lua:80: attempt to compare number with string
BUG  Okay, WTF? The pumpkin was both inside and outside of an inventory at the same time...
BUG  Singleplayer - Weapons do not deploy clientside or something - the item slot is not showing up.
BUG  Hitting ammo results in serverside bugs

theJ89's Giant TODO list
This is why the system hasn't been released yet:

TODO code maintainence... make sure that multi-line comments are used for function descriptions, check arguments, do cleanup code (for items listed in an inventory for example), for collections check to see if something being inserted still exists, check events to make sure they are all being pcalled, consider putting base item's events into their own lua file.
TODO remember to divide default files into sections: Methods, events, internal methods (things scripters won't be calling)
TODO Have it so item types can be reloaded without needing a full map change/restart
TODO redux of itemforge_item and itemforge_item_held, need to reduce complexity and homogenize
TODO consider renaming default item "item" to "base" or "base_item"
TODO eliminate redundancy; ex: IF.Items:CreateItem becomes IF.Items:Create
TODO pay attention to function return values; false should be returned for failures, true most of the other times
TODO wire outputs are forgotten when the item is taken out of the world and put back in; make an item wrapper that remembers them, restore when entity enters world
TODO looping sounds should resume when possible
TODO change inventory functions from MoveSlot to SwapSlot (functionality and name)
TODO SetWorldModel and SetViewModel need to work clientside too
TODO MaxHealth=0 means item is invincible
TODO migrate .ReloadsSingly related things from the shotgun to the base_ranged
TODO base_ranged needs to have "Load" renamed to "FillClip"; StartReload needs to be called OnReload - if the weapon .ReloadsSingly this starts the reload loop, otherwise this immediately fills the clip; items that use :Load() must be configured this way

Item Ideas
TODO Wearable gear as suggested by Mr. Bix

Events related
TODO consider rewriting events so "true" overrides and false/nil doesn't (garry does this already so lazy/ignorant coders don't accidentilly break something and spend hours trying to find what went wrong)
TODO possibly make hooks for both items and item types (ex: ITEMTYPE:Hook() creates a hook for all items of that type)
TODO Gravity Gun/Physgun hooks like in RPMod v2
TODO OnChangeAmount
TODO OnNewWorldModel
TODO OnNewViewModel
TODO OnPopulateMenu is stupid, rename it to OnMakeMenu or OnRightClick
TODO OnLeftClick/OnRightClick event for world entity & item icon??
TODO If OnInit returns false, remove the item

UI related
TODO when item model changes it doesn't update on the "hold" icon.
TODO The UI needs to be able to mouse-capture entities as intended
TODO If drags are enabled on any slots in ItemforgeInventorySlots they stay on even if an item is no longer occupying the slot.
TODO Need to come up with good looking Item Card
TODO redux of button icons for inventory?
TODO button bars? Have it so individual items can decide what their button bar creates, have so combinations can place

Entity related
TODO Spawning and Dragdropping to world often stick the items in the world... ideally we don't want this to happen
TODO Need to have SetSkin function that takes appropriate action (NOTE: may have to engineer ItemSlot displaying item to check for changes in skin)

Networking related
TODO okay let me set this straight once and for all: A sync is when a variable changes on the server and is synced with the client. An update is when an item syncs everything related to that item with a client. A full update is an update of all items sent to a client. I need to rename these things as such.
TODO check that when a full update is performed everything is intact...
TODO Default network commands, consider putting in IFI instead?
TODO Merge and split's networking can be macro'ed to save bandwidth
TODO Josh suggested doing something like Item-Types but with groups of items - creating macros and passing IDs: IFI_MSG_CREATEMACRO "macro_healthkit" 2 3 6 8 10 creates 5 items with IDs 2, 3, 6, 8, and 10
TODO Josh also suggested prioritizing full updates of items, sending items in the order most important. Items held would be first, in world second, in inventories third, and in void fourth (or maybe not at all?).
TODO rename "Owner" to "NetOwner" or something to that effect, I can see this being accidentally overridden; "Owner" isn't a good name for the concept anyway
TODO Ownership has been neglected; needs to be looked at in a serious manner
TODO Additionally I could rewrite the ownership to allow items clientside to be public, private, group-owned or hidden (where group-owned is like private with multiple players, and hidden is on no clients [server only])

Item creation/removal related
TODO Duplicator support
TODO split and join behavior - for example, a stack of 2 items with an inventory splits; what then? Or, a heavily damaged item stacks with an intact item - average? lowest on top? sum? what?
TODO Need to have a tab on the spawn menu that allows you to spawn items in world(like entities)
TODO Save and reload capabilities for both databases, files, and singleplayer saves (perhaps make one interface for several methods)
TODO Need to have an entity that spawns a given item-type in the world (so items can be pre-placed on maps). Perhaps even an inventory-item entity which takes an item-type and an item (to allow items to be created in containers)

TODO - I have stuff marked with DEBUG and TEMPORARY, remove that before release
]]--

MODULE.Name="Items";										--Our module will be stored at IF.Items
MODULE.Disabled=false;										--Our module will be loaded
MODULE.ItemsDirectory="itemforge/items/";					--What folder are the different item types stored in relative to the garrysmod/lua/ directory
MODULE.ExtensionsDirectory="extend"							--What folder are extensions for item types stored in relative to the item-type's folder (ex: if this is "extend" it means extensions for "item_crowbar" are stored in "garrysmod/lua/itemforge/items/item_crowbar/extend")?
MODULE.MaxItems=65535;										--WARNING: Item IDs beyond this value CANNOT be sent through networking! DO NOT CHANGE. How many unique items can exist at a single time (a stack of items count as one unique item)?
MODULE.MaxHeldItems=32;										--How many items can be held by a player at a single time (in the player's weapon menu)? This should NOT exceed 32. If your gamemode wants to set this, use this in your init: IF.Items:SetMaxHeld(amt)

if CLIENT then


MODULE.FullUpInProgress=false;								--If this is true a full update is being recieved from the server
MODULE.FullUpTarget=0;										--Whenever a full update starts, this is how many items need to be sent from the server.
MODULE.FullUpCount=0;										--Every time an item is created while a full update is being recieved, this number is increased by 1.
MODULE.FullUpItemsUpdated={};								--Every time an item is created while a full update is being recieved, FullUpItemsUpdated[Item ID] is set to true.
															--Whenever the full update finishes, we'll check to make sure all clientside items have been updated.
															--Any non-updated items are assumed to be removed on the server (since no update was recieved), and will be removed clientside.
end

--These are local on purpose. I want to prevent people from messing with ItemTypes so shit doesn't get screwy in case of some bad code. I'd also like people to use the Get function, and not grab the items directly from the table.
local BaseType="item";										--This is the undisputed absolute base item-type. All items inherit from this item.
local ItemTypes={};											--Item types. After being loaded from the script they are placed here
local Items={};												--Items collection - all items are stored here
local ItemRefs={};											--Item references - there's an item reference for every item. We pass this instead of the actual item. By storing the references, the actual item the reference refers to can be properly garbage collected when it's removed (freeing up memory). It also informs the scripter of any careless mistakes (referencing an item after it has been deleted mostly).
local ItemsByType={};										--Items by type are stored here (ex ItemsByType["item_crowbar"] contains all item_crowbar items currently spawned)
local NextItem=1;											--This is a pointer of types, that records where the next item will be made. IDs are assigned based on this number. This only serves as a starting point to search for a free ID. If this slot is taken then it will search through the entire items array once to look for a free slot.
local ProtectedKeys={};										--This is a table of protected keys in the base item-type. If an item attempts to override a protected key, the console will report a warning and get rid of the override by setting it to nil. Likewise attempting to override a protected key on an item (myItem.Use="hello" for example) will be stopped as well.
local AllowProtect=false;									--If this is true, we can protect keys (in other words, we're loading the base item-type while this is true)

--Itemforge Item (IFI) Message (-128 to 127. Uses char in usermessage).
IFI_MSG_CREATE			=	-128;	--(Server > Client) Sync Create item clientside
IFI_MSG_REMOVE			=	-127;	--(Server > Client) Sync Remove item clientside
IFI_MSG_SETANGLE		=	-126;	--(Server > Client) Sync a networked angle
IFI_MSG_SETBOOL			=	-125;	--(Server > Client) Sync a networked boolean
IFI_MSG_SETCHAR			=	-124;	--(Server > Client) Sync a networked char (an int from -128 to 127)
IFI_MSG_SETCOLOR		=	-123;	--(Server > Client) Sync a networked color (four unsigned chars - or four chars ranging from 0 to 255)
IFI_MSG_SETENTITY		=	-122;	--(Server > Client) Sync a networked entity
IFI_MSG_SETFLOAT		=	-121;	--(Server > Client) Sync a networked float
IFI_MSG_SETLONG			=	-120;	--(Server > Client) Sync a networked long (an int from -2,147,483,648 to 2,147,483,647)
IFI_MSG_SETSHORT		=	-119;	--(Server > Client) Sync a networked short (an int from -32,768 to 32,767)
IFI_MSG_SETSTRING		=	-118;	--(Server > Client) Sync a networked string
IFI_MSG_SETVECTOR		=	-117;	--(Server > Client) Sync a networked vector
IFI_MSG_SETITEM			=	-116;	--(Server > Client) Sync a networked item
IFI_MSG_SETINV			=	-115;	--(Server > Client) Sync a networked inventory
IFI_MSG_SETUCHAR		=	-114;	--(Server > Client) Sync a networked unsigned char (an int from 0 to 255)
IFI_MSG_SETULONG		=	-113;	--(Server > Client) Sync a networked unsigned long (an int from 0 to 4,294,967,295)
IFI_MSG_SETUSHORT		=	-112;	--(Server > Client) Sync a networked unsigned short (an int from 0 to 65,535)
IFI_MSG_SETNIL			=	-111;	--(Server > Client) Sync a networked var - changes whatever was there before to nil
IFI_MSG_REQFULLUP		=	-110;	--(Client > Server) Client requests full update of an item
IFI_MSG_REQFULLUPALL	=	-109;	--(Client > Server) Client requests full update of all items
IFI_MSG_STARTFULLUPALL	=	-108;	--(Server > Client) This message tells the client that a full update of all items is going to being sent and how many to expect.
IFI_MSG_ENDFULLUPALL	=	-107;	--(Server > Client) This message tells the client the full update of all items has finished.
IFI_MSG_SV2CLCOMMAND	=	-106;	--(Server > Client) Send a NWCommand for an item from the server to the client(s)
IFI_MSG_CL2SVCOMMAND	=	-105;	--(Client > Server) Send a NWCommand for an item from the client to the server
IFI_MSG_CREATETYPE		=	-104;	--(Server > Client) Macro; Create several items of this item type (used with full updates, saves bandwidth)
IFI_MSG_CREATEININV		=	-103;	--(Server > Client) Macro; Create item in inventory (saves bandwidth)
IFI_MSG_MERGE			=	-102;	--(Server > Client) Macro; Merge two items (change amount of an item and remove another, saves bandwidth)
IFI_MSG_PARTIALMERGE	=	-101;	--(Server > Client) Macro; Merge two items partially (change amount of two items, saves bandwidth)
IFI_MSG_SPLIT			=	-100;	--(Server > Client) Macro; Split an item (saves bandwidth)



--[[
This is handled automatically, there's no need for a scripter to do anything here.

Setting an itemtype's metatable to this will cause it to look in it's baseclass (inheritence).
This means the itemtype can use everything from the itemtype it's based off of.
If both the itemtype and the base itemtype don't have it, nil is returned.
]]--
local itmt={};
--The inheritence is carried out here
function itmt:__index(k)
	return self.BaseClass[k];
end

--[[
After an item type is loaded, it shouldn't be modified. This can be bypassed, but it's here as a safeguard.
If an Item-Type is accidentally modified a warning message will be generated and no changes will occur.
]]--
function itmt:__newindex(k,v)
	ErrorNoHalt("Itemforge Items: WARNING! Override on Item-Type \""..self.Type.."\" blocked: Tried to set \""..k.."\" to \""..v.."\".\n");
end





--[[
This is handled automatically, there's no need for a scripter to do anything here.

Setting an item's metatable to this allows an item to use everything it's item type can use.
]]--
local imt={};
function imt:__index(k)
	return self.Class[k];
end

--[[
Item references indirectly reference an item.
By doing this, we can garbage collect any removed item properly (unless somebody hacks around it on purpose).
This function binds a newly created reference to a newly created item.
References have an internal item, "i", that can only be accessed from internal functions here.
References have internal functions "IsValid", and "Invalidate".
	Call item:IsValid() on a reference to see if a reference is still good (item hasn't been deleted).
		This will return true if the item hasn't been removed, and false otherwise.
	Don't bother calling item:Invalidate(). This is called by Itemforge after the item is removed.
		This will clear the internal item, "i". This makes any further reads/writes to the item (except for IsValid and Invalidate) fail.
]]--
local function BindReference(iref,item,id)
	local i=item;
	local id=id;
	
	local function irefIsValid() return (i!=nil); end
	local function irefInvalidate() i=nil; end
	local function irefGetTable()
		if !i then
			ErrorNoHalt("Itemforge Items: Couldn't grab item table from removed item (used to be Item "..id..")\n");
			return false;
		end
		local t={};
		for k,v in pairs(i) do t[k]=v; end
		return t;
	end
	local irefmt={};
	
	--We want to forward reads to the item, so long as it's valid
	function irefmt:__index(k)
		if k=="IsValid" then
			return irefIsValid;
		elseif k=="GetTable" then
			return irefGetTable;
		elseif k=="Invalidate" then
			return irefInvalidate;
		elseif i!=nil then
			return i[k];
		else
			ErrorNoHalt("Itemforge Items: Couldn't reference \""..tostring(k).."\" on removed item (used to be Item "..id..")\n");
		end
	end
	
	--We want to forward writes to the item, so long as it's valid
	function irefmt:__newindex(k,v)
		if i!=nil then
			if IF.Items:IsProtectedKey(k) then
				ErrorNoHalt("Itemforge Items: WARNING! Item "..id.." tried to override \""..tostring(k).."\", a protected function or value in the base item-type.\n");
				return false;
			end
			i[k]=v;
		else
			ErrorNoHalt("Itemforge Items: Couldn't set \""..tostring(k).."\" to \""..tostring(v).."\" on removed item (used to be Item "..id..")\n");
			return false;
		end
	end
	
	--[[
	When tostring() is performed on an item reference, returns a string containing some information about the item.
	Format: "Item ID [ITEM_TYPE]xAMT" 
	Ex:     "Item 5 [item_crowbar]" (Item 5, a single crowbar)
	Ex:		"Item 3 [item_rock]x53" (Item 3, a stack of 53 item_rocks)
	Ex:		"Item 7 [invalid]" (used to be Item 7, invalid/has been removed/no longer exists)
	]]--
	function irefmt:__tostring()
		if i!=nil then
			if self:GetMaxAmount()!=1 then return "Item "..self:GetID().." ["..self:GetType().."]x"..self:GetAmount();
			else return "Item "..self:GetID().." ["..self:GetType().."]"; end
		else
			return "Item "..id.." [invalid]";
		end
	end
	
	setmetatable(iref,irefmt);
end


--[[
DoesLuaFileExist returns true if the given path in the lua directory does exist, false otherwise
LuaPath should be something like "itemforge/items/item/shared.lua"
]]--
local function DoesLuaFileExist(LuaPath)
	if SERVER then
		return file.Exists("../lua/"..LuaPath);
	else
		return file.Exists("../lua_temp/"..LuaPath) or file.Exists("../lua/"..LuaPath);
	end
end

--[[
IsLuaFolder will return false if you give it a file (or if the folder given doesn't exist), and true if you give it a folder.
LuaPath should be something like "itemforge/items/item"
]]--
local function IsLuaFolder(LuaPath)
	if SERVER then
		return file.IsDir("../lua/"..LuaPath);
	else
		return file.IsDir("../lua_temp/"..LuaPath) or file.IsDir("../lua/"..LuaPath);
	end
end








--Initilize Items module. We need to load the item types, then set their bases.
function MODULE:Initialize()
	self:LoadItemTypes();
	self:FixItemTypeMissingData();
	self:SetItemTypeBases();
	self:SetItemTypeNWVarAndCommandIDs();
	self:StartTick();
end

--Clean up the items module. Removes all items. Currently I have this done prior to a refresh. It will remove any items and clean up any local stuff stored here.
--TODO make this useful; actually use it somewhere
function MODULE:Cleanup()
	for k,v in pairs(ItemRefs) do
		v:Remove();
	end
	
	ItemTypes=nil;
	Items=nil;
	ItemRefs=nil;
	ItemsByType=nil;
	ProtectedKeys=nil;
end

--Load itemtypes. This loads the items' scripts and can be used to refresh a changed item.
function MODULE:LoadItemTypes()
	if ItemTypes then ItemTypes={}; end				--Clear this table in case it has been loaded before (in the case we're refreshing it).
	
	--List of all items in the items directory
	local itemFolders=file.FindInLua(self.ItemsDirectory.."*");		--itemforge/items/*
	
	--Search for directories in our item folder
	for k,v in pairs(itemFolders) do
		
		local path=self.ItemsDirectory..v;							--itemforge/items/item
		if v!=".." && v!="." && IsLuaFolder(path) then
			if string.lower(v)==BaseType then AllowProtect=true end
			
			--Create a temporary ITEM table at global
			ITEM={};
			
			
			
			
			--[[
			Lets load an item type! (loads init if on the server, or cl_init if on the client - if either init or cl_init is missing, shared will be loaded if shared exists. If shared doesn't exist, nothing will be loaded.)
			AddCSLuaFile must be done manually. I try to make item scripts resemble entity/swep/effect scripts as much as possible.
			]]--
			if SERVER then
				
				if DoesLuaFileExist(path.."/init.lua")	then
					local s,r=pcall(include,path.."/init.lua");
					if !s then ErrorNoHalt(r.."\n") end
				elseif DoesLuaFileExist(path.."/shared.lua") then
					local s,r=pcall(include,path.."/shared.lua");
					if !s then ErrorNoHalt(r.."\n") end
				end
				
			else
				
				if DoesLuaFileExist(path.."/cl_init.lua") then
					local s,r=pcall(include,path.."/cl_init.lua");
					if !s then ErrorNoHalt(r.."\n") end
				elseif DoesLuaFileExist(path.."/shared.lua") then
					local s,r=pcall(include,path.."/shared.lua");
					if !s then ErrorNoHalt(r.."\n") end
				end
				
			end
			
			
			--Load extensions to this item if available (in the case that a scripter wants to add onto an existing item-type for his own purposes - such as adding "temperature" to the base item-type to give all items a temperature rating).
			local extfolder=path.."/"..self.ExtensionsDirectory;		--itemforge/items/item/extend
			if IsLuaFolder(extfolder) then
				--List of all extensions in this item's extension folder
				local extensionFolders=file.FindInLua(extfolder.."/*");	--itemforge/items/item/extend/*
				
				--We sort these because they need to load in the same order serverside and clientside
				table.sort(extensionFolders);
				
				for i=1,table.getn(extensionFolders) do
					local v=extensionFolders[i];
					local extpath=extfolder..v;							--itemforge/items/item/extend/temperature
					if v!=".." && v!="." && IsLuaFolder(extpath) then
						--Load init serverside, cl_init clientside. In the abscence of either, load shared in it's place if it exists.
						if SERVER then
							
							if DoesLuaFileExist(extpath.."/init.lua")	then
								local s,r=pcall(include,extpath.."/init.lua");
								if !s then ErrorNoHalt(r.."\n") end
							elseif DoesLuaFileExist(extpath.."/shared.lua") then
								local s,r=pcall(include,extpath.."/shared.lua");
								if !s then ErrorNoHalt(r.."\n") end
							end
							
						else
							
							if DoesLuaFileExist(extpath.."/cl_init.lua") then
								local s,r=pcall(include,extpath.."/cl_init.lua");
								if !s then ErrorNoHalt(r.."\n") end
							elseif DoesLuaFileExist(extpath.."/shared.lua") then
								local s,r=pcall(include,extpath.."/shared.lua");
								if !s then ErrorNoHalt(r.."\n") end
							end
							
						end
					end
				end
			end
			
			
			
			
			ITEM.Type=string.lower(v);				--Set type to the name of the folder
			if ITEM.Base!=nil then	ITEM.Base=string.lower(ITEM.Base) end
			
			ItemTypes[ITEM.Type]=ITEM;				--Store the item type just loaded
			ItemsByType[ITEM.Type]={};				--Create an Items by Type table to store any items spawned of this type
			
			if SERVER then
				umsg.PoolString(ITEM.Type);			--Pool this string (increases network efficiency by substituting a smaller placeholder for this string when networked)
			end 
			
			ITEM=nil;								--Get rid of the temporary ITEM table
			AllowProtect=false;
		end
	end
	
end

--[[
We add tables that may be missing, such as NWVarsByName
Additionally this function checks to make sure item types are not overriding any protected values
]]--
function MODULE:FixItemTypeMissingData()
	for k,v in pairs(ItemTypes) do
		v.NWVarsByName		=	v.NWVarsByName		or {};
		v.NWVarsByID		=	v.NWVarsByID		or {};
		v.NWCommandsByName	=	v.NWCommandsByName	or {};
		v.NWCommandsByID	=	v.NWCommandsByID	or {};
		
		--[[
		if SERVER then	--Server Only
		else			--Client only
		end
		]]--
		
		--Make sure the item-type hasn't overridden any protected functions or values in the base-item type; if it has, set them to nil (so it will use the base item-type's stuff)
		if k!=BaseType then
			for a,b in pairs(v) do
				if self:IsProtectedKey(a) then
					ErrorNoHalt("Itemforge Items: WARNING! Itemtype \""..k.."\" tried to override \""..a.."\", a protected function or value in the base item-type.\n");
					v[a]=nil;
				end
			end
		end
	end
end

--We set the base classes/base item types for items here. This is where inheritence for item types is set.
function MODULE:SetItemTypeBases()
	for k,v in pairs(ItemTypes) do
		if v.Type!=BaseType then			--The absolute base item-type can't have a base class, all items are based off of it. Inheriting from itself would cause an infinite loop.
			
			--Set base class to the base item type. Can't inherit from self.
			if v.Base then
				if v.Base!=v.Type then
					--Set itemtype's base-class to another itemtype
					v.BaseClass=ItemTypes[v.Base];
					
					if v.BaseClass==nil then	--Couldn't find the base-class (note that all classes are loaded before bases are set - so the only reason this would happen is if the base isn't loaded or couldn't be loaded)
						ErrorNoHalt("Itemforge Items: Item-Type \""..k.."\" could not inherit from Item-Type \""..v.Base.."\". \""..v.Base.."\"  could not be found.\n");
					end
				else
					ErrorNoHalt("Itemforge Items: Item-Type \""..k.."\" couldn't inherit from Item-Type \""..v.Base.."\". The item was trying to inherit from itself, which would cause an infinite loop.\n");
				end
			end
			
			--If BaseClass still hasn't been set, then we'll set the base to the base for all item-types (except for itself of course)
			if v.BaseClass==nil then
				v.Base=BaseType;
				v.BaseClass=ItemTypes[BaseType];
			end
			
			--We'll also do something like C++ does with "myObject::InheritedClass" here.
			--[[
			Lets say you have items that inherit like this (top inherits from bottom):
			item_crowbar
			base_melee
			base_weapon
			item
			
			You spawn an item_crowbar called "myItem".
			You can do myItem.BaseClass or myItem.base_melee to access base_melee's stuff.
			Likewise, if you want myItem to access base_weapon's stuff, you can do myItem.base_weapon.
			]]--
			v[v.Base]=v.BaseClass;
			
			--Set the meta table finally. Make this item type inherit from another item type.
			setmetatable(ItemTypes[k],itmt);
		end
	end
end

--[[
Set network command and network var ID numbers...
We take hierarchy into consideration with this function.
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
function MODULE:SetItemTypeNWVarAndCommandIDs()
	for k,v in pairs(ItemTypes) do
		local NWVarNames={};
		local NWCommandNames={};
		
		local NWVarIDs={};
		local NWCommandIDs={};
		
		local b=v;

		while b!=nil do
			for i=1,table.getn(b.NWVarsByID) do
				--If our itemtype doesn't have a var by this name yet then make a copy of it
				if NWVarNames[b.NWVarsByID[i].Name]==nil then
					local NWVarCopy={};
					NWVarCopy.Name=b.NWVarsByID[i].Name;
					NWVarCopy.Default=b.NWVarsByID[i].Default;
					NWVarCopy.Predicted=b.NWVarsByID[i].Predicted;
					NWVarCopy.HoldFromUpdate=b.NWVarsByID[i].HoldFromUpdate;
					NWVarCopy.Save=b.NWVarsByID[i].Save;
					NWVarCopy.Type=b.NWVarsByID[i].Type;
					NWVarCopy.ID=table.insert(NWVarIDs,NWVarCopy);
					NWVarNames[NWVarCopy.Name]=NWVarCopy;
				end
			end
			
			for i=1,table.getn(b.NWCommandsByID) do
				--If our itemtype doesn't have a command by this name yet then make a copy of it
				if NWCommandNames[b.NWCommandsByID[i].Name]==nil then
					local NWCommandCopy={};
					NWCommandCopy.Name=b.NWCommandsByID[i].Name;
					NWCommandCopy.Hook=b.NWCommandsByID[i].Hook;
					NWCommandCopy.Datatypes=b.NWCommandsByID[i].Datatypes;
					NWCommandCopy.ID=table.insert(NWCommandIDs,NWCommandCopy);
					NWCommandNames[NWCommandCopy.Name]=NWCommandCopy;
				end
			end
			
			b=b.BaseClass;
		end
		
		v.NWVarsByName=NWVarNames;
		v.NWCommandsByName=NWCommandNames;
		v.NWVarsByID=NWVarIDs;
		v.NWCommandsByID=NWCommandIDs;
	end
end

--[[
Sets the max number of holdable items (how many items can be held in the player's weapon menu at any given time).
amt is how many weapons you want the players to hold at any given time. This will be clamped between 0 and 32.
	If this is 0, no items can be held; any time an item tries to be held, it will return false.
	The absolute limit to this is 32.
]]--
function MODULE:SetMaxHeld(amt)
	if !amt then ErrorNoHalt("Itemforge Items: Couldn't set max holdable items. No amount was given!\n"); return false end
	self.MaxHeldItems=math.Clamp(amt,0,32);
	
	return true;
end

--[[
Protects a key in the base item-type
Stops items from overriding these keys by removing overrides after parsing item-types (and additionally if a protected key is being overwritten on an item, such as... myItem.Use="TEST").
Additionally this will alert the scripter that he's tried to override a protected key.
I know it's not 100% foolproof but the reason it's in place is to make sure that the items system keeps working in case of a careless mistake.
]]-- 
function MODULE:ProtectKey(key)
	if !key then ErrorNoHalt("Itemforge Items: Can't protect key - key not given.\n"); return false end
	if !AllowProtect then ErrorNoHalt("Itemforge Items: Can't protect key \""..key.."\" - can only protect keys from the base item-type.\n"); return false end
	
	ProtectedKeys[key]=true;
	return true;
end

--[[
Returns true if the given key is a protected key in the base item-type and can't (more like shouldn't) be overridden.
Returns false if it isn't.
]]--
function MODULE:IsProtectedKey(key)
	if ProtectedKeys[key]==true then return true end
	return false;
end

--[[
Creates a networked variable for a type of item.
The networked command should be created serverside and clientside, in the same order.
itemtype should usually be ITEM (assuming you're doing this in the itemtype's file)
sName is the name you want to give the network var. This can be whatever you want, it won't lag since this string will not be sent (to cut down on networking lag). Instead, the name is used to identify this var and associate it with an ID passed through networking.
sDatatype is what type of data this network var uses. Valid types are: int,integer,long,char,short,uchar,ulong,ushort,float,bool,boolean,str,string,ent,entity,pl,ply,player,vec,vector,ang,angle,item,inventory,inv, and color.
vDefaultValue is optional; it can either be a value (such as 1, "hello", 3.4, or true) or a function( such as function(self) return self:CanEatCake(); end).
	Whenever a network var hasn't been set (or is set to nil), and we need to grab the value of it, the default value will be returned.
	If no default value is given, then nil will be returned if the network var isn't set.
bPredicted is an optional true/false that defaults to false.
	If bPredicted is false, then whenever the networked var changes it is updated as soon as possible on the clients.
	If bPredicted is true, then whenever the networked var changes it is sent to the clients during the next server "tick" (there are about 3 of these per second).
bHoldFromUpdate is an optional true/false that defaults to false.
	If this is true, then whenever a player connects we won't send the networked var to him.
	This is useful for things that aren't really that important for joining players to know, such as "Next Attack Time".
bNoSave is an optional true/false that defaults to false.
	If this is false, the value of this networked var will be saved when the item is saved.
	If this is true, this networked var will never be saved when the item is saved.
	
	It should be known that networked vars are not saved if the networked var is the same as the default (IE, it has never been set, it has been set to nil, or has been set to something equal to the default value).
]]--
function MODULE:CreateNWVar(itemtype,sName,sDatatype,vDefaultValue,bPredicted,bHoldFromUpdate,bNoSave)
	if sName==nil then ErrorNoHalt("Itemforge Items: Couldn't create networked var. sName wasn't provided.\n"); return false end
	if itemtype==nil then ErrorNoHalt("Itemforge Items: Couldn't create networked var \""..sName.."\". itemtype wasn't provided (if this is being called inside of an item itemtype should be ITEM\n"); return false end
	if sDatatype==nil then ErrorNoHalt("Itemforge Items: Couldn't create networked var. The datatype wasn't provided.\n"); return false end
	
	if itemtype.NWVarsByName==nil then itemtype.NWVarsByName={} end
	if itemtype.NWVarsByID==nil then itemtype.NWVarsByID={} end
	
	if itemtype.NWVarsByName[sName]!=nil then ErrorNoHalt("Itemforge Items: Couldn't create networked var \""..sName.."\" - there's already a networked var with this name in this itemtype!\n"); return false end
	
	
	
	local NewNWVar={}
	NewNWVar.Name=sName;
	NewNWVar.Default=vDefaultValue;
	NewNWVar.Predicted=bPredicted or false;
	NewNWVar.HoldFromUpdate=bHoldFromUpdate or false;
	NewNWVar.Save=bNoSave or false;
	local t=string.lower(sDatatype);
		
	if t=="int" || t=="integer" || t=="long" || t=="char" || t=="short" || t=="uchar" || t=="uint" || t=="uinteger" || t=="ulong" || t=="ushort" then
		NewNWVar.Type=1;
	elseif t=="float" then
		NewNWVar.Type=2;
	elseif t=="bool" || t=="boolean" then
		NewNWVar.Type=3;
	elseif t=="str" || t=="string" then
		NewNWVar.Type=4;
	elseif t=="ent" || t=="entity" || t=="pl" || t=="ply" || t=="player" then
		NewNWVar.Type=5;
	elseif t=="vec" || t=="vector" then
		NewNWVar.Type=6;
	elseif t=="ang" || t=="angle" then
		NewNWVar.Type=7;
	elseif t=="item" then
		NewNWVar.Type=8;
	elseif t=="inventory" || t=="inv" then
		NewNWVar.Type=9;
	elseif t=="color" then
		NewNWVar.Type=10;
	else
		ErrorNoHalt("Itemforge Items: Bad datatype for NWVar \""..sName.."\". \""..t.."\" is invalid; valid types are:\n int,integer,long,char,short,uchar,ulong,ushort,float,bool,boolean,str,string,ent,entity,pl,ply,player,vec,vector,ang,angle,item,inventory,inv,and color\n");
		NewNWVar.Type=0;
	end
	
	itemtype.NWVarsByName[sName]=NewNWVar;
	NewNWVar.ID=table.insert(itemtype.NWVarsByID,NewNWVar);
end

--[[
Creates a networked command for a type of item.
The networked command should be created serverside and clientside, in the same order.
itemtype should usually be ITEM (assuming you're doing this in the itemtype's file)
sName is the name you want to give the network command.
	This will not be sent (to cut down on networking lag), so you can make this as long or short as you want.
	Instead, the name is used to identify this command and associate it with an ID passed through networking.
fHook is called if there's an incoming NWCommand with this name.
	fHook should be nil if this command is SENT from this side.
	fHook should NOT be nil if this command is RECEIVED on this side.
	If you send a NWCommand serverside, then Hookfunc will be called clientside.
	If you send a NWCommand clientside, then Hookfunc will be called serverside.
tDatatypes is a table, which contains the types of data that will be sent with the command.
	This can be nil if there is no data sent/received with this command.
	If tDatatypes was {"bool","short"} that means it's expecting the first piece of data to be a bool, and the second to be a short whenever you send (and receive) the command.
	valid types are:\n int,integer,long,char,short,float,bool,boolean,str,string,ent,entity,pl,ply,player,vec,vector,ang,angle,item,inv,inventory,uchar,ushort, and ulong
	
Here's an example of how to create a network command that is sent from the server and received on the client.
	NWCommands are created on both the server and client.
	
	ON SERVER:
		IF.Items:CreateNWCommand(ITEM,"MyNWCommand",nil,{"bool","short"});
	
	ON CLIENT:
		function ITEM:myHookName(bool,short)
			Msg("MyNWCommand received from server!\n");
			Msg("Bool is: "..tostring(bool).."!\n");
			Msg("Short is: "..tostring(short).."\n");
		end
		
		--Notice that our function above is ITEM:myHookName, but our hook is ITEM.myHookName
		IF.Items:CreateNWCommand(ITEM,"MyNWCommand",ITEM.myHookName,{"bool","short"});

I'll probably explain this in a tutorial or something. Must be overwhelming.
]]--
function MODULE:CreateNWCommand(itemtype,sName,fHook,tDatatypes)
	if sName==nil then ErrorNoHalt("Itemforge Items: Couldn't create networked command. sName wasn't provided.\n"); return false end
	if itemtype==nil then ErrorNoHalt("Itemforge Items: Couldn't create networked command \""..sName.."\". itemtype wasn't provided (if this is being called inside of an item script, itemtype should be ITEM\n"); return false end
	
	if itemtype.NWCommandsByName==nil then itemtype.NWCommandsByName={} end
	if itemtype.NWCommandsByID==nil then itemtype.NWCommandsByID={} end
	
	if itemtype.NWCommandsByName[sName]!=nil then ErrorNoHalt("Itemforge Items: Couldn't create networked command \""..sName.."\" - there is already a networked command with this name in this itemtype!\n"); return false end
	
	local newNWCommand={};
	newNWCommand.Name=sName;
	newNWCommand.Hook=fHook;
	newNWCommand.Datatypes={};
	
	if type(tDatatypes)=="table" then
		for i=1,table.maxn(tDatatypes) do
			local t=string.lower(tDatatypes[i]);
			
			if t=="int" || t=="integer" || t=="long" then
				table.insert(newNWCommand.Datatypes,1);
			elseif t=="char" then
				table.insert(newNWCommand.Datatypes,2);
			elseif t=="short" then
				table.insert(newNWCommand.Datatypes,3);
			elseif t=="float" then
				table.insert(newNWCommand.Datatypes,4);
			elseif t=="bool" || t=="boolean" then
				table.insert(newNWCommand.Datatypes,5);
			elseif t=="str" || t=="string" then
				table.insert(newNWCommand.Datatypes,6);
			elseif t=="ent" || t=="entity" || t=="pl" || t=="ply" || t=="player" then
				table.insert(newNWCommand.Datatypes,7);
			elseif t=="vec" || t=="vector" then
				table.insert(newNWCommand.Datatypes,8);
			elseif t=="ang" || t=="angle" then
				table.insert(newNWCommand.Datatypes,9);
			elseif t=="item" then
				table.insert(newNWCommand.Datatypes,10);
			elseif t=="inventory" || t=="inv" then
				table.insert(newNWCommand.Datatypes,11);
			elseif t=="uchar" then
				table.insert(newNWCommand.Datatypes,12);
			elseif t=="ulong" then
				table.insert(newNWCommand.Datatypes,13);
			elseif t=="ushort" then
				table.insert(newNWCommand.Datatypes,14);
			else
				ErrorNoHalt("Itemforge Items: CreateNWCommand (\""..sName.."\") given unrecognized datatype "..t.."; valid types are:\n int,integer,long,char,short,float,bool,boolean,str,string,ent,entity,pl,ply,player,vec,vector,ang,angle,item,inv,inventory,uchar,ushort, and ulong\n");
				table.insert(newNWCommand.Datatypes,0);
			end
		end
	elseif tDatatypes!=nil then
		ErrorNoHalt("Itemforge Items: CreateNWCommand's (\""..sName.."\") fourth argument, tDatatypes, takes a table, not a "..type(tDatatypes).."!\n");
		return false;
	end
	
	
	itemtype.NWCommandsByName[sName]=newNWCommand;
	newNWCommand.ID=table.insert(itemtype.NWCommandsByID,newNWCommand);
	
	return true;
end

--TODO I'm not satisfied with the way this function works; consider reworking it sometime
--[[
Searches the Items[] table for an empty slot.
iFrom is an optional number describing where to start searching in the table.
	If this number is not given, is over the max number of items, or is under 1, it will be set to 1.
This function will keep searching until:
	It finds an open slot.
	It has gone through the entire table once.
The index of an empty slot is returned if one is found, or nil is returned if one couldn't be found.
]]--
function MODULE:FindEmptySlot(iFrom)
	--Wrap around to 1 if iFrom wasn't given or was under zero or was over the item limit
	if !iFrom || iFrom>self.MaxItems || iFrom<1 then iFrom=1; end
	
	local count=1;
	while count<=self.MaxItems do
		if Items[iFrom]==nil then return iFrom end
		count=count+1;
		iFrom=iFrom+1;
		if iFrom>self.MaxItems then iFrom=1 end
	end
	return nil;
end

--[[
Starts Itemforge Item's tick
]]--
function MODULE:StartTick()
	hook.Add("Tick","itemforge_tick",self.Tick,self)
end

--[[
This runs the Tick() function on every active item on the server (Serverside and Clientside)
]]--
function MODULE:Tick()
	for k,v in pairs(ItemRefs) do
		v:Tick();
	end
end

--[[
Stops Itemforge Item's tick
]]--
function MODULE:StopTick()
	hook.Remove("Tick","itemforge_tick");
end

--[[
Creates an item of this type. This should only be called on the server by a scripter. Clientside, this is called to sync creation.

Once the item has been created, it will be floating around in the void (not in the world or in an inventory).
You'll have to place it in the world, in a player's hands, an inventory, or simply leave it in the void.
I personally suggest doing one of the first three, so you don't lose track of items in the void.

If you want a more convenient solution, try:
	IF.Items:CreateInWorld(type,pos,ang);
	IF.Items:CreateHeld(type,player);
	IF.Items:CreateInInventory(type,inventory);
	IF.Items:CreateInInv(type,inventory);
	IF.Items:CreateSameLocation(type,otherItem);

id is only required when creating items clientside. This is the item id to give the created item.
fullUpd is only used on the client. This will be true only if creating the item is part of a full update.
owner is an optional player given serverside.
	If this player is given, only this player will be told to create the item (usually the only reason this is given is because the item is being created in a private inventory)
bPredict is an optional true/false that defaults to false on the server and true on the client. If bPredict is:
	false, then if successful we'll register and return a new item. nil will be returned if unsuccessful for any reason.
	true, then if we determine the item can be created, a temporary item that can be used for further prediction tests will be returned. nil will be returned otherwise.
]]--
function MODULE:Create(type,id,fullUpd,owner,bPredict)
	if type==nil then ErrorNoHalt("Itemforge Items: Could not create item. No type was provided.\n"); return nil end
	type=string.lower(type);
	
	if bPredict==nil then bPredict=CLIENT end
	
	--[[
	Make sure the itemtype we want is valid (has loaded succesfully)
	If it's not, a few things could be causing this.
	    Parsing errors serverside or clientside may be at work (meaning there's probably a typo in your script)
	    If the item can be created serverside with no trouble, but can't be created clientside...
	        Make sure that all the necessary files are being sent (included with AddCSLuaFile). You can check this with the "dumptables" console command.
	        Check the server console. Apparantly, lua files are compiled before they are sent to the clients. If there are parsing errors dealing with clientside files, this may be to blame.
	]]--
	if ItemTypes[type]==nil then
		if SERVER then	ErrorNoHalt("Itemforge Items: Could not create item, \""..type.."\" is not a valid item-type. Check for parsing errors in console or mis-spelled item-type.\n"); 
		else			ErrorNoHalt("Itemforge Items: Could not create item, \""..type.."\" is not a valid item-type. Check for item scripts not being sent!\n");
		end
		return nil;
	end
	
	--[[
	We need to find an ID for the soon-to-be created item.
	We'll either use an ID that is not in use at the moment, which is usually influenced by the number of items created so far
	or a requested ID likely sent from the server
	]]--
	local n;
	if SERVER || (bPredict && !id) then
		n=NextItem;
		if Items[n]!=nil then
			n=self:FindEmptySlot(n+1);
			
			if n==nil then ErrorNoHalt("Itemforge Items: Couldn't create item - no free slots (all "..self.MaxItems.." slots occupied)!\n"); return nil; end
		end
		
		NextItem=n+1;
		if NextItem>self.MaxItems then NextItem=1 end
	else
		if id==nil then ErrorNoHalt("Itemforge Items: Could not create \""..type.."\" clientside, the ID of the item to be created wasn't given!\n"); return nil end
		n=id;
	end
	
	--When an item is updated, Create is called before updating it. That way if the item doesn't exist it's created in time for the update.
	if CLIENT && fullUpd==true && self.FullUpInProgress==true && !bPredict then
		self.FullUpCount=self.FullUpCount+1;
		self.FullUpItemsUpdated[n]=true;
	end
	
	--Does the item exist already? No need to recreate it.
	--TODO possible bug here; what if a dead item clientside blocks new items with the same ID from being created?
	if Items[n] then
		--We only need to bitch about this on the server. Full updates of an item clientside will tell the item to be created regardless of whether it exists or not. If it exists clientside we'll just ignore it.
		if SERVER && !bPredict then
			ErrorNoHalt("Itemforge Items: Could not create \""..type.."\", with id "..n..". An item with this ID already exists!\n");
		end
		
		return nil;
	end
	
	if bPredict then n=0 end
	
	local newitem={};					--Create a new item
	newitem.Class=ItemTypes[type];		--Set the item type to the type provided
	newitem.ID=n;						--Set item ID (the item ID is stored in both the reference and the item itself)
	setmetatable(newitem,imt);			--Setting the meta table makes the item able to use everything the item-type has. It searches the item-type for functions and default values.
	
	local newref={};					--Create a new item reference
	BindReference(newref,newitem,n);	--We tell the new reference to refer to the new item and store the ID it uses
	
	if !bPredict then
		Items[n]=newitem;					--Register the item in array
		ItemRefs[n]=newref;
		ItemsByType[type][n]=newref;		--Register in "items by type" array
		
		--We'll tell the clients to create and initialize the item as well
		if SERVER then self:CreateClientside(newref,owner); end
		
		--Items will be initialized right after being created
		--TODO predicted items need to initialize too but not do any networking shit
		newref:Initialize(owner);
	end
	
	--Return a reference to the newly created item
	return newref;
end

--[[
Creates an item and then places it in the given inventory
If the creation succeeds, the item created is returned. Otherwise, nil is returned.
]]--
function MODULE:CreateInInventory(type,inv,bPredict)
	if type==nil then ErrorNoHalt("Itemforge Items: Tried to create item in inventory, but type of item to create was not given!\n"); return nil end
	if !inv or !inv:IsValid() then ErrorNoHalt("Itemforge Items: Tried to create item in inventory, but given inventory was not valid!\n"); return nil end
	
	if bPredict==nil then bPredict=CLIENT end
	
	--Get the owner of the inventory. The item will be networked to this player only.
	local owner=inv:GetOwner();
	
	local item=self:Create(type,nil,false,owner,bPredict);
	if !item then return nil end
	
	--TODO PREDICT
	if !bPredict && !item:ToInventory(inv,nil,owner) then
		item:Remove(true);
		return nil;
	end
	
	return item;
end
MODULE.CreateInInv=MODULE.CreateInInventory;

--[[
Creates an item and then places it in the world at the given position and angles.
type is the type of item you want to create.
vWhere is an optional position you want to create the item at in the world. This defaults to Vector(0,0,0).
aAngles is an optional Angle() you want to rotate the item to. This defaults to Angle(0,0,0).
bPredict is an

If the creation succeeds, the item created is returned. Otherwise, nil is returned.
]]--
function MODULE:CreateInWorld(type,vWhere,aAngles,bPredict)
	if type==nil then ErrorNoHalt("Itemforge Items: Tried to create item in world but type of item to create was not given!\n"); return nil end
	
	vWhere=vWhere or Vector(0,0,0);
	if bPredict==nil then bPredict=CLIENT end
	
	--Create the item.
	local item=self:Create(type,nil,nil,nil,bPredict);
	if !item then return nil end
	
	--TODO PREDICT
	if !bPredict && !item:ToWorld(vWhere,aAngles) then
		item:Remove(true);
		return nil;
	end
	
	return item;
end

--[[
Creates an item and then places it in the hands of a player as a weapon.
If the creation succeeds, the item created is returned. Otherwise, nil is returned.
]]--
function MODULE:CreateHeld(type,pPlayer,bPredict)
	if type==nil then ErrorNoHalt("Itemforge Items: Tried to create item as weapon but type of item was not given!\n"); return nil end
	if pPlayer==nil then ErrorNoHalt("Itemforge Items: Tried to create item as weapon but player to give the item to wasn't given!\n"); return nil end
	
	if bPredict==nil then bPredict=CLIENT end
	
	local item=self:Create(type,nil,nil,nil,bPredict);
	if !item then return nil end
	
	--TODO PREDICT
	if !bPredict && !item:Hold(pPlayer) then
		item:Remove(true);
		return nil;
	end
	
	return item;
end

--[[
Creates an item and places it in the same location as an existing item.
This function is probably best for things that are breaking apart (such as a pickaxe breaking into a pickaxe head and a stick)
extItem is an existing item. The new item will be created in the same location as it.

The new item will be created in...
	the same container that this item is in, if 'extItem' is in a container.
	nearby this item, if 'extItem' in the world.
	where the player is looking, if 'extItem' is held by a player (because a player can only hold one item at a time).
	
The newly created item will be returned if all goes well, or nil will be returned in case of errors.
TODO this sucks, fix it
]]--
function MODULE:CreateSameLocation(type,extItem,bPredict)
	if type==nil then ErrorNoHalt("Itemforge Items: Tried to create item in same location as other item, but type of item to create was not given!\n"); return nil end
	if !extItem or !extItem:IsValid() then ErrorNoHalt("Itemforge Items: Tried to create \""..type.."\" in same location as other item, but other item wasn't given!\n"); return nil end
	
	if bPredict==nil then bPredict=CLIENT end
	
	local item=self:Create(type,nil,nil,nil,bPredict);
	if !item then return nil end
	
	--TODO predict
	if !bPredict && !item:ToSameLocationAs(extItem,nil,true) then
		--DEBUG
		Msg("Couldn't create in same location, removing.\n");
		item:Remove();
		return nil;
	end
	
	return item;
end

--[[
This will remove an existing item. item:Remove() calls this. When this function is run, the OnRemove() hook on an item is triggered.
item should be an existing item.
]]--
function MODULE:Remove(item)
	if !item or !item:IsValid() then ErrorNoHalt("Itemforge Items: Could not remove item given - doesn't exist!\n"); return false end
	if item.BeingRemoved==true then
		return false;
	else
		item.BeingRemoved=true;
	end
	
	item:Event("OnRemove");
	
	--Stop thinking if we're thinking, stop all looping sounds and active timers
	item:StopThink();
	item:StopAllLoopingSounds();
	item:RemoveAllTimers();
	
	--Hide the right click menu if it is open
	if CLIENT then item:KillMenu() end
	
	--Unlink any inventories that are connected to this item (an inventory "belonging" to this item - ex: a backpack's inventory or a crate's inventory)
	if item.Inventories then
		if SERVER then
			for k,v in pairs(item.Inventories) do
				v.Inv:SeverItem(v.ConnectionSlot,true);
			end
		else
			for k,v in pairs(item.Inventories) do
				v.Inv:SeverItem(v.ConnectionSlot);
			end
		end
	end
	
	--Remove entity, swep, or remove from inventory.
	if SERVER then
		item:ToVoid(true,nil,true);
	else
		item:ToVoid(true,nil,nil,false);
	end
	
	local type=item:GetType();
	local id=item:GetID();
	
	--Tell clients to remove too
	if SERVER then
		self:RemoveClientside(id);
	end
	
	--Clear item from collection, invalidate item reference (disconnect it from the actual item), remove reference from collection, remove from ItemsByType collection
	Items[id]=nil;
	ItemRefs[id]:Invalidate();
	ItemRefs[id]=nil;
	ItemsByType[type][id]=nil;
	
	return true;
end

--[[
Returns true if the given entity is actually an item in the world (an "itemforge_item" entity).
Returns false otherwise.
]]--
function MODULE:IsEntItem(eEnt)
	if !eEnt || !eEnt:IsValid() then return false end
	if eEnt:GetClass()=="itemforge_item" then return true end
	return false;
end

--[[
Returns true if the given weapon is actually an item being held by a player (an "itemforge_item_held*" entity)
]]--
function MODULE:IsWeaponItem(eWep)
	if !eWep || !eWep:IsValid() then return false end
	for i=1,self.MaxHeldItems do
		if eWep:GetClass()=="itemforge_item_held_"..i then return true end
	end
	return false;
end

--[[
If the given entity is actually an item in the world, returns the item.
Returns nil otherwise.
]]--
function MODULE:GetEntItem(eEnt)
	if !eEnt || !eEnt:IsValid() then return nil end
	if eEnt:GetClass()!="itemforge_item" then return nil end
	return eEnt:GetItem();
end

--[[
If the given weapon is actually an item being held by a player, returns the item.
Returns nil otherwise.
]]--
function MODULE:GetWeaponItem(eWep)
	if !eWep || !eWep:IsValid() then return nil end
	for i=1,self.MaxHeldItems do
		if eWep:GetClass()=="itemforge_item_held_"..i then return eWep:GetItem() end
	end
	return nil;
end

--[[
This returns a reference to an item with the given ID.
For all effective purposes this is the same thing as returning the actual item,
except it doesn't hinder garbage collection,
and helps by warning the scripter of careless mistakes (still referencing an item after it's been deleted).
This returns an item reference (a table) if successful, and nil if there is no reference with that ID.
]]--
function MODULE:Get(id)
	return ItemRefs[id];
end

--[[
Returns a table of all items currently available to Itemforge.
Please note:
	This function copies the entire table of item references every time it is run. Do not run it all the time! That lags!
	If this function is run on the client, the client may not have every single item the server has (because of private inventories and lag).
	However, this function will always return every single item serverside, regardless of who owns it.
TODO possibly a more efficient alternative
]]--
function MODULE:GetAll()
	local t={};
	
	for k,v in pairs(ItemRefs) do
		t[k]=v;
	end
	
	return t;
end

--[[
Returns a table of all items with a given type currently available to Itemforge.
TODO possibly a more efficient alternative
]]--
function MODULE:GetByType(sType)
	local t={};
	
	for k,v in pairs(ItemsByType[sType]) do
		t[k]=v;
	end
	
	return t;
end

--[[
Returns a list of all item types.
Please note:
	This function copies the entire table of item types every time it is run. Do not run it all the time! That lags!
	Don't modify the item-types. If you do, every currently spawned item with that item-type may change.
TODO ensure that item-types are write protected in metatable, find a more efficient alternative.
]]--
function MODULE:GetTypes()
	local t={};
	
	for k,v in pairs(ItemTypes) do
		t[k]=v;
	end
	
	return t;
end

--[[
Returns the item type by name sName.
NOTE: If your item is based off of another item, you can access it's type by doing self["base_class"] (where self is your item, and base_class is whatever it's based off of, like base_lock, base_item, whatever)
If the item type exists, returns it. Otherwise, returns nil.
]]--
function MODULE:GetType(sName)
	return ItemTypes[sName];
end

--TEMPORARY/DEBUG
function MODULE:DumpItems()
	dumpTable(Items);
end

--TEMPORARY/DEBUG
function MODULE:DumpItemRefs()
	dumpTable(ItemRefs);
end

--TEMPORARY/DEBUG
function MODULE:DumpItem(id)
	dumpTable(Items[id]);
end




--Server only
if SERVER then




--[[
Asks the client to create an item clientside. When the request to create the item arrives clientside, if the item already exists it is disregarded.
item is an existing, valid item that needs to be created.
If pl isn't nil, this function will only tell that player to create the item. Otherwise, all players are instructed to create this item clientside.
fullUpd is optional. This should only be true if this item is being created as part of a full update.

True will be returned if there are no errors. False is returned otherwise.
]]--
function MODULE:CreateClientside(item,pl,fullUpd)
	if !item or !item:IsValid() then ErrorNoHalt("Itemforge Items: Couldn't CreateClientside - Item given isn't valid!\n"); return false end
	
	--Validate player
	if pl!=nil then
		if !pl:IsValid() then ErrorNoHalt("Itemforge Items: Couldn't CreateClientside - The player to send "..tostring(item).." to isn't valid!\n"); return false;
		elseif !pl:IsPlayer() then ErrorNoHalt("Itemforge Items: Couldn't CreateClientside - The player to send "..tostring(item).." to isn't a player!\n"); return false;
		end
	else
		local allSuccess=true;
		for k,v in pairs(player.GetAll()) do
			if !self:CreateClientside(item,v,fullUpd) then allSuccess=false end
		end
		return allSuccess;
	end
	
	self:IFIStart(pl,IFI_MSG_CREATE,item:GetID());
	self:IFIString(item:GetType());
	self:IFIBool(fullUpd==true);
	self:IFIEnd();
	
	return true;
end

--[[
Asks the client to remove an item clientside.
itemid is the ID of an item that needs to be removed. We use itemid here instead of item because the item has probably already been removed serverside, and we would need to run :GetID() on a non-existent item in that case
If pl is given/isn't nil, this function will only tell that player to remove the item. Otherwise, all players are instructed to remove this item clientside.
]]--
function MODULE:RemoveClientside(itemid,pl)
	if itemid==nil then ErrorNoHalt("Itemforge Items: Couldn't RemoveClientside - No itemid was given!\n"); return false end
	
	--Validate player
	if pl!=nil then
		if !pl:IsValid() then ErrorNoHalt("Itemforge Items: Couldn't RemoveClientside - The player to remove the item from isn't valid!\n"); return false; end
		if !pl:IsPlayer() then ErrorNoHalt("Itemforge Items: Couldn't RemoveClientside - The player remove the item from isn't a player!\n"); return false; end
	else
		local allSuccess=true;
		for k,v in pairs(player.GetAll()) do
			if !self:RemoveClientside(itemid,v) then allSuccess=false end
		end
		return allSuccess;
	end
	
	self:IFIStart(pl,IFI_MSG_REMOVE,itemid);
	self:IFIEnd();
	
	return true;
end

--[[
Remove an item clientside on all players except for the given player.
--TODO rename to RemoveClientsideToAllBut
]]--
function MODULE:RemoveClientsideOnAllBut(itemid,pl)
	if itemid==nil then ErrorNoHalt("Itemforge Items: Couldn't RemoveClientsideOnAllBut - No itemid was given!\n"); return false end
	
	--Validate player
	if pl==nil then ErrorNoHalt("Itemforge Items: Couldn't RemoveClientsideOnAllBut - No player was given!\n"); return false
	elseif !pl:IsValid() then ErrorNoHalt("Itemforge Items: Couldn't RemoveClientsideOnAllBut - The player to remove item with ID "..itemid.." from isn't valid!\n"); return false;
	elseif !pl:IsPlayer() then ErrorNoHalt("Itemforge Items: Couldn't RemoveClientsideOnAllBut - The player to remove item with ID "..itemid.." from isn't a player!\n"); return false;
	end
	
	for k,v in pairs(player.GetAll()) do
		if v!=pl then self:RemoveClientside(itemid,v) end
	end
	
	return true;
end

--[[
Sends a full update on an item, as requested by a client usually.
If the item doesn't exist serverside then instead of a full update, the client will be told to remove that item.
This should not be used unless necessary.
itemid is the ID of the item to send an update of. We use the ID because, as previously stated, the item could possibly not exist on the server.
pl is the player to send the update of the item to.
This returns true if successful, or false if not.
]]--
function MODULE:SendFullUpdate(itemid,pl)
	if !itemid then ErrorNoHalt("Itemforge Inventories: Couldn't send a full update of an item... the item ID wasn't given.\n"); return false end
	
	--Validate player
	if pl!=nil then
		if !pl:IsValid() then ErrorNoHalt("Itemforge Items: Couldn't send full update of item with ID "..itemid.." - The player given isn't valid!\n"); return false;
		elseif !pl:IsPlayer() then ErrorNoHalt("Itemforge Items: Couldn't send full update of item with ID "..itemid.." - The player given isn't a player!\n"); return false; end
	else
		local allSuccess=true;
		for k,v in pairs(player.GetAll()) do
			if !self:SendFullUpdate(itemid,v) then allSuccess=false end
		end
		return allSuccess;
	end
	
	local item=self:Get(itemid);
	if !item || !item:IsValid() then
		--The item the update was requested on doesn't exist. Tell the client who requested the update to get rid of it.
		return self:RemoveClientside(itemid,pl);
	end
	
	return (self:CreateClientside(item,pl)&&item:SendFullUpdate(pl));
end

--Sends a full update of ONE item clientside on all players except for the given player.
--TODO rename to SendFullUpdateToAllBut instead
function MODULE:SendFullUpdateOnAllBut(item,pl)
	if !item or !item:IsValid() then ErrorNoHalt("Itemforge Items: Couldn't SendFullUpdateOnAllBut - Given item was invalid!\n"); return false end
	
	--Validate player
	if pl==nil then ErrorNoHalt("Itemforge Items: Couldn't send full update of "..tostring(item).." - No player was given!\n"); return false
	elseif !pl:IsValid() then ErrorNoHalt("Itemforge Items: Couldn't SendFullUpdateOnAllBut - The player to send "..tostring(item).." isn't valid!\n"); return false;
	elseif !pl:IsPlayer() then ErrorNoHalt("Itemforge Items: Couldn't SendFullUpdateOnAllBut - The player to send "..tostring(item).." isn't a player!\n"); return false;
	end
	
	local allSuccess=true;
	for k,v in pairs(player.GetAll()) do
		if v!=pl then
			if !self:SendFullUpdate(item:GetID(),v) then allSuccess=false end
		end
	end
	
	return allSuccess;
end

--[[
Creates all items applicable (the items that aren't in private inventories) as part of a full update on a given player clientside.
pl is the player to create items on clientside. This can be nil to send to all players
To do a full update on all items and inventories properly, all items should be created clientside first, then all inventories, then full updates of all items, and then full updates of all inventories.
True is returned if the items were created on the given player, OR if no items need to be sent to the player (this happens when there are no items, or when there are only private items not owned by that player). If the given player was nil, this returns false if one of the players couldn't have the items sent to him.
]]--
function MODULE:StartFullUpdateAll(pl)
	--Validate player
	if pl!=nil then
		if !pl:IsValid() then ErrorNoHalt("Itemforge Items: Couldn't start full update - The player to send items to isn't valid!\n"); return false; end
		if !pl:IsPlayer() then ErrorNoHalt("Itemforge Items: Couldn't start full update - The player to send items to isn't a player!\n"); return false; end
	
	--pl is nil so we'll create the items clientside on each player individually
	else
		local allSuccess=true;
		for k,v in pairs(player.GetAll()) do
			if !self:StartFullUpdateAll(v) then allSuccess=false end
		end
		return allSuccess;
	end
	
	--Old method
	--[[
	--We'll buffer the items to send here ahead of time.
	local itemBuffer={};
	for k,v in pairs(ItemRefs) do
		--Make sure to only send items the player can have
		if v:CanSendItemData(pl) then
			table.insert(itemBuffer,v);
		end
	end
	
	local c=table.getn(itemBuffer);
	if c>0 then
		self:IFIStart(pl,IFI_MSG_STARTFULLUPALL,c);
		self:IFIEnd();
	
		local allCreated=true;
		for i=1,c do
			if !self:CreateClientside(itemBuffer[i],pl,true) then allCreated=false end
		end
		return allCreated;
	end
	]]--
	
	
	--[[
	We buffer items for three reasons:
	So we get a list of items that can be sent to a player (determined by NetOwner mostly)
	So we know how many items of each type are being sent (to determine whether or not it's necessary to send a message to create items of that type)
	So we know how many items TOTAL are being sent (to determine if sending a full update is even necessary)
	]]--
	local totalCount=0;
	local itemBuffer={};
	for sType,tItems in pairs(ItemsByType) do
		itemBuffer[sType]={};
		for k,v in pairs(tItems) do
			if v:CanSendItemData(pl) then
				table.insert(itemBuffer[sType],k);
				totalCount=totalCount+1;
			end
		end
	end
	
	if totalCount>0 then
		self:IFIStart(pl,IFI_MSG_STARTFULLUPALL,totalCount);
		self:IFIEnd();
		
		--[[
		We can send up to this many items IDs in one usermessage at a time.
		It's important to set this number reasonably;
		If it's too small, the bandwidth saved with this method is negligible.
		If it's too large, the usermessage overflows and causes network problems.
		If I could pin down how much each datatype takes up in the usermessage I could send this more reliably
		]]--
		local limit=70;
		
		for sType,tIDs in pairs(itemBuffer) do
			--c is how many items of this type we need to send
			local c=table.getn(tIDs);
			
			if c>0 then
				--We can send up to "limit" items at a time, so instead of sending one huge message we send several small "batches" of messages.
				--Each batch begins at "a".
				local a=1;
				while a<=c do
					--We're sending "limit" items or "remaining" items (by remaining items I mean fewer than "limit" items, the "last batch" if you will)
					self:IFIStart(pl,IFI_MSG_CREATETYPE,math.min(limit,(c-a+1)));
					self:IFIString(sType);
					
					for i=a,math.min(a+(limit-1),c) do
						self:IFIShort(tIDs[i]-32768);
					end
					self:IFIEnd(pl);
					a=a+limit;
				end
			end
		end
	end
	return true;
end

--[[
Sends a full update on all items from the server to a player (or players).
If pl is a player:
	Returns true if a full update of each individual item was successfully sent to the given player or if the player didn't need any items sent to him (no items, or no items that could be sent to this player)..
	Returns false otherwise.
If pl is nil:
	It runs this function once for each player and returns true if this function succeeded (full update of all items sent successfully to that player) for every connected player.
	If successful full updates of all items couldn't be sent to all players, false is returned.
]]--
function MODULE:EndFullUpdateAll(pl)
	--Validate player if player given
	if pl!=nil then
		if !pl:IsValid() then ErrorNoHalt("Itemforge Items: Couldn't EndFullUpdateAll - The player to send full updates of all items to isn't valid!\n"); return false end
		if !pl:IsPlayer() then ErrorNoHalt("Itemforge Items: Couldn't EndFullUpdateAll - The player to send full updates of all items to isn't a player!\n"); return false end
	
	--pl is nil so we'll send a full update to each player individually and end this instance of the function when the rest complete
	else
		local allSuccess=true;
		for k,v in pairs(player.GetAll()) do
			if !self:EndFullUpdateAll(v) then allSuccess=false end
		end
		return allSuccess;
	end
	
	--We'll buffer the items to send here ahead of time.
	local itemBuffer={};
	for k,v in pairs(ItemRefs) do
		--Make sure to only send items the player can have
		if v:CanSendItemData(pl) then
			table.insert(itemBuffer,v);
		end
	end
	
	local c=table.getn(itemBuffer);
	if c>0 then
		local allSent=true;
		
		--Send full updates
		for i=1,c do
			if !itemBuffer[i]:SendFullUpdate(pl) then allSent=false end
		end
		
		self:IFIStart(pl,IFI_MSG_ENDFULLUPALL,0);
		self:IFIEnd();
		
		return allSent;
	end
	return true;
end


--[[
IFI usermessage functions are below.
These usermessage functions are here so the debugger can override them and peek at messages being sent.
All functions below behave exactly like umsg functions, except with a different syntax.
ex: umsg.Angle(a) becomes IF.Items:IFIAngle(a)

The only one that doesn't is IFI start. It starts an IFI usermessage and sets the type of message and player to send to.

pl is the player to send to (this should probably never be nil, packets tend to get sent out of order)
msg is an IFI constant (such as IFI_MSG_CREATE).
item is an optional item ID. 32768 will be subtracted from this automatically. This defaults to 0.
]]--
function MODULE:IFIStart(pl,msg,itemid) umsg.Start("ifi",pl); umsg.Char(msg); umsg.Short((itemid or 0)-32768) end
function MODULE:IFIAngle(v) umsg.Angle(v) end
function MODULE:IFIBool(v) umsg.Bool(v) end
function MODULE:IFIChar(v) umsg.Char(v) end
function MODULE:IFIEntity(v) umsg.Entity(v) end
function MODULE:IFIFloat(v) umsg.Float(v) end
function MODULE:IFILong(v) umsg.Long(v) end
function MODULE:IFIShort(v) umsg.Short(v) end
function MODULE:IFIString(v) umsg.String(v) end
function MODULE:IFIVector(v) umsg.Vector(v) end
function MODULE:IFIEnd() umsg.End() end

--Handles incoming "ifi" (Itemforge Item) messages from client
function MODULE:HandleIFIMessages(pl,command,args)
	if !pl || !pl:IsValid() || !pl:IsPlayer() then ErrorNoHalt("Itemforge Items: Couldn't handle incoming message from client - Player given doesn't exist or wasn't player!\n"); return false end
	if !args[1] then ErrorNoHalt("Itemforge Items: Couldn't handle incoming message from client "..tostring(pl).." - message type wasn't received.\n"); return false end
	if !args[2] then ErrorNoHalt("Itemforge Items: Couldn't handle incoming message from client "..tostring(pl).." - item ID wasn't received.\n"); return false end
	
	local msgType=tonumber(args[1]);
	local id=tonumber(args[2])+32768;
	
	if msgType==IFI_MSG_REQFULLUP then
		--Send a full update of the item to the client.
		self:SendFullUpdate(id,pl);
	elseif msgType==IFI_MSG_REQFULLUPALL then
		self:StartFullUpdateAll(pl);
		self:EndFullUpdateAll(pl);
	elseif msgType==IFI_MSG_CL2SVCOMMAND then
		local item=self:Get(id);
		if !item || !item:IsValid() then ErrorNoHalt("Itemforge Items: Tried to run a networked command (Client to Server) on non-existent item with ID "..id..".\n"); return false; end
		if !args[3] then ErrorNoHalt("Itemforge Items: Couldn't run a networked command (Client to Server) on "..tostring(item).." - Command ID not received.\n"); return false end
		
		item:ReceiveNWCommand(pl,tonumber(args[3])+128,string.Explode(" ",args[4]));
	else
		ErrorNoHalt("Itemforge Items: Unhandled IFI message \""..msgType.."\"\n");
		return false;
	end
	
	return true;
end

--We use a proxy here so we can make HandleIFIMessages a method (:) instead of a regular function (.)
concommand.Add("ifi",function(pl,command,args) return IF.Items:HandleIFIMessages(pl,command,args) end);




--Client only
else




--Called when a full update has started - We're expecting a certain number of items from the server
function MODULE:OnStartFullUpdateAll(count)
	self.FullUpInProgress=true;
	self.FullUpTarget=count;
end

--Called when a full update has ended. Did we get them all?
function MODULE:OnEndFullUpdateAll()
	if self.FullUpCount<self.FullUpTarget then
		ErrorNoHalt("Itemforge Items: Full item update only updated "..self.FullUpCount.." out of expected "..self.FullUpTarget.." items!\n");
	end
	
	--Remove non-updated items
	for k,v in pairs(ItemRefs) do
		if self.FullUpItemsUpdated[k]!=true then
			--DEBUG
			Msg("Itemforge Items: Removing "..tostring(v).." - only exists clientside\n");
			
			v:Remove();
		end
	end
	
	self.FullUpInProgress=false;
	self.FullUpTarget=0;
	self.FullUpCount=0;
	self.FullUpItemsUpdated={};
end


--Handles incoming "ifi" messages from server
function MODULE:HandleIFIMessages(msg)
	--Message type depends what happens next.
	local msgType=msg:ReadChar();
	local id=msg:ReadShort()+32768;
	
	if msgType==IFI_MSG_CREATE then
		local type=msg:ReadString();
		local fullUpRelated=msg:ReadBool();
		
		--Create the item clientside too. Use the ID provided by the server.
		self:Create(type,id,fullUpRelated,nil,false);
	elseif msgType==IFI_MSG_REMOVE then
		local item=self:Get(id);
		if !item then return false end
		
		--Remove the item clientside since it has been removed serverside.
		self:Remove(item);
	elseif msgType==IFI_MSG_CREATETYPE then
		local type=msg:ReadString();
		for i=1,id do
			self:Create(type,msg:ReadShort()+32768,true,nil,false);
		end
	elseif msgType==IFI_MSG_CREATEININV then
		--TODO Macro
		--self:
	elseif msgType==IFI_MSG_MERGE then
		--TODO Macro
		local item=self:Get(id);
		if !item then return false end
		
		local newAmt=msg:ReadLong();
		local otherItem=msg:ReadShort()+32768;
		
		item:SetAmount(newAmt);
		self:Remove(otherItem);
	elseif msgType==IFI_MSG_PARTIALMERGE then
		--TODO Macro
	elseif msgType==IFI_MSG_SPLIT then
		--TODO Macro
	elseif msgType==IFI_MSG_SV2CLCOMMAND then
		local item=self:Get(id);
		if !item then return false end
		
		item:ReceiveNWCommand(msg);
	elseif msgType>=IFI_MSG_SETANGLE && msgType<=IFI_MSG_SETNIL then
		local item=self:Get(id);
		local VarID=msg:ReadChar()+128;
		
		if !item then return false end
		
		if item.NWVarsByID[VarID]==nil then ErrorNoHalt("Itemforge Items: Couldn't find a networked var by ID "..VarID.." on "..tostring(item).."\n"); return false end
		local sName=item.NWVarsByID[VarID].Name;
		
		if msgType==IFI_MSG_SETANGLE then
			local vVal=msg:ReadAngle();
			
			item:ReceiveNWVar(sName,vVal);
		elseif msgType==IFI_MSG_SETBOOL then
			local vVal=msg:ReadBool();
			
			item:ReceiveNWVar(sName,vVal);
		elseif msgType==IFI_MSG_SETCHAR then
			local vVal=msg:ReadChar();
			
			item:ReceiveNWVar(sName,vVal);
		elseif msgType==IFI_MSG_SETCOLOR then
			local vVal=Color(msg:ReadChar()+128,msg:ReadChar()+128,msg:ReadChar()+128,msg:ReadChar()+128);
			
			item:ReceiveNWVar(sName,vVal);
		elseif msgType==IFI_MSG_SETENTITY then
			local vVal=msg:ReadEntity();
			
			item:ReceiveNWVar(sName,vVal);
		elseif msgType==IFI_MSG_SETFLOAT then
			local vVal=msg:ReadFloat();
			
			item:ReceiveNWVar(sName,vVal);
		elseif msgType==IFI_MSG_SETLONG then
			local vVal=msg:ReadLong();
			
			item:ReceiveNWVar(sName,vVal);
		elseif msgType==IFI_MSG_SETSHORT then
			local vVal=msg:ReadShort();
			
			item:ReceiveNWVar(sName,vVal);
		elseif msgType==IFI_MSG_SETSTRING then
			local vVal=msg:ReadString();
			
			item:ReceiveNWVar(sName,vVal);
		elseif msgType==IFI_MSG_SETVECTOR then
			local vVal=msg:ReadVector();
			
			item:ReceiveNWVar(sName,vVal);
		elseif msgType==IFI_MSG_SETITEM then
			local vVal=msg:ReadShort()+32768;
			iItem=IF.Items:Get(vVal);
			
			if !iItem then ErrorNoHalt("Itemforge Items: Tried to set a networked item (var ID "..VarID..") on "..tostring(item).." to non-existent item with ID "..vVal..".\n"); return false end
			
			item:ReceiveNWVar(sName,iItem);
		elseif msgType==IFI_MSG_SETINV then
			local vVal=msg:ReadShort()+32768;
			iInv=IF.Inv:Get(vVal);
			
			if !iInv then ErrorNoHalt("Itemforge Items: Tried to set a networked inventory (var ID "..VarID..") on "..tostring(item).." to non-existent inventory with ID "..vVal..".\n"); return false end
			
			item:ReceiveNWVar(sName,vVal);
		elseif msgType==IFI_MSG_SETUCHAR then
			local vVal=msg:ReadChar()+128;
			
			item:ReceiveNWVar(sName,vVal);
		elseif msgType==IFI_MSG_SETULONG then
			local vVal=msg:ReadLong()+2147483648;
			
			item:ReceiveNWVar(sName,vVal);
		elseif msgType==IFI_MSG_SETUSHORT then
			local vVal=msg:ReadShort()+32768;
			
			item:ReceiveNWVar(sName,vVal);
		elseif msgType==IFI_MSG_SETNIL then
			item:ReceiveNWVar(sName,nil);
		end
	elseif msgType==IFI_MSG_STARTFULLUPALL then
		self:OnStartFullUpdateAll(id);
	elseif msgType==IFI_MSG_ENDFULLUPALL then
		self:OnEndFullUpdateAll();
	else
		ErrorNoHalt("Itemforge Items: Unhandled IFI message \""..msgType.."\"\n");
	end
end

--We use a proxy here so we can make HandleIFIMessages a method (:) instead of a regular function (.)
usermessage.Hook("ifi",function(msg) return IF.Items:HandleIFIMessages(msg) end);




end