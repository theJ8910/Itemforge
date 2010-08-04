--[[
Itemforge Network Module
SERVER

This module handles the networking of data between client and server.
It also implements a base networked object.
]]--

MODULE.Name="Network";											--Our module will be stored at IF.Network
MODULE.Disabled=false;											--Our module will be loaded

local BaseNWClassName="base_nw";								--The name of the Base Networked class

local IFN_DTYPE_CHAR = 1;
local IFN_DTYPE_SHORT = 2;
local IFN_DTYPE_LONG = 3;

local _OBJECTS={};												--Networked objects are stored here
local ChangedNWObjects={};										--When a network object has a networked property changed, the object is added here temporarily

local _NWBASE={};

--[[
What type of datatype do the NWIDs for networked objects use?
This determines two things:
	1. The total number of unique Itemforge networked objects that can be in the game at any time is determined by the datatype used.
	2. The NWID of a networked object is included anytime a message is sent; the bigger the datatype you use, the larger these messages will be, and as a consequence more bandwidth will be used.

By default, Itemforge uses IFN_DTYPE_SHORT.
If for some reason, however, you feel the need to change this, NWIDType can be set to:
	IFN_DTYPE_CHAR: Up to 256 networked objects may exist at any time. This is a pitiful amount, but the char datatype uses the least amount of bandwidth.
	IFN_DTYPE_SHORT: Up to 65,536 unique networked objects may exist at any time. The short datatype is twice as big as the char datatype in terms of bandwidth used, but the number of networked objects you can have in increased dramatically.
	IFN_DTYPE_LONG: Up to 4,294,967,296 unique networked objects may exist at any time. The long datatype is four times as big as the char datatype in terms of bandwidth used. This datatype will likely slow things down, especially if you actually manage to surpass 65,536 networked objects. If you have to, absolutely have to, the long datatype is here for you.
]]--
MODULE.NWIDType=IFN_DTYPE_SHORT;

--[[
The following commands apply to all networked objects.
]]--
local IFN_MSG_CREATE		=	-128;	--(Server > Client) Sync creation clientside
local IFN_MSG_REMOVE		=	-127;	--(Server > Client) Sync removal clientside
local IFN_MSG_REQUP			=	-128;	--(Client > Server) Client requests full update of a networked object
local IFN_MSG_REQFULLUP		=	-127;	--(Client > Server) Client requests full update of all networked objects
local IFN_MSG_STARTFULLUP	=	-126;	--(Server > Client) A full update of all networked objects is going to being sent - expect this many.
local IFN_MSG_ENDFULLUP		=	-125;	--(Server > Client) A full update of all networked objects has finished.
--[[
I have organized the SET* list by message size.
The exact size of the message sent is hard to know because of encapsulation.
However, I can calculate part of the message's sized based on my knowledge of datatypes.
If something is marked with "?", I am estimating what the size of the datatype is.
Remember, less is more! Do your part to make Garry's Mod playable for everyone - use small datatpes whenever possible!
]]--
local IFN_MSG_SETNIL		=	-124;	--(Server > Client) [0 bits]				Sync a networked var - changes whatever was there before to nil
local IFN_MSG_SETBOOL		=	-123;	--(Server > Client) [8 bits]				Sync a networked boolean
local IFN_MSG_SETCHAR		=	-122;	--(Server > Client) [8 bits]				Sync a networked char (an int from -128 to 127)
local IFN_MSG_SETUCHAR		=	-121;	--(Server > Client) [8 bits]				Sync a networked unsigned char (an int from 0 to 255)
local IFN_MSG_SETSHORT		=	-120;	--(Server > Client) [16 bits]				Sync a networked short (an int from -32,768 to 32,767)
local IFN_MSG_SETUSHORT		=	-119;	--(Server > Client) [16 bits]				Sync a networked unsigned short (an int from 0 to 65,535)
local IFN_MSG_SETENTITY		=	-118;	--(Server > Client) [16 bits?]				Sync a networked entity
local IFN_MSG_SETITEM		=	-117;	--(Server > Client) [16 bits]				Sync a networked item
local IFN_MSG_SETINV		=	-116;	--(Server > Client) [16 bits]				Sync a networked inventory
local IFN_MSG_SETLONG		=	-115;	--(Server > Client) [32 bits]				Sync a networked long (an int from -2,147,483,648 to 2,147,483,647)
local IFN_MSG_SETULONG		=	-114;	--(Server > Client) [32 bits]				Sync a networked unsigned long (an int from 0 to 4,294,967,295)
local IFN_MSG_SETCOLOR		=	-113;	--(Server > Client) [32 bits]				Sync a networked color
local IFN_MSG_SETFLOAT		=	-112;	--(Server > Client) [32 bits]				Sync a networked float
local IFN_MSG_SETVECTOR		=	-111;	--(Server > Client) [96 bits?]				Sync a networked vector
local IFN_MSG_SETANGLE		=	-110;	--(Server > Client) [96 bits?]				Sync a networked angle
local IFN_MSG_SETSTRING		=	-109;	--(Server > Client) [8*(str_len+1) bits?]	Sync a networked string

--Item
local IFN_MSG_CREATEITEM	=	-108;	--(Server > Client) Sync Create item clientside
local IFN_MSG_REMOVEITEM	=	-107;	--(Server > Client) Sync Remove item clientside
local IFN_MSG_SV2CLCOMMAND	=	-106;	--(Server > Client) Send a NWCommand for an item from the server to the client(s)
local IFN_MSG_CL2SVCOMMAND	=	-105;	--(Client > Server) Send a NWCommand for an item from the client to the server
local IFN_MSG_CREATETYPE	=	-104;	--(Server > Client) Macro. Create several items of this item type (used with full updates, saves bandwidth)
local IFN_MSG_CREATEININV	=	-103;	--(Server > Client) Macro. Create item in inventory (saves bandwidth)
local IFN_MSG_MERGE			=	-102;	--(Server > Client) Macro. Merge two items (change amount of an item and remove another, saves bandwidth)
local IFN_MSG_PARTIALMERGE	=	-101;	--(Server > Client) Macro. Merge two items partially (change amount of two items, saves bandwidth)
local IFN_MSG_SPLIT			=	-100;	--(Server > Client) Macro. Split an item (saves bandwidth)

--Inventory
local IFN_MSG_CREATEINV		=	-99;	--(Server > Client) Sync create inventory clientside
local IFN_MSG_REMOVEINV		=	-98;	--(Server > Client) Sync remove inventory clientside
local IFN_MSG_REQUP			=	-97;	--(Client > Server) Client requests an update of an inventory
local IFN_MSG_REQFULLUP		=	-96;	--(Client > Server) Client requests an update of all inventories (joining player)
local IFN_MSG_STARTFULLUP	=	-95;	--(Server > Client) This message tells the client that a full update of all inventories is going to being sent and how many to expect.
local IFN_MSG_ENDFULLUP		=	-94;	--(Server > Client) This message tells the client the full update of all inventories has finished.
local IFN_MSG_INVUP			=	-93;	--(Server > Client) A full update on an inventory is being sent. This sends basic data about the inventory.
local IFN_MSG_WEIGHTCAP		=	-92;	--(Server > Client) The weight capacity of the inventory has changed serverside. Sync to client.
local IFN_MSG_SIZELIMIT		=	-91;	--(Server > Client) The size limit of the inventory has changed serverside. Sync to client.
local IFN_MSG_MAXSLOTS		=	-90;	--(Server > Client) The max number of slots was changed. Sync to client.
local IFN_MSG_CONNECTITEM	=	-89;	--(Server > Client) The inventory has connected itself with an item. Have client connect too.
local IFN_MSG_CONNECTENTITY	=	-88;	--(Server > Client) The inventory has connected itself with an entity. Have client connect too.
local IFN_MSG_SEVERITEM		=	-87;	--(Server > Client) The inventory is severing itself from an item. Have client sever as well.
local IFN_MSG_SEVERENTITY	=	-86;	--(Server > Client) The inventory is severing itself from an entity. Have client sever too.
local IFN_MSG_LOCK			=	-85;	--(Server > Client) The inventory has been locked serverside. Have client lock too.
local IFN_MSG_UNLOCK		=	-84;	--(Server > Client) The inventory has been unlocked serverside. Have client unlock too.

--FileSend stuff
IFN_MSG_FILESENDSTART		=	-83;	--(Server > Client) Indicates a file is about to be sent; gives it's path and size
IFN_MSG_FILESEND			=	-82;	--(Server > Client) Contains a fragment of the sent file's contents.
IFN_MSG_FILESENDEND			=	-81;	--(Server > Client) Indicates the file has been sent completely.

--[[
* SHARED

Initilize network module
]]--
function MODULE:Initialize()
	IF.Base:RegisterClass(_NWBASE,BaseNWClassName);
	self:StartTick()
end

--[[
* SHARED

Cleanup network module
]]--
function MODULE:Cleanup()
	self:StopTick();
end

--[[
* SHARED

Returns the networked object with the given ID.
]]--
function MODULE:Get(id)
	return _OBJECTS[id];
end

--[[
* SHARED

Starts the network tick
]]--
function MODULE:StartTick()
	hook.Add("Tick","itemforge_tick",function(...) self:Tick(...) end);
end

--[[
* SHARED

Ends the network tick
]]--
function MODULE:StopTick()
	hook.Remove("Tick","itemforge_tick");
end

--[[
* SHARED

Ticks all network objects clientside and serverside
]]--
function MODULE:Tick()
	--[[
	for k,v in pairs(ChangedNWObjects) do
		v:Tick();
		ChangedNWObjects[k]=nil;
	end
	]]--
end

if SERVER then

local ServerOutHandlers={
	[IFN_MSG_FILESENDSTART]=function(self,pl,strFilepath,iSize)
		self:IFSendStart(pl,IFN_MSG_FILESENDSTART,0);
		self:IFSendString(strFilepath);
		self:IFSendLong(iSize);
		self:IFSendEnd();
	end,
	[IFN_MSG_FILESEND]=function(self,pl,strFragment)
		self:IFSendStart(pl,IFN_MSG_FILESEND,0);
		self:IFSendString(strFragment);
		self:IFSendEnd();
	end,
	[IFN_MSG_FILESENDEND]=function(self,pl)
		self:IFSendStart(pl,IFN_MSG_FILESENDEND,0);
		self:IFSendEnd();
	end,
};

local ServerInHandlers={
};

--Server send functions
local IFSendStartLookupTable = {
	[IFN_DTYPE_CHAR]	= function(self,pl,eMsg,id) umsg.Start("if",pl); umsg.Char(eMsg); umsg.Char((id or 0)-128)			end,
	[IFN_DTYPE_SHORT]	= function(self,pl,eMsg,id) umsg.Start("if",pl); umsg.Char(eMsg); umsg.Short((id or 0)-32768)		end,
	[IFN_DTYPE_LONG]	= function(self,pl,eMsg,id) umsg.Start("if",pl); umsg.Char(eMsg); umsg.Long((id or 0)-2147483648)	end
};

MODULE.IFSendStart = IFSendStartLookupTable[MODULE.NWIDType];

function MODULE:IFSendAngle(v)			umsg.Angle(v)			end
function MODULE:IFSendBool(v)			umsg.Bool(v)			end
function MODULE:IFSendChar(v)			umsg.Char(v)			end
function MODULE:IFSendEntity(v)			umsg.Entity(v)			end
function MODULE:IFSendFloat(v)			umsg.Float(v)			end
function MODULE:IFSendLong(v)			umsg.Long(v)			end
function MODULE:IFSendShort(v)			umsg.Short(v)			end
function MODULE:IFSendString(v)			umsg.String(v)			end
function MODULE:IFSendVector(v)			umsg.Vector(v)			end
function MODULE:IFSendVectorNormal(v)	umsg.VectorNormal(v)	end

local IFSendNWObjLookupTable = {
	[IFN_DTYPE_CHAR]	= function(self,v) umsg.Char(v:GetID()-128)					end,
	[IFN_DTYPE_SHORT]	= function(self,v) umsg.Short(v:GetID()-32768)				end,
	[IFN_DTYPE_LONG]	= function(self,v) umsg.Long(v:GetID()-2147483648)			end
};

MODULE.IFSendNWObj=IFSendNWObjLookupTable[MODULE.NWIDType];

function MODULE:IFSendEnd() umsg.End() end

--Server receive functions
function MODULE:IFReadAngle()			return nil				end
function MODULE:IFReadBool()			return nil				end
function MODULE:IFReadChar()			return nil				end
function MODULE:IFReadEntity()			return nil				end
function MODULE:IFReadFloat()			return nil				end
function MODULE:IFReadLong()			return nil				end
function MODULE:IFReadShort()			return nil				end
function MODULE:IFReadString()			return nil				end
function MODULE:IFReadVector()			return nil				end
function MODULE:IFReadVectorNormal()	return nil				end

local IFReadNWIDLookupTable = {
	[IFN_DTYPE_CHAR]	= function(self,msg)	return 0+128		end,
	[IFN_DTYPE_SHORT]	= function(self,msg)	return 0+32768		end,
	[IFN_DTYPE_LONG]	= function(self,msg)	return 0+2147483648	end
};

MODULE.IFReadNWID=IFReadNWIDLookupTable[MODULE.NWIDType];
function MODULE:IFReadNWObj()			return self:Get(self:IFReadNWID())		end

--[[
* SERVER

Sends a message out with the given args on the given player(s)
]]--
function MODULE:ServerOut(eMsg,pl,...)
	local f=ServerOutHandlers[eMsg];
	if pl==nil then
		for k,v in pairs(player.GetAll()) do
			f(self,v,...);
		end
	else
		f(self,pl,...);
	end
end

--[[
* SERVER

Handles incoming "if" (Itemforge) messages from client
]]--
function MODULE:ServerIn(pl,command,args)
	if !pl || !pl:IsValid() || !pl:IsPlayer() then ErrorNoHalt("Itemforge Network: Couldn't handle incoming message from client - Player given doesn't exist or wasn't player!\n"); return false end
	if !args[1] then ErrorNoHalt("Itemforge Network: Couldn't handle incoming message from client "..tostring(pl).." - message type wasn't received.\n"); return false end
	
	local eMsg=tonumber(args[1]);
	local f=ServerInHandlers[eMsg];
	if f then
		f(self,pl,args);
		return true;
	else
		ErrorNoHalt("Itemforge Network: Unhandled IF message \""..msgType.."\"\n");
		return false;
	end
end

concommand.Add("if",function(pl,command,args) return IF.Items:ServerIn(pl,command,args) end);




else




local ClientOutHandlers={
};

local ClientInHandlers={
	[IFN_MSG_FILESENDSTART]=function(self,msg)
		self:IFReadNWID(msg);
		IF.Util:FileSendStart(self:IFReadString(msg),self:IFReadLong(msg));
	end,
	[IFN_MSG_FILESEND]=function(self,msg)
		self:IFReadNWID(msg);
		IF.Util:FileSendTick(self:IFReadString(msg));
	end,
	[IFN_MSG_FILESENDEND]=function(self,msg)
		self:IFReadNWID(msg);
		IF.Util:FileSendEnd();
	end,
};

--Client send functions
local IFSendStartLookupTable = {
	[IFN_DTYPE_CHAR]	= function(self,eMsg,id) end,
	[IFN_DTYPE_SHORT]	= function(self,eMsg,id) end,
	[IFN_DTYPE_LONG]	= function(self,eMsg,id) end
};

MODULE.IFSendStart = IFSendStartLookupTable[MODULE.NWIDType];

function MODULE:IFSendAngle(v) end
function MODULE:IFSendBool(v) end
function MODULE:IFSendChar(v) end
function MODULE:IFSendEntity(v) end
function MODULE:IFSendFloat(v) end
function MODULE:IFSendLong(v) end
function MODULE:IFSendShort(v) end
function MODULE:IFSendString(v) end
function MODULE:IFSendVector(v) end
function MODULE:IFSendVectorNormal(v) end

local IFSendNWObjLookupTable = {
	[IFN_DTYPE_CHAR]	= function(self,v) end,
	[IFN_DTYPE_SHORT]	= function(self,v) end,
	[IFN_DTYPE_LONG]	= function(self,v) end
};

MODULE.IFSendNWObj=IFSendNWObjLookupTable[MODULE.NWIDType];

function MODULE:IFSendEnd() end

--Client receive functions
function MODULE:IFReadAngle(msg)		return msg:ReadAngle()				end
function MODULE:IFReadBool(msg)			return msg:ReadBool()				end
function MODULE:IFReadChar(msg)			return msg:ReadChar()				end
function MODULE:IFReadEntity(msg)		return msg:ReadEntity()				end
function MODULE:IFReadFloat(msg)		return msg:ReadFloat()				end
function MODULE:IFReadLong(msg)			return msg:ReadLong()				end
function MODULE:IFReadShort(msg)		return msg:ReadShort()				end
function MODULE:IFReadString(msg)		return msg:ReadString()				end
function MODULE:IFReadVector(msg)		return msg:ReadVector()				end
function MODULE:IFReadVectorNormal(msg) return msg:ReadVectorNormal()		end

local IFReadNWIDLookupTable = {
	[IFN_DTYPE_CHAR]	= function(self,msg)	return msg:ReadChar()+128			end,
	[IFN_DTYPE_SHORT]	= function(self,msg)	return msg:ReadShort()+32768		end,
	[IFN_DTYPE_LONG]	= function(self,msg)	return msg:ReadLong()+2147483648	end,
};

MODULE.IFReadNWID=IFReadNWIDLookupTable[MODULE.NWIDType];
function MODULE:IFReadNWObj(msg)		return self:Get(self:IFReadNWID(msg));		end

--[[
* CLIENT

Sends a message out with the given args
]]--
function MODULE:ClientOut(eMsg,...)
	ClientOutHandlers[eMsg](self,...);
end

--[[
* CLIENT

Handles incoming "if" messages from server
]]--
function MODULE:ClientIn(msg)
	local eMsg=self:IFReadChar(msg);
	
	local f=ClientInHandlers[eMsg];
	if f then
		f(self,msg);
		return true;
	else
		ErrorNoHalt("Itemforge Network: Unhandled IF message \""..eMsgType.."\"\n");
		return false;
	end
end

usermessage.Hook("if",function(msg) return IF.Network:ClientIn(msg) end);




end









_NWBASE._ProtectedKeys={};

--[[
* SHARED
* Different for each Class

The Base Networked class is based off of the Base class.
]]--
_NWBASE.Base="base";

--[[
* SHARED
* Different for each Class

This table lists the names of networked vars on _this type of_ networked object.
This table is sorted by each networked var's ID.
]]--
_NWBASE._NWVars=nil;

--[[
* SHARED
* Default defined in this class
* Different for each object

This is an ID number used to identify what object a network update is intended for.
ID numbers range from 0 to n. n is the max size of the integer datatype used (see MODULE.NWIDType at top of file)
]]--
_NWBASE._NWID=0;

--[[
* SHARED
* Different for each object

This table serves different purposes Serverside and Clientside.
Serverside:
	This table contains the values of any network vars on this object at the time of the last tick.
	When the next tick occurs, we compare the current values of any networked vars to the values stored in this table.
	If the values are different, then we send updates of those values to the object's NWClient(s),
	then set the "last tick" values stored in this table to the current values.
Clientside:
	This table contains updates for networked vars on this object that have been received from the server.
	When the next clientside tick occurs, we go through this table. If there are any updates waiting,
	we update the networked vars with the values from this table.
	Following that, this table is cleared.
]]--
_NWBASE._NWVar=nil;

--[[
* SHARED
* Protected

This function returns the Network ID of this object.
]]--
function _NWBASE:GetID()
	return self._NWID;
end
--_NWBASE._ProtectedKeys["GetID"]=true;

--[[
* SHARED
* Protected

This function runs every tick, both serverside and clientside.
]]--
function _NWBASE:Tick()
	if SERVER then
	else
	end
end
--_NWBASE._ProtectedKeys["Tick"]=true;

--[[
* SHARED
* Event

When tostring() is used on this object, this function returns a string describing the object.
]]--
function _NWBASE:ToString()
	return "Networked Object ["..self.ClassName.."]";
end

if SERVER then




--[[
* SERVER
* Default defined per-class
* Different for each object

A Network Client has two purposes:
	A.) The server will only send data about an object to it's network client(s).
	B.) The server will only listen to messages regarding this object from it's network clients. (eg: Player 5 asks the server to pick up Item 6. Player 5 is not a network client, so his request is ignored by the server)

If nil, all players are network clients of this object.
If this is a player, only that player is a network client of this object.
If this is a table of players, all players in that table become network clients of this object.

If this is IF_PVS, then network clients are added and removed automatically, depending on whether or not players can "see" this object (obj:DoesPlayerSee(pl) determines whether or not a player can see this object).
	The advantage of PVS is that a player only receives data from the server regarding objects the player can see, potentially saving a lot of bandwidth and as a consequence making the game less laggy for everyone.
	A disadvantage of PVS is that any time a player 'discovers' an object (goes from not being able to see it to being able to see it) an update of the item must be sent to this player.
	This may produce temporary spikes in bandwidth usage when this occurs, especially if the player discovers several items at once.
	Another disadvantage of PVS is that some objects (although most don't) may need to constantly network data to/from clients,
	even if they can't see them. In this case, you'll probably want to use one of the options above.
	
Any time a player becomes a network client, an update of the object will be sent to him.
If a player is no longer a network client, updates will stop being sent to him.
No message to remove the object from that client is sent until the object is removed from the server.
]]--
_NWBASE._NWClient=IF_PVS;

--[[
SERVER
Object

A table of players that saw this object last frame.
This table is indexed by Player ID.
]]--
_NWBASE._PVS=nil;

--[[
* SERVER
* Protected

Can a player "see" this object? This is really only important if your networked object uses IF_PVS for it's _NWClient.
Override this function in classes that inherit from this.

Returns true if the given player can see this object, and false otherwise.
]]--
function _NWBASE:DoesPlayerSee(pl)
	return false;
end
_NWBASE._ProtectedKeys["DoesPlayerSee"]=true;

--[[
* SERVER
* Protected

This function detects when something has been set on the object.
It's first prerogative is to stop overrides of any protected keys from the _BASE and _NWBASE.

But it's main purpose is this:
If a networked value was set to something different, then the object is marked as "changed",
and an update will be sent to the approprite clients next tick.
]]--
function _NWBASE:OnNewIndex(k,v)
	--TODO detect changed keys
	return true;
end
_NWBASE._ProtectedKeys["OnNewIndex"]=true;



end