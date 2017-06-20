--[[
Itemforge Items Module
SHARED

This module implements items. The purpose of this module is to load item types, keep track of created items and item types,
handle inheritence between item types, handle networking of items between client and server, and much, much more.

theJ89's BUG list
BUG  Shotgun reload loop is failing when trying to reload from a stack of 1 items
BUG  net_fakelag 500 produces noticable problems with weapons. *sigh*
BUG  Weapons should have networked, predicted ammo counters instead of using :GetAmount() from the current ammo. This should fix the "dry fire on last shot clientside" bug with ranged weapons.
BUG  SWEP pickup issues (Give player weapon but he doesn't pick it up); waiting on garry for this
BUG	 Odd bug noticed; may be related to entity owner, entity collision group, or damage. Sometimes while in the world an item loses its collision, player can walk through it, can't use it, etc.
BUG  fix bug with SetNetOwner; is complaining about non-existent inventories table 
BUG  when updates are being sent to connecting players, the server often complains about not being able to index something on removed items... what is this about?
BUG  the new reusable IDs may interfere with full-update checks - If an old item 5 (lets pretend it's a crowbar) exists clientside and a new item 5 (lets say it's a base_ranged) is created, then it needs to override. This may be troublesome.
BUG  Possibly PVS related or something - players will often see other players holding nothing.
	 Items like the lantern stop working during lag spikes.
	 Lantern light sticks until the local player observes the player holding the lantern.
BUG  Sometimes players see bullets fired from other players... wierd!
	 POSSIBLE SOLUTION: Could this be due to firing bullets from the player? Maybe firing bullets from the SWEP could help!
BUG  Debug module is reporting message -114 is undefined for some clients
BUG  Okay, WTF? The pumpkin was both inside and outside of an inventory at the same time...

theJ89's Giant TODO list
This is why the system hasn't been released yet:

ADD OR FIX THIS UPDATE
TODO change inventory functions from MoveSlot to SwapSlot (functionality and name)
TODO looping sounds should resume when possible
TODO Spawning, dragdropping to world, throwing often stick the items in the world or in the player... ideally we don't want this to happen (Use hull traces! start/end 1 unit difference if just checking a point)
TODO Rope cutting code can be improved. Have rope cut function take a parameter (t) rather than plane info (center + normal). Check if ents in box can be used for length constraints (length constraint world space aabb?).
TODO Need to have SetSkin function that takes appropriate action (NOTE: may have to engineer ItemSlot displaying item to check for changes in skin [observer model with nwvar should fix this])
TODO Move ammo stuff to base weapon.
TODO Weapon events can ask ammo what to do
TODO Add firemodes to base weapon( objects / network objects, should assume "self" is the weapon and not the object)
TODO allow firemodes to be assigned to primary and secondary.
TODO Multiple cooldown timers (maybe just set a simple # of cooldown timers?) firemodes choose what cooldown timer they use, what cooldown timer(s) they delay. Setting cooldown timers sets primary/secondary weapon timer if primary/secondary firemode depends on that timer.
TODO migrate .ReloadsSingly related things from the shotgun to the base_ranged. ReloadsSingly should be a clip property, clips can possibly implement the start reload / end reload stuff.
TODO Use interface model for save/load objects. Create a different class of save/load objects for each kind of interface (text, mysql, singleplayer saves, etc). Have it like usermessage (read/write value by datatype)
TODO Use interface model for inventory attachments (ents / items will implement it)
TODO Use interface model for Wiremod as suggested by MegaDeath409 (Default wire interface implementor will use stub events, Wiremod implementer will use Wiremod events)
TODO wire outputs are forgotten when the item is taken out of the world and put back in; make an item wrapper that remembers them, restore when entity enters world
TODO It would probably be more convenient and more efficient to register Wiremod inputs and OnSetNWVar stuff as hooks instead.
TODO Ebayle's suggestion of numbering dynamically generated weapons (hash code?)
TODO Weapon centering can be improved by midpointing muzzle AP and valvebiped right hand positions as suggested by Ghor.
TODO sniper rifle's laser is better now that viewmodel animations are working, but needs some minor smoothing between viewmodel anim transitions
TODO sniper rifle zoom should move scope and reposition laser somewhere more appropriate
TODO Some kind of formal hierarchial system for items that allows them to parent to items, ents, whatever, used when inventories are considered overkill (i.e. parenting. Mostly useful for lock items, weapons [ammo/mods], but has other uses.)
TODO I have an idea. When an item is removed, if it's ID was lower than the "NextItem" ID, we can set NextItem to that to make better use of the slots. However, the reusable item ID bug will need to be fixed before I can implement this.
TODO As I implemented it before, prediction kind of sucks.
	 I bet I could improve it, though, by having it so you could activate prediction "mode",
	 then have writes to IF objects be stored in their own seperate prediction tables that get removed when prediction mode ends.
	 I'd have to take care to make sure that anything outside of Itemforge (like entities) also isn't modified in prediction mode, though.
	 Something related to this: Maybe using atomic operations could help here. In this way, if one of the sub-operations fails, the whole operation is considered a failure.
	 Something else related: We can apply a technique similiar to collision detection and resolution.
	 In this way, we simply perform the operation, then check to see if it was allowed.
	 If it wasn't, we resolve it by returning it to it's original state.
	 If it's accepted, we run the On* events. The events should be based on the previous state and current state (this would help with the inventory transitions).
TODO You can dragdrop stuff to/from another player's inventory... fix this (or not? allows stealing, which may be wanted. making the invs private would protect against this)
TODO Item wrappers for existing SWEP and SENTs.
TODO Port the SWEP turret. Improve upon it's entity emulator by having override libraries that are switched to during wrapped calls.

Code QA
TODO code maintainence... make sure that multi-line comments are used for function descriptions, check arguments, do cleanup code (for items listed in an inventory for example), for collections check to see if something being inserted still exists, check events to make sure they are all being pcalled, respond to errors well, test error situations, consider putting base item's events into their own lua file.
TODO I now realize I have such a shitty coding style. Whenever I get the time I should go through the files and apply my style guide for Future Game to Itemforge.
TODO remember to divide default files into sections: Methods, events, internal methods (things scripters won't be calling)
TODO pay attention to function return values; false should be returned for failures, true most of the other times

Item Ideas
TODO Wearable gear as suggested by Mr. Bix
TODO Flare gun as suggested by Mr. Bix
TODO Harpoon that can puncture things in a way similar to the sawblade

Events related
TODO possibly make hooks for both items and item types (ex: ITEMTYPE:Hook() creates a hook for all items of that type)
TODO OnPopulateMenu is stupid, rename it to OnMakeMenu or OnRightClick
TODO OnLeftClick/OnRightClick event for world entity & item icon??
TODO If OnInit returns false, remove the item

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
TODO When I get around to the networking update I need to use the Base64 code to encode binary to improve the client -> server networking.

UI related
TODO Need to come up with good looking Item Card
TODO redux of button icons for inventory?
TODO button bars? Have it so individual items can decide what their button bar creates, have so combinations can place

Item creation/removal related
TODO Duplicator support
TODO split and join behavior - for example, a stack of 2 items with an inventory splits; what then? Or, a heavily damaged item stacks with an intact item - average? lowest on top? sum? what?
TODO Need to have a tab on the spawn menu that allows you to spawn items in world(like entities)
TODO Need to have an entity that spawns a given item-type in the world (so items can be pre-placed on maps). Perhaps even an inventory-item entity which takes an item-type and an item (to allow items to be created in containers)

TODO - I have stuff marked with DEBUG and TEMPORARY, remove that before release
]]--

MODULE.Name					= "Items";						--Our module will be stored at IF.Items
MODULE.Disabled				= false;						--Our module will be loaded
MODULE.ItemsDirectory		= "itemforge/items/";			--What folder are the different item types stored in relative to the garrysmod/lua/ directory
MODULE.ExtensionsDirectory	= "extend"						--What folder are extensions for item types stored in relative to the item-type's folder (ex: if this is "extend" it means extensions for "item_crowbar" are stored in "garrysmod/lua/itemforge/items/item_crowbar/extend")?
MODULE.BaseEntityClassName	= "itemforge_item";				--What is the classname of the base entity that Itemforge uses? This is the entity that allows an item to exist in the world. 
MODULE.BaseWeaponClassName	= "itemforge_item_held";		--What is the classname of the base SWEP that Itemforge SWEPs are based off of? This is the SWEP that allows us to hold items.

if SERVER then


MODULE.TaskQueue = nil;										--A task queue for sending files


else


MODULE.FullUpInProgress		= false;						--If this is true a full update is being recieved from the server
MODULE.FullUpTarget			= 0;							--Whenever a full update starts, this is how many items need to be sent from the server.
MODULE.FullUpCount			= 0;							--Every time an item is created while a full update is being recieved, this number is increased by 1.
MODULE.FullUpItemsUpdated	= {};							--Every time an item is created while a full update is being recieved, FullUpItemsUpdated[Item ID] is set to true.
															--Whenever the full update finishes, we'll check to make sure all clientside items have been updated.
															--Any non-updated items are assumed to be removed on the server (since no update was recieved), and will be removed clientside.
end

--These are local on purpose. I want to prevent people from messing with ItemTypes so shit doesn't get screwy in case of some bad code. I'd also like people to use the Get function, and not grab the items directly from the table.
local BaseType				= "base_item";					--This is the undisputed absolute base item-type. All items inherit from this item.
local ItemTypes				= {};							--Item types. After being loaded from the script they are placed here
local ItemRefs				= {};							--Item references - there's an item reference for every item. We pass this instead of the actual item. By storing the references, the actual item the reference refers to can be properly garbage collected when it's removed (freeing up memory). It also informs the scripter of any careless mistakes (referencing an item after it has been deleted mostly).
local ItemsByType			= {};							--Items by type are stored here (ex ItemsByType["item_crowbar"] contains all item_crowbar items currently spawned)
local WorldItems			= {};							--All items in the world
local HeldItems				= {};							--All items that are held
local ThinkingItems			= {};							--All items that think every frame (item:StartThink() adds, item:StopThink() removes)
local MaxItems				= 65535;						--WARNING: Item IDs beyond this value CANNOT be sent through networking! DO NOT CHANGE. How many unique items can exist at a single time (a stack of items count as one unique item)?
local NextItem				= 1;							--This is a pointer of types, that records where the next item will be made. IDs are assigned based on this number. This only serves as a starting point to search for a free ID. If this slot is taken then it will search through the entire items array once to look for a free slot.
local ProtectedKeys			= {};							--This is a table of protected keys in the base item-type. If an item attempts to override a protected key, the console will report a warning and get rid of the override by setting it to nil. Likewise attempting to override a protected key on an item (myItem.Use="hello" for example) will be stopped as well.
local AllowProtect			= false;						--If this is true, we can protect keys (in other words, we're loading the base item-type while this is true)

local OldInclude = include;

--Lookup table for CreateNWVar. Used to convert a datatype string to a datatype ID.
local NWVDatatypeStrToID = {
	["int"]			= 1,	["integer"]	= 1,	["long"]	= 1,	["char"]	= 1,	["short"]	= 1,	["uchar"] = 1,	["uint"] = 1,	["uinteger"] = 1,	["ulong"] = 1,	["ushort"] = 1,
	["float"]		= 2,
	["bool"]		= 3,	["boolean"]	= 3,
	["str"]			= 4,	["string"]	= 4,
	["ent"]			= 5,	["entity"]	= 5,	["pl"]		= 5,	["ply"]		= 5,	["player"]	= 5,
	["vec"]			= 6,	["vector"]	= 6,
	["ang"]			= 7,	["angle"]	= 7,
	["item"]		= 8,
	["inventory"]	= 9,	["inv"]		= 9,
	["color"]		= 10,
};

--Lookup table for CreateNWCommand. Used to convert a datatype string to a datatype ID.
local NWCDatatypeStrToID = {
	["int"]			= 1,	["integer"]		= 1,	["long"]	= 1,
	["char"]		= 2,
	["short"]		= 3, 
	["float"]		= 4,
	["bool"]		= 5,	["boolean"]		= 5,
	["str"]			= 6,	["string"]		= 6,
	["ent"]			= 7,	["entity"]		= 7,	["pl"]		= 7,	["ply"] = 7,	["player"] = 7,
	["vec"]			= 8,	["vector"]		= 8,
	["ang"]			= 9,	["angle"]		= 9,
	["item"]		= 10,
	["inventory"]	= 11,	["inv"]			= 11,
	["uchar"]		= 12,
	["uint"]		= 13,	["uinteger"]	= 13,	["ulong"]	= 13,
	["ushort"]		= 14,
};

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
IFI_MSG_RELOAD			=	-99;		--(Server > Client) Server tells client to reload an itemtype

--[[
* SHARED

DoesLuaFileExist returns true if the given path in the lua directory does exist, false otherwise
LuaPath should be something like "itemforge/items/base_item/shared.lua"
]]--
local function DoesLuaFileExist( LuaPath )
	if SERVER then		return file.Exists( "../lua/"..LuaPath );
	else				return file.Exists( "../lua_temp/"..LuaPath ) or file.Exists( "../lua/"..LuaPath );
	end
end

--[[
* SHARED

DoesLuaFileExistCached returns true if the given path in the file cache (files received from the server after entering the game) does exist, false otherwise
LuaPath should be something like "itemforge/items/base_item/shared.lua"
]]--
local function DoesLuaFileExistCached( LuaPath )
	return IF.Util:FileIsCached( "lua/"..LuaPath );
end

--[[
* SHARED

IsLuaFolder will return false if you give it a file (or if the folder given doesn't exist), and true if you give it a folder.
LuaPath should be something like "itemforge/items/item"
]]--
local function IsLuaFolder( LuaPath )
	if SERVER then		return file.IsDir( "../lua/"..LuaPath );
	else				return file.IsDir( "../lua_temp/"..LuaPath ) or file.IsDir( "../lua/"..LuaPath );
	end
end








--[[
* SHARED

Initilize Items module.
Item-related hooks are added here.
]]--
function MODULE:Initialize()
	
	if SERVER then
		hook.Add( "GravGunPickupAllowed", "itemforge_items_gravgunpickupallowed",	function( ... ) return self:GravGunPickupAllowed( ... ) end );
		hook.Add( "GravGunOnPickedUp",	  "itemforge_items_gravgunonpickedup",		function( ... ) return self:GravGunOnPickedUp( ... )	end	);
		hook.Add( "GravGunOnDropped",	  "itemforge_items_gravgunondropped",		function( ... ) return self:GravGunOnDropped( ... )		end	);
		
		hook.Add( "OnPhysgunFreeze",	  "itemforge_items_onphysgunfreeze",		function( ... ) return self:PhysgunFreeze( ... )		end	);
		hook.Add( "CanPlayerUnfreeze",	  "itemforge_items_canplayerunfreeze",		function( ... ) return self:CanPlayerUnfreeze( ... )	end	);
	end

		hook.Add( "GravGunPunt",		  "itemforge_items_gravgunpunt",			function( ... ) return self:GravGunPunt( ... )			end	);

		hook.Add( "PhysgunPickup",		  "itemforge_items_physgunpickup",			function( ... ) return self:PhysgunPickup( ... )		end	);
		hook.Add( "PhysgunDrop",		  "itemforge_items_onphysgundrop",			function( ... ) return self:PhysgunDrop( ... )			end	);

		hook.Add( "Think",				  "itemforge_items_think",					function( ... ) return self:Think( ... )				end	);

	self:StartTick();
end

--[[
* SHARED

Clean up the items module.

Item-related hooks are removed here.
Removes all items.

Currently I have this done prior to a refresh.
It will remove any items and clean up any local stuff stored here.
TODO make this useful; actually use it somewhere
]]--
function MODULE:Cleanup()
	for k, v in pairs( ItemRefs ) do
		v:Remove();
	end
	
	if SERVER then
		hook.Remove( "GravGunPickupAllowed", "itemforge_items_gravgunpickupallowed"	);
		hook.Remove( "GravGunOnPickedUp",	 "itemforge_items_gravgunonpickedup"	);
		hook.Remove( "GravGunOnDropped",	 "itemforge_items_gravgunondropped"		);

		hook.Remove( "OnPhysgunFreeze",		 "itemforge_items_onphysgunfreeze"		);
		hook.Remove( "CanPlayerUnfreeze",	 "itemforge_items_canplayerunfreeze"	);
	end

		hook.Remove( "GravGunPunt",			 "itemforge_items_gravgunpunt"			);

		hook.Remove( "PhysgunPickup",		 "itemforge_items_physgunpickup"		);
		hook.Remove( "PhysgunDrop",			 "itemforge_items_onphysgundrop"		);

		hook.Remove( "Think",				 "itemforge_items_think"				);

	self:StopTick();
end

--[[
* SHARED

Load itemtypes.
This loads the items' scripts and can be used to refresh a changed item.
]]--
function MODULE:LoadItemTypes()
	if ItemTypes then ItemTypes = {}; end
	
	--List of all items in the items directory
	local itemFolders = file.FindInLua( self.ItemsDirectory.."*" );		--itemforge/items/*
	
	--Each folder is considered an item type. We'll try to load each one.
	for k,v in pairs( itemFolders ) do
		self:LoadItemType( v );
	end
end

--[[
* SHARED

Includes a file, generates an error and returns false if it can't be
opened and executed successfully.

Returns true otherwise.
]]--
local function PCallInclude( strFilepath )
	--TODO use file.Read and CompileString when addon/ bug in file.Read is fixed 
	local s, r = pcall( OldInclude, strFilepath );
	if !s then ErrorNoHalt( "Itemforge Items: Couldn't include file \""..strFilepath.."\": "..r.."\n" ); return false end
	return true;
end

--[[
* SHARED

Includes a file from the file cache.

Generates an error and returns false if it can't be opened and
executed successfully.

Returns true otherwise.
]]--
local		   PCallIncludeFileCachePath = "";
local function PCallIncludeFileCache( strFilepath )
	local OldDir = PCallIncludeFileCachePath;
	strFilepath  = OldDir..strFilepath;
	PCallIncludeFileCachePath = string.GetPathFromFilename( strFilepath );
	
	local bSuccess = true;
	
	local LuaPath = "lua/"..strFilepath;
	local strContents = IF.Util:FileCacheGet( LuaPath );
	if strContents then
		local s, r = pcall( CompileString, strContents, LuaPath );
		if s then
			local s, r = pcall( r );
			if !s then
				ErrorNoHalt( "Itemforge Items: Error executing included file \""..LuaPath.."\": "..r.."\n" );
				bSuccess = false
			end
		else
			ErrorNoHalt( "Itemforge Items: Couldn't include file \""..LuaPath.."\": "..r.."\n" );
			bSuccess = false;
		end
	else
		ErrorNoHalt( "Itemforge Items: Couldn't include file \""..LuaPath.."\", file could not be found in file cache.\n" );
		bSuccess = false;
	end
	
	PCallIncludeFileCachePath = OldDir;
	return bSuccess;
end

--[[
* SHARED

Loads and registers the requested itemtype.

strType is the name of the itemtype to load.
bDynamic is an optional true/false that's used in reloading changed itemtypes.
	It's use varies on server/client:
	On the server, if bDynamic is:
		false or not given, the file is just loaded on the server.
		true, then in addition we send the clientside files to the client then tell
			the client to reload.
	On the client, if bDynamic is:
		false or not given, then we load the file normally
			(from the lua cache he downloaded when he joined the server).
		true, then we load it from the sendfile cache.
			(stuff the server sent us after we joined)
]]--
function MODULE:LoadItemType( strType, bDynamic )
	if !IF.Util:IsString( strType ) then ErrorNoHalt( "Itemforge Items: Couldn't load item type, type to load wasn't given / wasn't a string.\n" ); return false end
	strType = string.lower( strType );
	if IF.Util:IsBadFolder( strType ) then return false end
	
	local path;
	path = self.ItemsDirectory..strType;						--itemforge/items/base_item
	
	include = PCallInclude;
	
	local Exists = DoesLuaFileExist;
	local tIncludeList;
	
	--If we use the dynamic approach we expect the file to be in the file cache.
	if bDynamic then
		if CLIENT then
			include = PCallIncludeFileCache;
			Exists = DoesLuaFileExistCached;
		else
			tIncludeList = {};
		end
	else
		if !IsLuaFolder( path ) then ErrorNoHalt( "Itemforge Items: Couldn't load item type \""..strType.."\", itemtype couldn't be located in lua/ folder." ); return false end
	end
	
	if strType == BaseType then AllowProtect = true end
	
	--We create a table in this function, and set ITEM to reference it at the global level.
	--This way, if somebody accidentilly does ITEM = nil in the item's code or in an extension, we won't lose the table.
	local tItemTable = {};
	ITEM = tItemTable;
	
	--[[
	Lets load an item type! (loads init if on the server, or cl_init if on the client.
	If either init or cl_init is missing, shared will be loaded if shared exists.
	If shared doesn't exist, nothing will be loaded.)
	AddCSLuaFile must be done manually. I try to make item scripts resemble entity/swep/effect scripts as much as possible.
	]]--
	local ServerPath = path.."/init.lua";
	local SharedPath = path.."/shared.lua";
	local ClientPath = path.."/cl_init.lua";
	if SERVER then
		
		if		Exists( ServerPath )		then	include( ServerPath );
		elseif	Exists( SharedPath )		then	include( SharedPath );
		end
		
		if bDynamic then
			if		Exists( ClientPath )	then	IF.Util:BuildIncludeList( "lua/"..ClientPath, tIncludeList );
			elseif	Exists( SharedPath )	then	IF.Util:BuildIncludeList( "lua/"..SharedPath, tIncludeList );
			end
		end
		
	else
		
		if		Exists( ClientPath )		then	include( ClientPath );
		elseif	Exists( SharedPath )		then	include( SharedPath );
		end
		
	end
	
	if ITEM == nil then ITEM = tItemTable end

	--Load extensions to this item if available (in the case that a scripter wants to add onto an existing item-type for his own purposes - such as adding "temperature" to the base item-type to give all items a temperature rating).
	--TODO reload support for extensions
	local extfolder = path.."/"..self.ExtensionsDirectory;					--itemforge/items/base_item/extend
	if !bDynamic && IsLuaFolder( extfolder ) then
		--List of all extensions in this item's extension folder
		local extensionFolders = file.FindInLua( extfolder.."/*" );			--itemforge/items/base_item/extend/*
		
		--We sort these because they need to load in the same order serverside and clientside
		table.sort( extensionFolders );
		
		for i = 1, #extensionFolders do
			local v = extensionFolders[i];
			if !IF.Util:IsBadFolder( v ) then
				--Load init serverside, cl_init clientside. In the abscence of either, load shared in it's place if it exists.
				local extpath = extfolder.."/"..v;							--itemforge/items/base_item/extend/temperature
				local ServerPath = extpath.."/init.lua";
				local SharedPath = extpath.."/shared.lua";
				local ClientPath = extpath.."/cl_init.lua";
				if SERVER then
					
					if		Exists( ServerPath ) then	include( ServerPath );
					elseif	Exists( SharedPath ) then	include( SharedPath );
					end
					
				else
					
					if		Exists( ClientPath ) then	include( ClientPath );
					elseif	Exists( SharedPath ) then	include( SharedPath );
					end
					
				end

				if ITEM == nil then ITEM = tItemTable end
			end
		end
	end
	
	include = OldInclude;
	
	--If a base was not given, the base is set to the base item-type.
	--Additionally we fix up any other missing data here.
	if tItemTable.Base				== nil		then	tItemTable.Base					= BaseType	end
	
	if tItemTable.NWVarsByName		== nil		then	tItemTable.NWVarsByName			= {}		end
	if tItemTable.NWVarsByID		== nil		then	tItemTable.NWVarsByID			= {}		end
	if tItemTable.NWCommandsByName	== nil		then	tItemTable.NWCommandsByName		= {}		end
	if tItemTable.NWCommandsByID	== nil		then	tItemTable.NWCommandsByID		= {}		end
	
	--Registers the class under the given name.
	if !IF.Base:RegisterClass( tItemTable, strType ) then ErrorNoHalt( "Itemforge Items: Couldn't register item-type; missing typename / ITEM table?\n" ); return false end
	
	ITEM = nil;								--Get rid of the temporary ITEM table
	AllowProtect = false;
	
	if SERVER && bDynamic then
		self:StartTaskQueue();

		for i = 1, #tIncludeList do
			self.TaskQueue:Add( function()
				if IF.Util:FileSendStart( tIncludeList[i], pl ) then return true end
				return IF.Util:FileSendTick();
			end );
		end
		
		self.TaskQueue:Add( function() self:ReloadItemType( strType ); return false end );
	end
	
	return true;
end

--[[
* SHARED

After a class has been inherited we register it as an item type,
create a collection of Items By Type, register an SWEP for it,
and create a network var / network command table for it.
]]--
function MODULE:ClassInherited( strType, tClass )
	--Store the item type just loaded
	ItemTypes[strType] = tClass;
	
	--Create an Items by Type table to store any items spawned of this type
	if ItemsByType[strType] == nil then ItemsByType[strType] = {}; end
	
	--Pool this string (increases network efficiency by substituting a smaller placeholder for this string when networked)
	if SERVER then umsg.PoolString( strType ); end
	
	--Register the SWEP this type of item uses.
	--I'd rather make all the items use one weapon but can't because of the goddamn viewmodel animations!!
	self:RegisterSWEP( tClass );
	
	local NWVarNames = {};
	local NWCommandNames = {};
	
	local NWVarIDs = {};
	local NWCommandIDs = {};
	
	local b = tClass;

	while b != nil do
		if b.NWVarsByID then
			for i = 1, #b.NWVarsByID do
				--If our itemtype doesn't have a var by this name yet then make a copy of it
				if NWVarNames[b.NWVarsByID[i].Name] == nil then
					local NWVarCopy				= {};
					NWVarCopy.Name				= b.NWVarsByID[i].Name;
					NWVarCopy.Default			= b.NWVarsByID[i].Default;
					NWVarCopy.Predicted			= b.NWVarsByID[i].Predicted;
					NWVarCopy.HoldFromUpdate	= b.NWVarsByID[i].HoldFromUpdate;
					NWVarCopy.Type				= b.NWVarsByID[i].Type;
					NWVarCopy.ID				= table.insert( NWVarIDs, NWVarCopy );
					NWVarNames[NWVarCopy.Name]	= NWVarCopy;
				end
			end
		end
		
		if b.NWCommandsByID then
			for i = 1, table.getn( b.NWCommandsByID ) do
				--If our itemtype doesn't have a command by this name yet then make a copy of it
				if NWCommandNames[b.NWCommandsByID[i].Name] == nil then
					local NWCommandCopy					= {};
					NWCommandCopy.Name					= b.NWCommandsByID[i].Name;
					NWCommandCopy.Hook					= b.NWCommandsByID[i].Hook;
					NWCommandCopy.Datatypes				= b.NWCommandsByID[i].Datatypes;
					NWCommandCopy.ID					= table.insert( NWCommandIDs, NWCommandCopy );
					NWCommandNames[NWCommandCopy.Name]	= NWCommandCopy;
				end
			end
		end
		
		b = b.BaseClass;
	end
	
	rawset( tClass, "NWVarsByName",		NWVarNames		);
	rawset( tClass, "NWCommandsByName",	NWCommandNames	);
	rawset( tClass, "NWVarsByID",		NWVarIDs		);
	rawset( tClass, "NWCommandsByID",	NWCommandIDs	);
end

--[[
* SHARED

Protects a key in the base item-type
Stops items from overriding these keys by removing overrides after parsing item-types (and additionally if a protected key is being overwritten on an item, such as... myItem.Use = "TEST" ).
Additionally this will alert the scripter that he's tried to override a protected key.
I know it's not 100% foolproof but the reason it's in place is to make sure that the items system keeps working in case of a careless mistake.

TODO nix this in favor of more generic
]]-- 
function MODULE:ProtectKey( vKey )
	if !vKey			then ErrorNoHalt( "Itemforge Items: Can't protect key - key not given.\n" ); return false end
	if !AllowProtect	then ErrorNoHalt( "Itemforge Items: Can't protect key \""..tostring( vKey ).."\" - can only protect keys from the base item-type.\n"); return false end
	
	if !ITEM._ProtectedKeys then ITEM._ProtectedKeys = {} end
	
	ITEM._ProtectedKeys[vKey] = true;
	return true;
end

--[[
* SHARED

Creates a networked variable for a type of item.
The networked command should be created serverside and clientside, in the same order.

itemtype should usually be ITEM (assuming you're doing this in the itemtype's file)
strName is the name you want to give the network var. This can be whatever you want, it won't lag since this string will not be sent (to cut down on networking lag).
	Instead, the name is used to identify this var and associate it with an ID passed through networking.
strDatatype is what type of data this network var uses.
	Valid types are: int, integer, long, char, short, uchar, ulong, ushort, float, bool, boolean, str, string, ent, entity, pl, ply, player, vec, vector, ang, angle, item, inventory, inv, and color.
vDefaultValue is optional; it can either be a value (such as 1, "hello", 3.4, or true) or a function( such as function( self ) return self:CanEatCake() end ).
	Whenever a network var hasn't been set (or is set to nil), and we need to grab the value of it, the default value will be returned.
	If no default value is given, then nil will be returned if the network var isn't set.
fnOnChange is an optional function. If fnOnChange is:
	nil or not given, no function is called when the network var changes.
	a function:
		function( self, strName, vNewValue )
		end

		self is the item the network var was changed on.
		strName was the name of the NWVar that was changed.
		vNewValue is the value that it was changed to.
bPredicted is an optional true/false that defaults to false.
	If bPredicted is false, then whenever the networked var changes it is updated as soon as possible on the clients.
	If bPredicted is true, then whenever the networked var changes it is sent to the clients during the next server "tick" (there are about 3 of these per second).
bHoldFromUpdate is an optional true/false that defaults to false.
	If this is true, then whenever a player connects we won't send the networked var to him.
	This is useful for things that aren't really that important for joining players to know, such as "Next Attack Time".

Returns true if the network var was created successfully.
]]--
function MODULE:CreateNWVar( itemtype, strName, strDatatype, vDefaultValue, fnOnChange, bPredicted, bHoldFromUpdate )
	if !IF.Util:IsString( strName )		then ErrorNoHalt( "Itemforge Items: Couldn't create networked var. strName wasn't a valid string.\n" );																						return false end
	if !IF.Util:IsTable( itemtype )		then ErrorNoHalt( "Itemforge Items: Couldn't create networked var \""..strName.."\". itemtype wasn't a valid table (if this is being called inside of an item itemtype should be ITEM\n" );	return false end
	if !IF.Util:IsString( strDatatype )	then ErrorNoHalt( "Itemforge Items: Couldn't create networked var. The datatype wasn't a string / wasn't given.\n" );																		return false end
	strDatatype = string.lower( strDatatype );

	if itemtype.NWVarsByName == nil then itemtype.NWVarsByName	= {} end
	if itemtype.NWVarsByID	 == nil then itemtype.NWVarsByID	= {} end
	
	if itemtype.NWVarsByName[strName] != nil then ErrorNoHalt( "Itemforge Items: Couldn't create networked var \""..strName.."\" - there's already a networked var with this name in this itemtype!\n" ); return false end
	
	local type = NWVDatatypeStrToID[strDatatype];
	if type == nil then
		ErrorNoHalt( "Itemforge Items: Bad datatype for NWVar \""..strName.."\". \""..strDatatype.."\" is invalid; valid types are:\n" );
		
		local l = #NWVDatatypeStrToID;
		for i = 1, l - 1 do
			ErrorNoHalt( NWVDatatypeStrToID[i]..", " );
		end
		ErrorNoHalt( " and "..NWVDatatypeStrToID[l]..".\n" );
		
		NewNWVar.Type = 0;
	end

	local NewNWVar			= {}
	NewNWVar.Name			= strName;
	NewNWVar.Type			= type;
	NewNWVar.ID				= table.insert( itemtype.NWVarsByID, NewNWVar );
	NewNWVar.Default		= vDefaultValue;
	NewNWVar.OnChange		= fnOnChange;
	NewNWVar.Predicted		= bPredicted or false;
	NewNWVar.HoldFromUpdate	= bHoldFromUpdate or false;
	
	itemtype.NWVarsByName[strName] = NewNWVar;
end

--[[
* SHARED

Creates a networked command for a type of item.
The networked command should be created serverside and clientside, in the same order.
itemtype should usually be ITEM (assuming you're doing this in the itemtype's file)
strName is the name you want to give the network command.
	This will not be sent (to cut down on networking lag), so you can make this as long or short as you want.
	Instead, the name is used to identify this command and associate it with an ID passed through networking.
fnHook is called if there's an incoming NWCommand with this name.
	fnHook should be nil if this command is SENT from this side.
	fnHook should NOT be nil if this command is RECEIVED on this side.
	If you send a NWCommand serverside, then fnHook will be called clientside.
	If you send a NWCommand clientside, then fnHook will be called serverside.
tDatatypes is a table, which contains the types of data that will be sent with the command.
	This can be nil if there is no data sent/received with this command.
	If tDatatypes was { "bool", "short" } that means it's expecting the first piece of data to be a bool, and the second to be a short whenever you send (and receive) the command.
	valid types are: int,integer,long,char,short,float,bool,boolean,str,string,ent,entity,pl,ply,player,vec,vector,ang,angle,item,inv,inventory,uchar,ushort, and ulong
	
Here's an example of how to create a network command that is sent from the server and received on the client.
	NWCommands are created on both the server and client.
	
	ON SERVER:
		IF.Items:CreateNWCommand( ITEM, "MyNWCommand", nil, { "bool", "short" } );
	
	ON CLIENT:
		function ITEM:myHookName( bool, short )
			Msg( "MyNWCommand received from server!\n"	);
			Msg( "Bool is: "..tostring(bool).."!\n"		);
			Msg( "Short is: "..tostring(short).."\n"	);
		end
		
		--Notice that our function above is ITEM:myHookName, but our hook is ITEM.myHookName
		IF.Items:CreateNWCommand( ITEM, "MyNWCommand", ITEM.myHookName, { "bool", "short" } );

I'll probably explain this in a tutorial or something. Must be overwhelming.
]]--
function MODULE:CreateNWCommand( itemtype, strName, fnHook, tDatatypes )
	if strName == nil	then ErrorNoHalt( "Itemforge Items: Couldn't create networked command. strName wasn't provided.\n" ); return false end
	if itemtype == nil	then ErrorNoHalt( "Itemforge Items: Couldn't create networked command \""..strName.."\". itemtype wasn't provided (if this is being called inside of an item script, itemtype should be ITEM\n" ); return false end
	
	if itemtype.NWCommandsByName == nil then itemtype.NWCommandsByName  = {} end
	if itemtype.NWCommandsByID	 == nil then itemtype.NWCommandsByID	= {} end
	
	if itemtype.NWCommandsByName[strName] != nil then ErrorNoHalt( "Itemforge Items: Couldn't create networked command \""..strName.."\" - there is already a networked command with this name in this itemtype!\n" ); return false end
	
	local newNWCommand		= {};
	newNWCommand.Name		= strName;
	newNWCommand.Hook		= fnHook;
	newNWCommand.Datatypes	= {};
	
	if type(tDatatypes) == "table" then
		for i = 1, table.maxn( tDatatypes ) do
			local t = string.lower( tDatatypes[i] );
			local id = NWCDatatypeStrToID[t];
			if id == nil then
				ErrorNoHalt( "Itemforge Items: Bad datatype for NWCommand \""..strName.."\". \""..string.lower(t).."\" is invalid; valid types are:\n" );
				
				local l = #NWCDatatypeStrToID;
				for i = 1, l - 1 do
					ErrorNoHalt( NWCDatatypeStrToID[i]..", " );
				end
				ErrorNoHalt( " and "..NWCDatatypeStrToID[l]..".\n" );
				
				id = 0;
			end
			table.insert( newNWCommand.Datatypes, id );
		end
	elseif tDatatypes != nil then
		ErrorNoHalt( "Itemforge Items: CreateNWCommand's (\""..strName.."\") fourth argument, tDatatypes, takes a table, not a "..type(tDatatypes).."!\n" );
		return false;
	end
	
	newNWCommand.ID = table.insert( itemtype.NWCommandsByID, newNWCommand );
	itemtype.NWCommandsByName[strName] = newNWCommand;

	return true;
end

--[[
* SHARED

Registers a scripted weapon for the given itemtype.

tItem should be the item-type table.
]]--
function MODULE:RegisterSWEP( tItemClass )
	local strClassName = tItemClass.ClassName;
	if string.len( strClassName ) > 30 then ErrorNoHalt( "Itemforge Items: Warning! \""..strClassName.."\"'s name is too long to register a SWEP for. Expect errors when trying to hold this item!\n" ) end
	
	--Make a copy of the base weapon
	local tCopy = {
		Base		=	self.BaseWeaponClassName,
		ViewModel	=	IF.Base:InheritedLookup( tItemClass, "ViewModel" ),
	};
	
	local strWeaponClass = "if_"..strClassName;
	if CLIENT then language.Add( strWeaponClass, "Item (held)" ); end
	weapons.Register( tCopy, strWeaponClass, true );
end

--[[
* SHARED

Searches the Items[] table for an empty slot.

This function will keep searching until:
	It finds an open slot.
	It has gone through the entire table once.

iFrom is an optional number describing where to start searching in the table.
	If this number is not given, is over the max number of items, or is under 1, it will be set to 1.

The index of an empty slot is returned if one is found,
or nil is returned if one couldn't be found.

TODO I'm not satisfied with the way this function works; consider reworking it sometime
]]--
function MODULE:FindEmptySlot( iFrom )
	--Wrap around to 1 if iFrom wasn't a number, was under zero, or was over the item limit
	if !IF.Util:IsNumber( iFrom ) || !IF.Util:IsInRange( iFrom, 1, MaxItems ) then iFrom = 1; end
	
	local count = 0;
	while count < MaxItems do
		if ItemRefs[iFrom] == nil then return iFrom end
		count = count + 1;
		iFrom = iFrom + 1;
		if iFrom > MaxItems then iFrom = 1 end
	end
	return nil;
end

--[[
* SHARED

Starts Itemforge Item's tick
]]--
function MODULE:StartTick()
	hook.Add( "Tick", "itemforge_items_tick", function(...) self:Tick(...) end );
end

--[[
* SHARED

This runs the Tick() function on every active item (Serverside and Clientside)
]]--
function MODULE:Tick()
	--TODO: Use list of changed items
	for k,v in pairs( ItemRefs ) do
		v:Tick();
	end
	
	if SERVER && self.FileSendInProgress then
		self:FileSendTick();
	end
end

--[[
* SHARED

Stops Itemforge Item's tick
]]--
function MODULE:StopTick()
	hook.Remove( "Tick", "itemforge_items_tick" );
end

--[[
* SHARED
* Internal

There should be no reason for a scripter to call this directly.
Adds the given item to the table of thinking items.
]]--
function MODULE:AddThinkingItem( item )
	ThinkingItems[item] = true;
end

--[[
* SHARED
* Internal

There should be no reason for a scripter to call this directly.
Removes the given item from the table of thinking items.
]]--
function MODULE:RemoveThinkingItem( item )
	ThinkingItems[item] = nil;
end

--[[
* SHARED
* Event

This runs the Think() function on every thinking item (Serverside and Clientside)
]]--
function MODULE:Think()
	local ct = CurTime();
	for k, v in pairs( ThinkingItems ) do
		if k:GetNextThink() <= ct then	k:Event( "OnThink" ); end
	end
end

--[[
* SHARED

Calls when a player tries to punt an entity with the gravity gun.

If the entity that was punted was actually an item, then we forward the event to the item,
letting it decide if the punt is allowed and how it reacts to being punted.
Otherwise, we don't interfere.

pl is the player who was weilding the gravity gun.
eEntity is the entity that was punted.

If this returns false, the punt is prevented.
If this returns true, the punt is allowed.
]]--
function MODULE:GravGunPunt( pl, eEntity )
	
	--If this isn't an item in the world we don't rule on whether a punt is allowed or not
	local item = self:GetEntItem( eEntity );
	if !item then return nil end

	--Was a punt explicitly forbidden?
	if item:Event( "CanGravGunPunt", true, pl, eEntity ) == false then return false end

	--If not, we allow the punt, and the item can respond to it here
	item:Event( "OnGravGunPunt", nil, pl, eEntity );

	return nil;

end

--[[
* SHARED

Calls when a player tries to grab an entity with the physgun.

If the entity that was grabbed was actually an item, then we forward the event to the item,
letting it decide if the pickup is allowed and how it reacts to being picked up.
Otherwise, we don't interfere.

pl is the player who was weilding the physgun.
eEntity is the entity that was picked up.

If the hook returns true, the pickup is allowed.
If it returns false, the pickup isn't allowed.
]]--
function MODULE:PhysgunPickup( pl, eEntity )

	--If this isn't an item in the world we don't rule on whether a pickup is allowed or not
	local item = self:GetEntItem( eEntity );
	if !item then return nil end

	--Was a pickup explicitly forbidden?
	if item:Event( "CanPhysgunPickup", true, pl, eEntity ) == false then return false end

	--If not, we allow the pickup, and the item can respond to it here
	item:Event( "OnPhysgunPickup", nil, pl, eEntity );

	return nil;
end

--[[
* SHARED

Calls when a player releases an entity that was being held with the physgun.

If the entity was actually an item, then we forward the event to the item,
letting it decide how it reacts to being dropped.
Otherwise, we don't interfere.

pl is the player who was weilding the physgun.
eEntity is the entity that was dropped up.
]]--
function MODULE:PhysgunDrop( pl, eEntity )

	--If this isn't an item in the world we don't care
	local item = self:GetEntItem( eEntity );
	if !item then return nil end

	--The item can respond to a drop here
	item:Event( "OnPhysgunDrop", nil, pl, eEntity );

end

--[[
* SHARED

Creates an item of this type.
This should only be called on the server by a scripter.
Clientside, this is called to sync creation.

Once the item has been created, it will be floating around in the void (not in the world or in an inventory).
You'll have to place it in the world, in a player's hands, an inventory, or simply leave it in the void.
I personally suggest doing one of the first three, so you don't lose track of items in the void.

If you want a more convenient solution, try:
	IF.Items:CreateInWorld(			strType, pos,		ang	);
	IF.Items:CreateHeld(			strType, player			);
	IF.Items:CreateInInventory(		strType, inventory		);
	IF.Items:CreateInInv(			strType, inventory		);
	IF.Items:CreateSameLocation(	strType, otherItem		);

strType is the type of item you want to create (e.g. "weapon_smg", "item_hammer", etc).
id is only required when creating items clientside.
	This is the item id to give the created item.
fullUpd is only used on the client.
	This will be true only if creating the item is part of a full update.
plOwner is an optional player given serverside.
	If this player is given, only this player will be told to create the item (usually the only reason this is given is because the item is being created in a private inventory)
bPredict is an optional true/false that defaults to false on the server and true on the client. If bPredict is:
	false, then if successful we'll register and return a new item. nil will be returned if unsuccessful for any reason.
	true, then if we determine the item can be created, a temporary item that can be used for further prediction tests will be returned. nil will be returned otherwise.
]]--
function MODULE:Create( strType, id, fullUpd, plOwner, bPredict )
	--If we're given an owner we need to validate it
	if !IF.Util:IsPlayer( plOwner ) then plOwner = nil end

	if strType == nil then ErrorNoHalt( "Itemforge Items: Could not create item. No type was provided.\n" ); return nil end
	strType = string.lower( strType );
	
	if !IF.Base:ClassExists( strType ) then
		ErrorNoHalt( "Itemforge Items: Could not create item. \""..strType.."\" is not a registered class." );
		return nil;
	elseif ItemTypes[strType] == nil then
		ErrorNoHalt( "Itemforge Items: Could not create item. \""..strType.."\" is a registered class, but is not an item-type. Naming conflicts can cause this error." );
		return nil;
	end
	
	if bPredict == nil then bPredict = CLIENT end
	
	--[[
	We need to find an ID for the soon-to-be created item.
	We'll either use an ID that is not in use at the moment, which is usually influenced by the number of items created so far
	or a requested ID likely sent from the server
	]]--
	local n;
	if SERVER || ( bPredict && !id ) then
		n = NextItem;

		if ItemRefs[n] != nil then
			n = self:FindEmptySlot( n + 1 );
			
			if n == nil then
				if !bPredict then ErrorNoHalt( "Itemforge Items: Couldn't create \""..strType.."\" - no free slots (all "..MaxItems.." slots occupied)!\n" ); end
				return nil;
			end
		end
		
		if !bPredict then
			NextItem = n + 1;
			if NextItem > MaxItems then NextItem = 1 end
		end
	else
		if id == nil then ErrorNoHalt( "Itemforge Items: Could not create \""..strType.."\" clientside, the ID of the item to be created wasn't given!\n" ); return nil end
		n = id;
	end
	
	--[[
	When an item is updated, Create is called before updating it.
	That way if the item doesn't exist it's created in time for the update.
	We only need to keep track of the number of items updated when all inventories are being updated.
	]]--
	if CLIENT && fullUpd == true && self.FullUpInProgress == true && !bPredict then
		self.FullUpCount = self.FullUpCount + 1;
		self.FullUpItemsUpdated[n] = true;
	end
	
	--Does the item exist already? No need to recreate it.
	--TODO possible bug here; what if a dead item clientside blocks new items with the same ID from being created?
	if ItemRefs[n] then
		--We only need to bitch about this on the server. Full updates of an item clientside will tell the item to be created regardless of whether it exists or not. If it exists clientside we'll just ignore it.
		if SERVER && !bPredict then
			ErrorNoHalt( "Itemforge Items: Could not create \""..strType.."\", with id "..n..". An item with this ID already exists!\n" );
		end
		
		return nil;
	end
	
	if bPredict then n = 0 end
	
	local newItem = IF.Base:CreateObject( strType );
	if newItem == nil then return nil end
	
	newItem.ID = n;
	
	if !bPredict then
		ItemRefs[n]				= newItem;
		ItemsByType[strType][n] = newItem;		--Register in "items by type" array
		
		--We'll tell the clients to create and initialize the item as well
		if SERVER then self:CreateClientside( newItem, plOwner ); end
		
		--Items will be initialized right after being created
		--TODO predicted items need to initialize too but not do any networking shit
		--TODO addendum: This should be solved in the coming networking update
		newItem:Initialize( plOwner );
	end
	
	--Return a reference to the newly created item
	return newItem;
end

--[[
* SHARED

Creates an item and then places it in the given inventory
If the creation succeeds, the item created is returned. Otherwise, nil is returned.
]]--
function MODULE:CreateInInventory( strType, inv, bPredict )
	if strType == nil			then ErrorNoHalt( "Itemforge Items: Tried to create item in inventory, but type of item to create was not given!\n" ); return nil end
	if !inv or !inv:IsValid()	then ErrorNoHalt( "Itemforge Items: Tried to create item in inventory, but given inventory was not valid!\n" ); return nil end
	
	if bPredict == nil then bPredict = CLIENT end
	
	--Get the owner of the inventory. The item will be networked to this player only.
	local owner = inv:GetOwner();
	
	local item = self:Create( strType, nil, false, owner, bPredict );
	if !item then return nil end
	
	--TODO PREDICT
	if !bPredict && !item:ToInventory( inv, nil, owner ) then
		item:Remove( true );
		return nil;
	end
	
	return item;
end
MODULE.CreateInInv = MODULE.CreateInInventory;

--[[
* SHARED

Creates an item and then places it in the world at the given position and angles.

strType is the type of item you want to create.
vWhere is an optional position you want to create the item at in the world.
	This defaults to Vector( 0, 0, 0 ).
aAngles is an optional Angle() you want to rotate the item to.
	This defaults to Angle( 0, 0, 0 ).
bPredict is an optional boolean that, instead of actually creating the item, lets you predict whether or not this will succeed.
	It defaults to false on the server, and true on the client.

If the creation succeeds, the item created is returned. Otherwise, nil is returned.
]]--
function MODULE:CreateInWorld( strType, vWhere, aAngles, bPredict )
	if strType == nil then ErrorNoHalt( "Itemforge Items: Tried to create item in world but type of item to create was not given!\n" ); return nil end
	
	vWhere = vWhere or Vector( 0, 0, 0 );
	if bPredict == nil then bPredict = CLIENT end
	
	--Create the item.
	local item = self:Create( strType, nil, nil, nil, bPredict );
	if !item then return nil end
	
	--TODO PREDICT
	if !bPredict && !item:ToWorld( vWhere, aAngles ) then
		item:Remove( true );
		return nil;
	end
	
	return item;
end

--[[
* SHARED

Creates an item and then places it in the hands of a player as a weapon.

strType is the type of item you want to create.
ePlayer is the player you want to give the item.
bPredict is an optional boolean that, instead of actually creating the item, lets you predict whether or not this will succeed.
	It defaults to false on the server, and true on the client.

If the creation succeeds, the item created is returned. Otherwise, nil is returned.
]]--
function MODULE:CreateHeld( strType, ePlayer, bPredict )
	if strType == nil		then ErrorNoHalt( "Itemforge Items: Tried to create item held by player, but type of item to create wasn't given.\n"); return nil end
	if !IsValid(ePlayer)	then ErrorNoHalt( "Itemforge Items: Tried to create item held by player, but the player wasn't given/was invalid.\n"); return nil end
	if !ePlayer:IsPlayer()	then ErrorNoHalt( "Itemforge Items: Tried to create item held by player, but the player given wasn't a player."); return nil end
	if bPredict==nil		then bPredict=CLIENT end
	
	local item = self:Create( strType, nil, nil, nil, bPredict );
	if !item then return nil end
	
	--TODO PREDICT
	if !bPredict && !item:Hold( ePlayer ) then
		if item:IsValid() then item:Remove(); end
		return nil;
	end
	
	return item;
end

--[[
* SHARED

Creates an item and places it in the same location as an existing item.
This function is probably best for things that are breaking apart (such as a pickaxe breaking into a pickaxe head and a stick)
extItem is an existing item. The new item will be created in the same location as it.

The new item will be created in...
	the same container that this item is in, if 'extItem' is in a container.
	nearby this item, if 'extItem' in the world.
	a player's weapon menu, if 'extItem' is held by that player.
	
The newly created item will be returned if all goes well, or nil will be returned in case of errors.
TODO this sucks, fix it
]]--
function MODULE:CreateSameLocation( strType, extItem, bPredict )
	if strType == nil					then ErrorNoHalt( "Itemforge Items: Tried to create item in same location as other item, but type of item to create was not given!\n" ); return nil end
	if !extItem or !extItem:IsValid()	then ErrorNoHalt( "Itemforge Items: Tried to create \""..strType.."\" in same location as other item, but other item wasn't given!\n" ); return nil end
	
	if bPredict == nil then bPredict = CLIENT end
	
	local item = self:Create( strType, nil, nil, nil, bPredict );
	if !item then return nil end
	
	--TODO predict
	if !bPredict && !item:ToSameLocationAs( extItem, nil, true ) then
		--DEBUG
		Msg( "Couldn't create in same location, removing.\n" );
		item:Remove();
		return nil;
	end
	
	return item;
end

--[[
* SHARED

This will remove an existing item.
item:Remove() calls this.

When this function is run, the OnRemove() hook on the item is triggered.

item should be an existing item.

true is returned if the item was successfully removed.
false is returned if an invalid item was given, or the item is already in the process of being removed.
]]--
function MODULE:Remove( item )
	if !item || !item:IsValid()		then ErrorNoHalt( "Itemforge Items: Could not remove given item - doesn't exist!\n" ); return false end
	if item.BeingRemoved			then return false;
	else								 item.BeingRemoved = true;
	end
	
	item:Event( "OnRemove" );
	
	
	item:StopThink();						--Stop thinking if we're thinking
	item:StopAllLoopingSounds();			--Stop all looping sounds
	item:RemoveAllTimers();					--Stop all active timers
	
	if CLIENT then
		item:UnregisterAllObservers();		--Unregister any observers
		item:KillMenu();					--Hide the right click menu if it is open
	end
	
	--Unlink any inventories that are connected to this item (an inventory "belonging" to this item - ex: a backpack's inventory or a crate's inventory)
	if item.Inventories then
		for k, v in pairs( item.Inventories ) do
			v.Inv:SeverItem( v.ConnectionSlot, SERVER );
		end
	end
	
	--Remove entity, swep, or remove from inventory.
	if SERVER then		item:ToVoid( true, nil, true );
	else				item:ToVoid( true, nil, nil, false );
	end
	
	local type = item:GetType();
	local id   = item:GetID();
	
	--[[
	Tell ALL clients to remove too
	Even if an item is private, it can change owners.
	It might have been public and then went private.
	To make sure the item is absolutely removed on all clients, we tell all clients to remove it.
	]]--
	if SERVER then		self:RemoveClientside( id ); end
	
	--Invalidate item reference (disconnect it from the actual item), remove reference from collection, remove from ItemsByType collection
	ItemRefs[id]:Invalidate();
	ItemRefs[id] = nil;
	ItemsByType[type][id] = nil;
	
	return true;
end

--[[
* SHARED

Returns true if the given entity is actually an item in the world
(an "itemforge_item" entity).
If the entity isn't an item, or is just invalid then false is returned.
]]--
function MODULE:IsEntItem( eEnt )
	if !eEnt || !eEnt:IsValid() then return false end
	return eEnt:GetClass() == self.BaseEntityClassName;
end

--[[
* SHARED

Returns true if the given weapon is actually an item being held by a player
(in other words, if it's based off of the base itemforge weapon).

If the weapon isn't an item, or is just invalid then false is returned.
]]--
function MODULE:IsWeaponItem( eWep )
	if !eWep || !eWep:IsValid() then return false end
	return eWep.Base == self.BaseWeaponClassName;
end

--[[
* SHARED

If the given entity is actually an item in the world, returns the item.
Returns nil otherwise.
]]--
function MODULE:GetEntItem( eEnt )
	if self:IsEntItem( eEnt ) then return eEnt:GetItem() end
	return nil;
end

--[[
* SHARED

If the given weapon is actually an item being held by a player, returns the item.
Returns nil otherwise.
]]--
function MODULE:GetWeaponItem( eWep )
	if self:IsWeaponItem( eWep ) then return eWep:GetItem() end
	return nil;
end

--[[
* SHARED

This returns a reference to an item with the given ID.
For all effective purposes this is the same thing as returning the actual item,
except it doesn't hinder garbage collection,
and helps by warning the scripter of careless mistakes (still referencing an item after it's been deleted).

id should be the ID of the item to get.

This returns an item reference (a table) if successful,
or nil if there is no item with that ID.
]]--
function MODULE:Get( id )
	return ItemRefs[id];
end

--[[
* SHARED

Returns a table of all items currently available to Itemforge.
Please note:
	This function copies the entire table of item references every time it is run.
	Do not run it all the time! That lags!
	If this function is run on the client, the client may not have every single item the server has,
	because of private inventories and lag. However, serverside this function will always return
	every single item, regardless of who owns it.

TODO possibly a more efficient alternative
]]--
function MODULE:GetAll()
	local t = {};
	
	for k, v in pairs( ItemRefs ) do
		t[k] = v;
	end
	
	return t;
end

--[[
* SHARED

Returns a table of all items with a given type currently available to Itemforge.
Please note:
	This function copies the entire table of items by this type every time it is run.
	Do not run it all the time! That lags!

TODO possibly a more efficient alternative
]]--
function MODULE:GetByType( strType )
	local t = {};
	
	for k, v in pairs( ItemsByType[strType] ) do
		t[k] = v;
	end
	
	return t;
end

--[[
* SHARED

Internal Itemforge function. Adds the item to the list of held items.
]]--
function MODULE:AddWorldItem( item )
	WorldItems[item:GetID()] = item;
end

--[[
* SHARED

Internal Itemforge function. Removes the item from the list of world items.
]]--
function MODULE:RemoveWorldItem( item )
	WorldItems[item:GetID()] = nil;
end

--[[
* SHARED

Internal Itemforge function. Adds the item to the list of held items.
]]--
function MODULE:AddHeldItem( item )
	HeldItems[item:GetID()] = item;
end

--[[
* SHARED

Internal Itemforge function. Removes the item from the list of held items.
]]--
function MODULE:RemoveHeldItem( item )
	HeldItems[item:GetID()] = nil;
end

--[[
* SHARED

Returns a table of all items that are known to be in the world.
Please note:
	This function copies the entire table of items in the world every time it is run.
	Do not run it all the time! That lags!

TODO possibly a more efficient alternative
]]--
function MODULE:GetWorld()
	local t = {};
	
	for k,v in pairs( WorldItems ) do
		t[k] = v;
	end
	
	return t;
end

--[[
* SHARED

Returns a table of all items that are known to be held by players.
Please note:
	This function copies the entire table of items held by players every time it is run.
	Do not run it all the time! That lags!

TODO possibly a more efficient alternative
]]--
function MODULE:GetHeld()
	local t = {};
	
	for k,v in pairs( HeldItems ) do
		t[k] = v;
	end
	
	return t;
end

--[[
* SHARED

Returns the name of the base item type (the class that all other item types are based off of).
]]--
function MODULE:GetBaseItemType()
	return BaseType;
end

--[[
* SHARED

Returns a list of all item types.
NOTE:
	Don't modify the item-types.
	If you do, every currently spawned item with that item-type may change.
]]--
function MODULE:GetTypes()
	local t = {};
	
	for k, v in pairs( ItemTypes ) do
		t[k] = v;
	end
	
	return t;
end

--[[
* SHARED

Returns the item type by name strName.

NOTE: If your item is based off of another item, you can access it's type by doing self["base_class"] (where self is your item,
	  and base_class is whatever it's based off of, like base_lock, base_item, whatever).
	  Don't modify the item-types. If you do, every currently spawned item with that item-type may change.

strName should be the name of the item type to get.
	
If the item type exists, returns it.
Otherwise, returns nil.
]]--
function MODULE:GetType( strName )
	if !IF.Util:IsString( strName ) then ErrorNoHalt( "Itemforge Items: Couldn't grab item type - name of type wasn't given!\n" ); return false end

	return ItemTypes[string.lower( strName )];
end

--TEMPORARY/DEBUG
function MODULE:DumpItems()
	dumpTable( Items );
end

--TEMPORARY/DEBUG
function MODULE:DumpItemRefs()
	dumpTable( ItemRefs );
end

--TEMPORARY/DEBUG
function MODULE:DumpItem( id )
	dumpTable( ItemRefs[id]:GetTable() );
end




--Server only
if SERVER then

--[[
* SERVER

Tells the client to reload an item type.
]]--
function MODULE:ReloadItemType( strType, pl )
	--Validate player
	if pl != nil then
		if !pl:IsValid()		then ErrorNoHalt( "Itemforge Items: Couldn't reload itemtype - The player to reload \""..strType.."\" to isn't valid!\n"); return false;
		elseif !pl:IsPlayer()	then ErrorNoHalt( "Itemforge Items: Couldn't reload itemtype - The player to send \""..strType.."\" to isn't a player!\n"); return false;
		end
	else
		local allSuccess = true;
		for k,v in pairs( player.GetAll() ) do
			if !self:ReloadItemType( strType, v ) then allSuccess = false end
		end
		return allSuccess;
	end
	
	self:IFIStart( pl, IFI_MSG_RELOAD, 0 );
	self:IFIString( strType );
	self:IFIEnd();
end

--[[
* SHARED
* Internal

Creates a task queue and a Think to process it
]]--
function MODULE:StartTaskQueue()
	self.TaskQueue = IF.Base:CreateObject( "TaskQueue" );
	hook.Add( "Think", "itemforge_taskqueue_think", function(...) self:TaskQueueThink(...) end );
end

--[[
* SHARED
* Internal

Called every frame to process the tasks while there are tasks
]]--
function MODULE:TaskQueueThink()
	self.TaskQueue:Process();
	if self.TaskQueue:IsEmpty() then self:StopTaskQueue(); end
end

--[[
* SHARED
* Internal

Removes the taskqueue think and deletes the task queue
]]--
function MODULE:StopTaskQueue()
	self.TaskQueue = nil;
	hook.Remove( "Think", "itemforge_taskqueue_think" );
end

--[[
* SHARED
* Internal

Calls when a player tries to pick up an entity with the gravity gun.

If the entity is actually an item, then we forward the event to the item,
letting it decide if the pickup is allowed.
Otherwise, we don't interfere.

pl is the player who was weilding the gravity gun.
eEntity is the entity that was picked up.

If this returns false, the pickup is prevented.
If this returns nil, whether or not the pickup is allowed will be decided by some other hook / the gamemode.
]]--
function MODULE:GravGunPickupAllowed( pl, eEntity )
	--If this isn't an item in the world we don't rule on whether a pickup is allowed or not
	local item = self:GetEntItem( eEntity );
	if !item then return nil end

	--Was a pickup explicitly forbidden?
	if item:Event( "CanGravGunPickup", true, pl, eEntity ) == false then return false end

	return nil;
end

--[[
* SHARED
* Internal

Calls after a player has picked up an entity with the gravity gun.

If the entity is actually an item, then we forward the event to the item letting it decide how to react.
Otherwise, we don't interfere.

pl is the player who was weilding the gravity gun.
eEntity is the entity that was picked up.
]]--
function MODULE:GravGunOnPickedUp( pl, eEntity )
	--If this isn't an item in the world we don't care
	local item = self:GetEntItem( eEntity );
	if !item then return nil end

	--The item can react to the pickup here
	item:Event( "OnGravGunPickup", nil, pl, eEntity );
end

--[[
* SHARED
* Internal

Calls after a player has dropped or launched an entity being held with the gravity gun.

If the entity is actually an item, then we forward the event to the item letting it decide how to react.
Otherwise, we don't interfere.

pl is the player who was weilding the gravity gun.
eEntity is the entity that was dropped / launched.
]]--
function MODULE:GravGunOnDropped( pl, eEntity )
	--If this isn't an item in the world we don't care
	local item = self:GetEntItem( eEntity );
	if !item then return nil end

	--The item can react to the pickup here
	item:Event( "OnGravGunDrop", nil, pl, eEntity );
end

--[[
* SHARED
* Internal

Calls when a player tries to freeze an entity with the physgun.

If the entity that was grabbed was actually an item, then we forward the event to the item,
letting it decide if the freeze is allowed and how it reacts to being frozen.
Otherwise, we don't interfere.

eWeapon is the physgun weapon itself.
phys is the specific physics object being frozen.
eEntity is the entity that the player is trying to freeze.
pl is the player who was weilding the physgun.

If the hook returns true, the pickup is allowed.
If it returns false, the pickup isn't allowed.
]]--
function MODULE:PhysgunFreeze( eWeapon, phys, eEntity, pl )
	
	--If this isn't an item in the world we don't rule on whether a freeze is allowed or not
	local item = self:GetEntItem( eEntity );
	if !item then return nil end

	--Was a freeze explicitly forbidden?
	if item:Event( "CanPhysgunFreeze", true, pl, eEntity, phys ) == false then return false end

	--If not, we allow the freeze, and the item can respond to it here
	item:Event( "OnPhysgunFreeze", nil, pl, eEntity, phys );

	return nil;

end

--[[
* SHARED
* Internal

Calls when a player tries to unfreeze an entity with the physgun in any way (grabbing it, pressing reload, double-tapping reload, etc).

If the player is trying to unfreeze an entity that was actually an item, then we forward the event to the item,
letting it decide if the unfreeze is allowed and how it reacts to being unfrozen.
Otherwise, we don't interfere.

pl is the player who was weilding the physgun.
eEntity is the entity that the player is trying to unfreeze.
phys is the specific physics object being unfrozen.

If the hook returns true, the pickup is allowed.
If it returns false, the pickup isn't allowed.
]]--
function MODULE:CanPlayerUnfreeze( pl, eEntity, phys )
	
	--If this isn't an item in the world we don't rule on whether a unfreeze is allowed or not
	local item = self:GetEntItem( eEntity );
	if !item then return nil end

	--Was an unfreeze explicitly forbidden?
	if item:Event( "CanPhysgunUnfreeze", true, pl, eEntity, phys ) == false then return false end

	--If not, we allow the freeze, and the item can respond to it here
	item:Event( "OnPhysgunUnfreeze", nil, pl, eEntity, phys );

	return nil;
end

--[[
* SERVER
* Internal

Asks the client to create an item clientside.
When the request to create the item arrives clientside, if the item already exists it is disregarded.

item is an existing, valid item that needs to be created clientside.
pl is an optional argument that defaults to nil.
	If this is nil, every player will receive an instruction to create the item.
	If this is a player, only this player will be told to create the item.
		In the case of a public item, this can be used to send the item to a player who needs it (like a connecting player).
		If the item is private, pl can only be the owner. It will fail otherwise.
bFullUpd is an optional true/false that defaults to false.
	This should only be true if this item is being created as part of a full update.

true is returned if there are no errors.
false is returned otherwise.
]]--
function MODULE:CreateClientside( item, pl, bFullUpd )
	if !item or !item:IsValid() then ErrorNoHalt( "Itemforge Items: Couldn't CreateClientside - Item given isn't valid!\n" ); return false end
	
	--Validate player
	if pl != nil then
		if !IF.Util:IsPlayer( pl ) then ErrorNoHalt( "Itemforge Items: Couldn't CreateClientside - The player to send "..tostring( item ).." to isn't a valid player!\n" ); return false; end
	else
		local bAllSuccess = true;
		for k, v in pairs( player.GetAll() ) do
			if !self:CreateClientside( item, v, bFullUpd ) then bAllSuccess = false end
		end
		return bAllSuccess;
	end
	
	self:IFIStart( pl, IFI_MSG_CREATE, item:GetID() );
	self:IFIString( item:GetType() );
	self:IFIBool( bFullUpd == true );
	self:IFIEnd();
	
	return true;
end

--[[
* SERVER
* Internal

Asks the client to remove an item clientside.

itemid is the ID of an item that needs to be removed clientside.
	We use itemid here instead of item because the item has probably already been removed serverside,
	and we would need to run :GetID() on a non-existent item in that case
pl is an optional player that defaults to nil.
	If pl isn't nil, this function will only tell that player to remove the item.
	Otherwise, all players are instructed to remove this item clientside.
]]--
function MODULE:RemoveClientside( itemid, pl )
	if itemid == nil then ErrorNoHalt( "Itemforge Items: Couldn't RemoveClientside - No itemid was given!\n" ); return false end
	
	--Validate player
	if pl != nil then
		if !IF.Util:IsPlayer( pl ) then	ErrorNoHalt( "Itemforge Items: Couldn't RemoveClientside - The player to remove the item from isn't a valid player!\n" ); return false; end
	else
		local allSuccess = true;
		for k,v in pairs( player.GetAll() ) do
			if !self:RemoveClientside( itemid, v ) then allSuccess = false end
		end
		return allSuccess;
	end
	
	self:IFIStart( pl, IFI_MSG_REMOVE, itemid );
	self:IFIEnd();
	
	return true;
end

--[[
* SERVER
* Internal

Remove an item clientside on all players except for the given player.

itemid is the ID of the item to remove.
pl is the player who the item will not be removed on.
TODO rename to RemoveClientsideToAllBut
]]--
function MODULE:RemoveClientsideOnAllBut( itemid, pl )
	if itemid == nil then ErrorNoHalt( "Itemforge Items: Couldn't RemoveClientsideOnAllBut - No itemid was given!\n" ); return false end
	
	--Validate player
	if pl == nil then			ErrorNoHalt( "Itemforge Items: Couldn't RemoveClientsideOnAllBut - No player was given!\n" ); return false
	elseif !pl:IsValid() then	ErrorNoHalt( "Itemforge Items: Couldn't RemoveClientsideOnAllBut - The player to remove item with ID "..itemid.." from isn't valid!\n" ); return false;
	elseif !pl:IsPlayer() then	ErrorNoHalt( "Itemforge Items: Couldn't RemoveClientsideOnAllBut - The player to remove item with ID "..itemid.." from isn't a player!\n" ); return false;
	end
	
	for k,v in pairs( player.GetAll() ) do
		if v != pl then self:RemoveClientside( itemid, v ) end
	end
	
	return true;
end

--[[
* SERVER
* Internal

Sends a full update on an item, as requested by a client usually.
If the item doesn't exist serverside then instead of a full update, the client will be told to remove that item.
Full updates are bandwidth consuming and should not be used unless necessary.

itemid is the ID of the item to send an update of.
	We use the ID because, as previously stated, it's possible the item doesn't exist on the server.
pl is the player to send the update of the item to.

This returns true if successful,
or false if not.
]]--
function MODULE:SendFullUpdate( itemid, pl )
	if !itemid then ErrorNoHalt( "Itemforge Items: Couldn't SendFullUpdate... the item ID wasn't given.\n" ); return false end
	
	--Validate player
	if pl != nil then
		if !pl:IsValid() then		ErrorNoHalt( "Itemforge Items: Couldn't SendFullUpdate "..itemid.." - The player given isn't valid!\n"); return false;
		elseif !pl:IsPlayer() then	ErrorNoHalt( "Itemforge Items: Couldn't SendFullUpdate "..itemid.." - The player given isn't a player!\n"); return false; end
	else
		local allSuccess = true;
		for k,v in pairs( player.GetAll() ) do
			if !self:SendFullUpdate( itemid, v ) then allSuccess = false end
		end
		return allSuccess;
	end
	
	--If the item doesn't exist, we tell the client who requested the update to get rid of it.
	local item = self:Get( itemid );
	if !item then return self:RemoveClientside( itemid, pl ); end
	
	return ( self:CreateClientside( item, pl ) && item:SendFullUpdate( pl ) );
end

--[[
* SERVER
* Internal

Sends a full update of ONE item clientside on all players except for the given player.
TODO rename to SendFullUpdateToAllBut instead
]]--
function MODULE:SendFullUpdateOnAllBut( item, pl )
	if !item or !item:IsValid() then ErrorNoHalt( "Itemforge Items: Couldn't SendFullUpdateOnAllBut - Given item was invalid!\n" ); return false end
	
	--Validate player
	if pl == nil			then ErrorNoHalt( "Itemforge Items: Couldn't send full update of "..tostring(item).." - No player was given!\n" ); return false
	elseif !pl:IsValid()	then ErrorNoHalt( "Itemforge Items: Couldn't SendFullUpdateOnAllBut - The player to send "..tostring(item).." isn't valid!\n" ); return false;
	elseif !pl:IsPlayer()	then ErrorNoHalt( "Itemforge Items: Couldn't SendFullUpdateOnAllBut - The player to send "..tostring(item).." isn't a player!\n" ); return false;
	end
	
	local allSuccess = true;
	for k,v in pairs( player.GetAll() ) do
		if v != pl then
			if !self:SendFullUpdate( item:GetID(), v ) then allSuccess = false end
		end
	end
	
	return allSuccess;
end

--[[
* SERVER
* Internal

Creates all items applicable (the items that aren't in private inventories) as part of a full update to a given player clientside.
To do a full update on all items and inventories properly, all items should be created clientside first,
then all inventories, then full updates of all items, and then full updates of all inventories.

pl is the player to create items on clientside.
	This can be nil to send to all players.

true is returned if the items were created on the given player, OR if no items need to be sent to the player (this happens when there are no items, or when there are only private items not owned by that player).
false is returned if the items could not be created on the given player.

If the given player was nil, this returns false if one of the players couldn't have the items sent to him.
]]--
function MODULE:StartFullUpdateAll( pl )
	--Validate player
	if pl != nil then
		if !pl:IsValid()	then ErrorNoHalt( "Itemforge Items: Couldn't StartFullUpdateAll - The player to send items to isn't valid!\n" ); return false end
		if !pl:IsPlayer()	then ErrorNoHalt( "Itemforge Items: Couldn't StartFullUpdateAll - The player to send items to isn't a player!\n" ); return false end
	
	--pl is nil so we'll create the items clientside on each player individually
	else
		local allSuccess = true;
		for k,v in pairs( player.GetAll() ) do
			if !self:StartFullUpdateAll( v ) then allSuccess = false end
		end
		return allSuccess;
	end
	
	--Old method
	--[[
	--We'll buffer the items to send here ahead of time.
	local tItemBuffer = {};
	for k, v in pairs( ItemRefs ) do
		--Make sure to only send items the player can have
		if v:CanNetwork( pl ) then
			table.insert( tItemBuffer, v );
		end
	end
	
	local c = table.getn( tItemBuffer );
	if c > 0 then
		self:IFIStart( pl, IFI_MSG_STARTFULLUPALL, c );
		self:IFIEnd();
	
		local bAllCreated = true;
		for i = 1, c do
			if !self:CreateClientside( tItemBuffer[i], pl, true ) then bAllCreated = false end
		end
		return bAllCreated;
	end
	]]--
	
	
	--[[
	We buffer items for three reasons:
	So we get a list of items that can be sent to a player (determined by NetOwner mostly)
	So we know how many items of each type are being sent (to determine whether or not it's necessary to send a message to create items of that type)
	So we know how many items TOTAL are being sent (to determine if sending a full update is even necessary)
	]]--
	local iTotalCount = 0;
	local tItemBuffer = {};
	for strType, tItems in pairs( ItemsByType ) do
		tItemBuffer[strType] = {};
		for k, v in pairs( tItems ) do
			if v:CanNetwork( pl ) then
				table.insert( tItemBuffer[strType], k );
				iTotalCount = iTotalCount + 1;
			end
		end
	end
	
	if iTotalCount > 0 then
		self:IFIStart( pl, IFI_MSG_STARTFULLUPALL, iTotalCount );
		self:IFIEnd();
		
		--[[
		We can send up to this many items IDs in one usermessage at a time.
		It's important to set this number reasonably;
		If it's too small, the bandwidth saved with this method is negligible.
		If it's too large, the usermessage overflows and causes network problems.
		If I could pin down how much each datatype takes up in the usermessage I could send this more reliably
		]]--
		local iLimit = 70;
		
		for strType, tIDs in pairs( tItemBuffer ) do
			--c is how many items of this type we need to send
			local c = table.getn( tIDs );
			
			if c > 0 then
				--We can send up to "iLimit" items at a time, so instead of sending one huge message we send several small "batches" of messages.
				--Each batch begins at "a".
				local a = 1;
				while a <= c do
					--We're sending "iLimit" items or "remaining" items (by remaining items I mean fewer than "iLimit" items, the "last batch" if you will)
					self:IFIStart( pl, IFI_MSG_CREATETYPE, math.min( iLimit, ( c - a + 1 ) ) );
					self:IFIString( strType );
					
					for i = a, math.min( a + ( iLimit - 1 ), c ) do
						self:IFIShort( tIDs[i] - 32768 );
					end
					self:IFIEnd( pl );
					a = a + iLimit;
				end
			end
		end
	end
	return true;
end

--[[
* SERVER
* Internal

Sends a full update on all items from the server to a player (or players).
If pl is a player:
	Returns true if a full update of each individual item was successfully sent to the given player or if the player didn't need any items sent to him (no items, or no items that could be sent to this player)..
	Returns false otherwise.
If pl is nil:
	It runs this function once for each player and returns true if this function succeeded (full update of all items sent successfully to that player) for every connected player.
	If successful full updates of all items couldn't be sent to all players, false is returned.
]]--
function MODULE:EndFullUpdateAll( pl )
	--Validate player if player given
	if pl != nil then
		if !pl:IsValid()	then ErrorNoHalt( "Itemforge Items: Couldn't EndFullUpdateAll - The player to send full updates of all items to isn't valid!\n" ); return false end
		if !pl:IsPlayer()	then ErrorNoHalt( "Itemforge Items: Couldn't EndFullUpdateAll - The player to send full updates of all items to isn't a player!\n" ); return false end
	
	--pl is nil so we'll send a full update to each player individually and end this instance of the function when the rest complete
	else
		local allSuccess = true;
		for k,v in pairs( player.GetAll() ) do
			if !self:EndFullUpdateAll( v ) then allSuccess = false end
		end
		return allSuccess;
	end
	
	--We'll buffer the items to send here ahead of time.
	local tItemBuffer = {};
	for k, v in pairs( ItemRefs ) do
		--Make sure to only send items the player can have
		if v:CanNetwork( pl ) then
			table.insert( tItemBuffer, v );
		end
	end
	
	local c = table.getn( tItemBuffer );
	if c > 0 then
		local bAllSent = true;
		
		--Send full updates
		for i = 1, c do
			if !tItemBuffer[i]:SendFullUpdate( pl ) then bAllSent = false end
		end
		
		self:IFIStart( pl, IFI_MSG_ENDFULLUPALL, 0 );
		self:IFIEnd();
		
		return bAllSent;
	end
	return true;
end

--[[
* SERVER
* Internal

IFI usermessage functions are below.
These usermessage functions are here so the debugger can override them and peek at messages being sent.
All functions below behave exactly like umsg functions, except with a different syntax.
ex: umsg.Angle(a) becomes IF.Items:IFIAngle(a)

The only one that doesn't is IFI start. It starts an IFI usermessage and sets the type of message and player to send to.

pl is the player to send to (this should probably never be nil, packets tend to get sent out of order)
msg is an IFI constant (such as IFI_MSG_CREATE).
item is an optional item ID. 32768 will be subtracted from this automatically. This defaults to 0.
]]--
function MODULE:IFIStart( pl, msg, itemid ) umsg.Start( "ifi", pl ); umsg.Char( msg ); umsg.Short( ( itemid or 0 ) - 32768 ) end
function MODULE:IFIAngle( v )				umsg.Angle( v )		end
function MODULE:IFIBool( v )				umsg.Bool( v )		end
function MODULE:IFIChar( v )				umsg.Char( v )		end
function MODULE:IFIEntity( v )				umsg.Entity( v )	end
function MODULE:IFIFloat( v )				umsg.Float( v )		end
function MODULE:IFILong( v )				umsg.Long( v )		end
function MODULE:IFIShort( v )				umsg.Short( v )		end
function MODULE:IFIString( v )				umsg.String( v )	end
function MODULE:IFIVector( v )				umsg.Vector( v )	end
function MODULE:IFIEnd()					umsg.End()			end

--[[
* SERVER
* Internal

Handles incoming "ifi" (Itemforge Item) messages from the client
]]--
function MODULE:HandleIFIMessages( pl, command, args )
	if !pl || !pl:IsValid() || !pl:IsPlayer()	then ErrorNoHalt( "Itemforge Items: Couldn't handle incoming message from client - Player given doesn't exist or wasn't player!\n" );			return false end
	if !args[1]									then ErrorNoHalt( "Itemforge Items: Couldn't handle incoming message from client "..tostring( pl ).." - message type wasn't received.\n" );		return false end
	if !args[2]									then ErrorNoHalt( "Itemforge Items: Couldn't handle incoming message from client "..tostring( pl ).." - item ID wasn't received.\n" );			return false end
	
	local msgType = tonumber( args[1] );
	local id = tonumber( args[2] ) + 32768;
	
	if msgType == IFI_MSG_REQFULLUP then
		--Send a full update of the item to the client.
		self:SendFullUpdate( id, pl );
	elseif msgType == IFI_MSG_REQFULLUPALL then
		self:StartFullUpdateAll( pl );
		self:EndFullUpdateAll( pl );
	elseif msgType == IFI_MSG_CL2SVCOMMAND then
		local item = self:Get( id );
		if !item || !item:IsValid() then ErrorNoHalt( "Itemforge Items: Tried to run a networked command (Client to Server) on non-existent item with ID "..id..".\n" );				return false end
		if !args[3]					then ErrorNoHalt( "Itemforge Items: Couldn't run a networked command (Client to Server) on "..tostring( item ).." - Command ID not received.\n" );	return false end
		
		item:ReceiveNWCommand( pl, tonumber( args[3] ) + 128, string.Explode( " ", args[4] ) );
	else
		ErrorNoHalt( "Itemforge Items: Unhandled IFI message \""..msgType.."\"\n" );
		return false;
	end
	
	return true;
end

--We use a proxy here so we can make HandleIFIMessages a method (:) instead of a regular function (.)
concommand.Add( "ifi", function( pl, command, args ) return IF.Items:HandleIFIMessages( pl, command, args ) end );




--Client only
else




--[[
* CLIENT
* Internal

Called when a full update has started.

iCount is the number of items we're expecting from the server
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
		ErrorNoHalt( "Itemforge Items: Full item update only updated "..self.FullUpCount.." out of expected "..self.FullUpTarget.." items!\n" );
	end
	
	--Remove non-updated items
	for k, v in pairs( ItemRefs ) do
		if self.FullUpItemsUpdated[k] != true then
			--DEBUG
			Msg( "Itemforge Items: Removing "..tostring(v).." - only exists clientside\n" );
			
			v:Remove();
		end
	end
	
	self.FullUpInProgress = false;
	self.FullUpTarget = 0;
	self.FullUpCount = 0;
	self.FullUpItemsUpdated = {};
end

--[[
* CLIENT
* Internal

Handles incoming "ifi" (Itemforge Item) messages from the server
]]--
function MODULE:HandleIFIMessages( msg )
	--Message type decides what happens next.
	local msgType = msg:ReadChar();
	local id = msg:ReadShort() + 32768;
	
	if msgType == IFI_MSG_CREATE then
		local type = msg:ReadString();
		local bFullUpRelated = msg:ReadBool();
		
		--Create the item clientside too. Use the ID provided by the server.
		self:Create( type, id, bFullUpRelated, nil, false );
	elseif msgType == IFI_MSG_REMOVE then
		local item = self:Get( id );
		if !item then return false end
		
		--Remove the item clientside since it has been removed serverside.
		self:Remove( item );
	elseif msgType == IFI_MSG_CREATETYPE then
		local type = msg:ReadString();
		for i = 1, id do
			self:Create( type, msg:ReadShort() + 32768, true, nil, false );
		end
	elseif msgType == IFI_MSG_CREATEININV then
		--TODO Macro
		--self:
	elseif msgType == IFI_MSG_MERGE then
		--TODO Macro
		local item = self:Get( id );
		if !item then return false end
		
		local newAmt = msg:ReadLong();
		local otherItem = msg:ReadShort() + 32768;
		
		item:SetAmount( newAmt );
		self:Remove( otherItem );
	elseif msgType == IFI_MSG_PARTIALMERGE then
		--TODO Macro
	elseif msgType == IFI_MSG_SPLIT then
		--TODO Macro
	elseif msgType == IFI_MSG_SV2CLCOMMAND then
		local item = self:Get( id );
		if !item then return false end
		
		item:ReceiveNWCommand( msg );
	elseif msgType >= IFI_MSG_SETANGLE && msgType <= IFI_MSG_SETNIL then
		local item = self:Get( id );
		local VarID = msg:ReadChar() + 128;
		
		if !item then return false end
		
		if item.NWVarsByID[VarID] == nil then ErrorNoHalt( "Itemforge Items: Couldn't find a networked var by ID "..VarID.." on "..tostring(item).."\n" ); return false end
		local strName = item.NWVarsByID[VarID].Name;
		
		if msgType == IFI_MSG_SETANGLE then
			local vVal = msg:ReadAngle();
			
			item:ReceiveNWVar( strName, vVal );
		elseif msgType == IFI_MSG_SETBOOL then
			local vVal = msg:ReadBool();
			
			item:ReceiveNWVar( strName, vVal );
		elseif msgType == IFI_MSG_SETCHAR then
			local vVal = msg:ReadChar();
			
			item:ReceiveNWVar( strName, vVal );
		elseif msgType == IFI_MSG_SETCOLOR then
			local vVal = Color( msg:ReadChar() + 128, msg:ReadChar() + 128, msg:ReadChar() + 128, msg:ReadChar() + 128 );
			
			item:ReceiveNWVar( strName, vVal );
		elseif msgType == IFI_MSG_SETENTITY then
			local vVal = msg:ReadEntity();
			
			item:ReceiveNWVar( strName, vVal );
		elseif msgType == IFI_MSG_SETFLOAT then
			local vVal = msg:ReadFloat();
			
			item:ReceiveNWVar( strName, vVal );
		elseif msgType == IFI_MSG_SETLONG then
			local vVal = msg:ReadLong();
			
			item:ReceiveNWVar( strName, vVal );
		elseif msgType == IFI_MSG_SETSHORT then
			local vVal = msg:ReadShort();
			
			item:ReceiveNWVar( strName, vVal );
		elseif msgType == IFI_MSG_SETSTRING then
			local vVal = msg:ReadString();
			
			item:ReceiveNWVar( strName, vVal );
		elseif msgType == IFI_MSG_SETVECTOR then
			local vVal = msg:ReadVector();
			
			item:ReceiveNWVar( strName, vVal );
		elseif msgType == IFI_MSG_SETITEM then
			local vVal = msg:ReadShort() + 32768;
			iItem = IF.Items:Get( vVal );
			
			if !iItem then ErrorNoHalt( "Itemforge Items: Tried to set a networked item (var ID "..VarID..") on "..tostring( item ).." to non-existent item with ID "..vVal..".\n"); return false end
			
			item:ReceiveNWVar( strName, iItem );
		elseif msgType == IFI_MSG_SETINV then
			local vVal = msg:ReadShort() + 32768;
			iInv = IF.Inv:Get( vVal );
			
			if !iInv then ErrorNoHalt( "Itemforge Items: Tried to set a networked inventory (var ID "..VarID..") on "..tostring( item ).." to non-existent inventory with ID "..vVal..".\n"); return false end
			
			item:ReceiveNWVar( strName, vVal );
		elseif msgType == IFI_MSG_SETUCHAR then
			local vVal = msg:ReadChar() + 128;
			
			item:ReceiveNWVar( strName, vVal );
		elseif msgType == IFI_MSG_SETULONG then
			local vVal = msg:ReadLong() + 2147483648;
			
			item:ReceiveNWVar( strName, vVal );
		elseif msgType == IFI_MSG_SETUSHORT then
			local vVal = msg:ReadShort() + 32768;
			
			item:ReceiveNWVar( strName, vVal );
		elseif msgType == IFI_MSG_SETNIL then
			item:ReceiveNWVar( strName, nil );
		end
	elseif msgType == IFI_MSG_STARTFULLUPALL then
		self:OnStartFullUpdateAll( id );
	elseif msgType == IFI_MSG_ENDFULLUPALL then
		self:OnEndFullUpdateAll();
	elseif msgType == IFI_MSG_RELOAD then
		local strType = msg:ReadString();
		self:LoadItemType( strType, true );
	else
		ErrorNoHalt( "Itemforge Items: Unhandled IFI message \""..msgType.."\"\n" );
	end
end

--We use a proxy here so we can make HandleIFIMessages a method (:) instead of a regular function (.)
usermessage.Hook( "ifi", function( msg ) return IF.Items:HandleIFIMessages( msg ) end );




end