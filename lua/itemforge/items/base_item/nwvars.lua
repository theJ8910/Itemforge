--[[
Itemforge Item Networked Variables
SHARED

These are here to make it easier to network data between the server and the clients.

Networked vars must first be defined for this item-type.
They must be created in the same order both serverside and clientside (which is why they're in the shared file).
Here is a demonstration of how to create a networked var for this item-type:
	IF.Items:CreateNWVar( ITEM, "MyNetworkedInt", "int", 1 );
	
You can set this networked var to 5 by doing:
	self:SetNWInt( "MyNetworkedInt", 5 );
	
You can get this networked var by doing:
	self:GetNWInt( "MyNetworkedInt" );


Setting any networked var serverside will cause it to be set clientside as well.
If pl is nil, and the network var changed (ex, changed from 3 to 5, not 3 to 3) Itemforge will update the network var on all connected players (or, if the item has a NetOwner, just that player).
If pl is a certain player, Itemforge will only update the network var on that client, even if the network var didn't change.
If pl is false, Itemforge will NOT update the network var on any clients.
You can set something to nil both clientside and serverside by giving nil to the SetNW* function.

The datatype of the networked var must be given. This tells Itemforge what kind of data it is (like a number, an entity, etc).
So, if your var's datatype is "int", you have to do SetNWInt() to set it.

Networked vars can have default values.
The default value is set when you create the networked var with IF.Items:CreateNWVar() (in our example above, it's 1).
The default value can be
	nil (for nothing - or in other words, it's optional - you don't even have to give it)
	a constant value, like the number 1 or the text "hello"
	a function, like... function(self) return self.Weight end
The default value is given when doing a GetNW* if:
	we haven't set a networked var yet
	we set a networked var to nil with the SetNW* functions

Networked vars will be transferred via inheritance - that is, if Item A has a networked var, and Item B inherits from Item A, Item B has Item A's networked var too.
You can also override networked vars inherited from other item types. For example:
	If Item A:
		has a networked var, "MyNetworkedVar" with a default value of 5
	and Item B:
		has a networked var, "MyNetworkedVar" with a default value of 21
		and inherits from Item A
	
	then Item B's "MyNetworkedVar" overrides Item A's "MyNetworkedVar", instead of inheriting it.
	The default value of MyNetworkedVar will be 21 on Item B.
]]--

--Don't modify/override these. They're either set automatically, don't need to be changed, or are listed here so I can keep track of them.
ITEM.NWVarsByName	= nil;		--List of Networked vars in this itemtype (key is name, value is id).
ITEM.NWVarsByID		= nil;		--List of Networked vars in this itemtype (key is id, value is name).
ITEM.NWVars			= nil;		--The current value for networked vars set on this particular item are stored here, both clientside and serverside.

if SERVER then




ITEM.NWVarsLastTick	= nil;		--Last time the server ticked, the predicted networked vars had these values.




else




ITEM.NWVarsThisTick	= nil;		--Next time the client ticks, the predicted networked vars will be set to this.




end

--[[
Default Networked Vars - ITEM, NameOfVar, Datatype, DefaultValue (optional), IsPredicted (optional), HoldFromUpdate (optional)
]]--
--What condition is this item in? If the item is actually a stack of items, the 'top' item is in this condition.
IF.Items:CreateNWVar( ITEM, "Health",				"int",		function( self ) return self.MaxHealth			end );

--How durable is the item (how many hit points total does it have)? Higher values mean the item is more durable.
IF.Items:CreateNWVar( ITEM, "MaxHealth",			"int",		function( self ) return self.MaxHealth			end );

--Weight is how much an item weighs, in grams. This affects how much weight an item fills in an inventory with a weight cap, not the physics weight when the item is on the ground.
IF.Items:CreateNWVar( ITEM, "Weight",				"int",		function( self ) return self.Weight				end );

--Size is a measure of how much space an item takes up (think volume, not weight). Inventories can be set up to reject items that are too big.
IF.Items:CreateNWVar( ITEM, "Size",					"int",		function( self ) return self.Size				end );

--What is this item's world model? This is visible when the item is in the world, in item slots, and when held in third person.
IF.Items:CreateNWVar( ITEM, "WorldModel",			"string",	function( self ) return self.WorldModel			end );

--What is this item's view model? The player sees himself holding this while he is wielding the item as an SWEP in first person.
IF.Items:CreateNWVar( ITEM, "ViewModel",			"string",	function( self ) return self.ViewModel			end );

--When the item is held, does the primary auto-attack?
IF.Items:CreateNWVar( ITEM, "SWEPPrimaryAuto",		"bool",		function( self ) return self.SWEPPrimaryAuto	end );

--When the item is held, does the secondary auto-attack?
IF.Items:CreateNWVar( ITEM, "SWEPSecondaryAuto",	"bool",		function( self ) return self.SWEPSecondaryAuto	end );

--When the item is held, how is it held?
IF.Items:CreateNWVar( ITEM, "SWEPHoldType",			"int",		function( self ) return self:HoldTypeToID( self.SWEPHoldType ) end );

--When the item is held, is the view model flipped?
IF.Items:CreateNWVar( ITEM, "SWEPViewModelFlip",	"bool",		function( self ) return self.SWEPViewModelFlip	end );

--When the item is held, what slot # and position does it occupy in the weapon selection menu?
IF.Items:CreateNWVar( ITEM, "SWEPSlot",				"int",		function( self ) return self.SWEPSlot			end );
IF.Items:CreateNWVar( ITEM, "SWEPSlotPos",			"int",		function( self ) return self.SWEPSlotPos		end );

--What color is the item? This affects model color and icon color by default.
IF.Items:CreateNWVar( ITEM, "Color",				"color",	function( self ) return self.Color				end );

--What override material does the item use? This affects the world model material by default.
IF.Items:CreateNWVar( ITEM, "OverrideMaterial",		"string",	function( self ) return self.OverrideMaterial	end );

--[[
How many items are in this stack?

Items with max amounts other than 1 are called stacks.
This doesn't actually create copies of the item, it just "says" there are 100.
The total weight of the stack is calculated by doing (amount * individual item weight)
Whenever an item's health reaches 0, item amounts are subtracted (usually by 1, but possibly more if the damage is great enough).
If amount reaches 0, the item is removed (this is why the default is 1).
:Split() can be used to split the stack, making a new stack (a copy) of the item.
Likewise, :Merge() can remove other items and add their amounts onto this item.
]]--
IF.Items:CreateNWVar( ITEM, "Amount",				"int",		function( self ) return self.StartAmount		end, nil, true );

--How many items can be in this stack? If this is set to 0, an unlimited amount of items of this type can be in the same stack.
IF.Items:CreateNWVar( ITEM, "MaxAmount",			"int",		function( self ) return self.MaxAmount			end );

--[[
* SHARED
* Protected

Set a networked angle on this item
]]--
function ITEM:SetNWAngle( strName, aAng, bSuppress )
	if strName							== nil			then return self:Error( "Couldn't set networked angle. strName wasn't given!\n" )									end
	if self.NWVarsByName[strName]		== nil			then return self:Error( "There is no networked var by the name "..strName..".\n" )									end
	if self.NWVarsByName[strName].Type  != 7			then return self:Error( "Couldn't set networked angle. "..strName.." is not a networked angle.\n" )					end
	if aAng != nil && !IF.Util:IsAngle( aAng )			then return self:Error( "Couldn't set networked angle. Given value was a \""..type( aAng ).."\", not an angle!\n" ) end
	
	local bUpd = self:SetNWVar( strName, aAng );
	
	if SERVER && bUpd && !bSuppress && !self.NWVarsByName[strName].Predicted then
		self:SendNWVar( strName );
	end
	
	return true;
end
IF.Items:ProtectKey( "SetNWAngle" );

--[[
* SHARED
* Protected

Set a networked bool on this item
]]--
function ITEM:SetNWBool( strName, bBool, bSuppress )
	if strName								== nil	then return self:Error( "Couldn't set networked bool. strName wasn't given!\n" )										end
	if self.NWVarsByName[strName]			== nil	then return self:Error( "There is no networked var by the name "..strName..".\n" )										end
	if self.NWVarsByName[strName].Type		!= 3	then return self:Error( "Couldn't set networked bool. "..strName.." is not a networked bool.\n" )						end
	if bBool != nil && !IF.Util:IsBoolean( bBool )	then return self:Error( "Couldn't set networked bool. Given value was a \""..type( bBool ).."\", not a boolean!\n" )	end
	
	local bUpd = self:SetNWVar( strName, bBool );
	
	if SERVER && bUpd && !bSuppress && !self.NWVarsByName[strName].Predicted then
		self:SendNWVar( strName );
	end
	
	return true;
end
IF.Items:ProtectKey( "SetNWBool" );

--[[
* SHARED
* Protected

Set a networked entity on this item
]]--
function ITEM:SetNWEntity( strName, eEnt, bSuppress )
	if strName							== nil		then return self:Error( "Couldn't set networked entity. strName wasn't given!\n" )											end
	if self.NWVarsByName[strName]		== nil		then return self:Error( "There is no networked var by the name "..strName..".\n" )											end
	if self.NWVarsByName[strName].Type	!= 5		then return self:Error( "Couldn't set networked entity. "..strName.." is not a networked entity.\n" )						end
	if cEnt != nil && !IF.Util:IsEntity( eEnt )		then return self:Error( "Couldn't set networked entity. Given value was a \""..type( cEnt ).."\", not an entity! Valid entity types are: Entity, Player, NPC, Vehicle, and Weapon\n" ) end
	
	local bUpd = self:SetNWVar( strName, cEnt );
	
	if SERVER && bUpd && !bSuppress && !self.NWVarsByName[strName].Predicted then
		self:SendNWVar( strName );
	end
	
	return true;
end
IF.Items:ProtectKey( "SetNWEntity" );

--[[
* SHARED
* Protected

Set a networked float on this item
]]--
function ITEM:SetNWFloat( strName, fFloat, bSuppress )
	if strName							== nil			then return self:Error( "Couldn't set networked float. strName wasn't given!\n" )										end
	if self.NWVarsByName[strName]		== nil			then return self:Error( "There is no networked var by the name "..strName..".\n" )										end
	if self.NWVarsByName[strName].Type	!= 2			then return self:Error( "Couldn't set networked float. "..strName.." is not a networked float.\n" )						end
	if fFloat != nil && !IF.Util:IsNumber( fFloat )		then return self:Error( "Couldn't set networked float. Given value was a \""..type( fFloat ).."\", not a number!\n" )	end
	
	local bUpd = self:SetNWVar( strName, fFloat );
	
	if SERVER && bUpd && !bSuppress && !self.NWVarsByName[strName].Predicted then
		self:SendNWVar( strName );
	end
	
	return true;
end
IF.Items:ProtectKey( "SetNWFloat" );

--[[
* SHARED
* Protected

Set a networked integer on this item.

The right type of data to send (char, uchar, short, ushort, long, or ulong) is determined automatically.
We opt to use the smallest datatypes possible.
If run on the server, and the number given is too large to be sent (even larger than an unsigned int) the number will be set to 0, both serverside and clientside.
]]--
function ITEM:SetNWInt( strName, iInt, bSuppress )
	if strName							== nil		then return self:Error( "Couldn't set networked integer. strName wasn't given!\n" )									end
	if self.NWVarsByName[strName]		== nil		then return self:Error( "There is no networked var by the name "..strName..".\n" )									end
	if self.NWVarsByName[strName].Type	!= 1		then return self:Error( "Couldn't set networked int. "..strName.." is not a networked int.\n" )						end
	if iInt != nil then
		--We were given something, were we given a valid number?
		if !IF.Util:IsNumber( iInt )				then return self:Error( "Couldn't set networked int. Given value was a \""..type( iInt ).."\", not a number!\n" )	end
		
		--If we /were/ given a valid number, we need to truncate the decimal, if there is any.
		iInt = math.floor( iInt );
	end
	
	local bUpd = self:SetNWVar( strName, iInt );
	
	if SERVER && bUpd && !bSuppress && !self.NWVarsByName[strName].Predicted then
		self:SendNWVar( strName );
	end
	
	return true;
end
IF.Items:ProtectKey( "SetNWInt" );

--[[
* SHARED
* Protected

Set a networked string on this item
]]--
function ITEM:SetNWString( strName, strString, bSuppress )
	if strName							== nil			then return self:Error( "Couldn't set networked string. strName wasn't given!\n" )											end
	if self.NWVarsByName[strName]		== nil			then return self:Error( "There is no networked var by the name "..strName..".\n" )											end
	if self.NWVarsByName[strName].Type	!= 4			then return self:Error( "Couldn't set networked string. "..strName.." is not a networked string.\n" )						end
	if sString!=nil && !IF.Util:IsString( strString )	then return self:Error( "Couldn't set networked string. Given value was a \""..type( strString ).."\", not a string!\n" )	end
	
	local bUpd = self:SetNWVar( strName, strString );
	
	if SERVER && bUpd && !bSuppress && !self.NWVarsByName[strName].Predicted then
		self:SendNWVar( strName );
	end
	
	return true;
end
IF.Items:ProtectKey( "SetNWString" );

--[[
* SHARED
* Protected

Set a networked vector on this item
]]--
function ITEM:SetNWVector( strName, vVec, bSuppress )
	if strName							== nil		then return self:Error( "Couldn't set networked vector. strName wasn't given!\n" )										end
	if self.NWVarsByName[strName]		== nil		then return self:Error( "There is no networked var by the name "..strName..".\n" )										end
	if self.NWVarsByName[strName].Type	!= 6		then return self:Error( "Couldn't set networked vector. "..strName.." is not a networked vector.\n" )					end
	if vVec != nil && !IF.Util:IsVector( vVec )		then return self:Error( "Couldn't set networked vector. Given value was a \""..type( vVec ).."\", not a vector!\n" )	end
	
	local bUpd = self:SetNWVar( strName, vVec );
	
	if SERVER && bUpd && !bSuppress && !self.NWVarsByName[strName].Predicted then
		self:SendNWVar( strName );
	end
	
	return true;
end
IF.Items:ProtectKey("SetNWVector");

--[[
* SHARED
* Protected

Set a networked item on this item
]]--
function ITEM:SetNWItem( strName, item, bSuppress )
	if strName							== nil		then return self:Error( "Couldn't set networked item. strName wasn't given!\n" )										end
	if self.NWVarsByName[strName]		== nil		then return self:Error( "There is no networked var by the name \""..strName.."\".\n" )									end
	if self.NWVarsByName[strName].Type	!= 8		then return self:Error( "Couldn't set networked item. \""..strName.."\" is not a networked item.\n" )					end
	if item != nil && !IF.Util:IsItem( item )		then return self:Error( "Couldn't set networked item. Given value was a \""..type( item ).."\", not a valid item!\n" );	end
	
	local bUpd = self:SetNWVar( strName, cItem );
	
	if SERVER && bUpd && !bSuppress && !self.NWVarsByName[strName].Predicted then
		self:SendNWVar( strName );
	end
	
	return true;
end
IF.Items:ProtectKey( "SetNWItem" );

--[[
* SHARED
* Protected

Set a networked inventory on this item
]]--
function ITEM:SetNWInventory( strName, inv, bSuppress )
	if strName							== nil		then return self:Error( "Couldn't set networked inventory. strName wasn't given!\n" )										end
	if self.NWVarsByName[strName]		== nil		then return self:Error( "There is no networked var by the name "..strName..".\n" )											end
	if self.NWVarsByName[strName].Type	!= 9		then return self:Error( "Couldn't set networked inventory. "..strName.." is not a networked inventory.\n" )					end
	if cInv != nil && !IF.Util:IsInventory( inv )	then return self:Error( "Couldn't set networked inventory. Given value was a \""..type( inv ).."\", not an inventory!\n" ); end
	
	local bUpd = self:SetNWVar( strName, cInv );
	
	if SERVER && bUpd && !bSuppress && !self.NWVarsByName[strName].Predicted then
		self:SendNWVar( strName );
	end
	
	return true;
end
IF.Items:ProtectKey( "SetNWInventory" );

--[[
* SHARED
* Protected

Set a networked color on this item
]]--
function ITEM:SetNWColor( strName, tColor, bSuppress )
	if strName							== nil	then return self:Error( "Couldn't set networked color. strName wasn't given!\n" )						end
	if self.NWVarsByName[strName]		== nil	then return self:Error( "There is no networked var by the name \""..strName.."\".\n" )					end
	if self.NWVarsByName[strName].Type	!= 10	then return self:Error( "Couldn't set networked color. \""..strName.."\" is not a networked color.\n" )	end
	if tColor != nil then
		if !IF.Util:IsColor( tColor )			then return self:Error( "Couldn't set networked color. Given value was a \""..type( tColor ).."\", not a color!\n" );
		else										 IF.Util:ClampColor( tColor )
		end
	end
	
	local bUpd = self:SetNWVar( strName, tColor );
	
	if SERVER && bUpd && !bSuppress && !self.NWVarsByName[strName].Predicted then
		self:SendNWVar( strName );
	end
	
	return true;
end
IF.Items:ProtectKey( "SetNWColor" );

--[[
* SHARED
* Protected
* Internal

Don't call this directly, it's called by the other SetNW* functions
This actually sets the networked var to the given value serverside/clientside.
This returns true if the networked value changed from what it was, or false if it didn't.
]]--
function ITEM:SetNWVar( strName, vValue )
	--If NWVars hasn't been created yet, we'll create it
	if self.NWVars == nil then self.NWVars = {} end
	
	--No change necessary if new value and old are same thing
	if ( vValue == nil && self.NWVars[strName] == nil ) || self:GetNWVar( strName ) == vValue then return false end
	
	--Set the networked var given to this name
	self.NWVars[strName] = vValue;
	
	--Our OnSetNWVar event gets called here
	--TODO Lets nix OnSetNWVar in favor of a per-NWVar callback function
	self:Event( "OnSetNWVar", nil, strName, vValue );
		
	return true;
end
IF.Items:ProtectKey( "SetNWVar" );

--[[
* SHARED
* Protected

Returns a networked entity with the given name.
If the networked entity is no longer valid it's set to nil.
]]--
function ITEM:GetNWEntity( strName )
	local eEntity = self:GetNWVar( strName );
	if eEntity && !eEntity:IsValid() then
		self:SetNWEntity( strName, nil );
		return nil;
	end
	return eEntity;
end
IF.Items:ProtectKey( "GetNWEntity" );

--[[
* SHARED
* Protected

Returns a networked item with the given name.
If the networked item is no longer valid it's set to nil.
]]--
function ITEM:GetNWItem( strName )
	local item = self:GetNWVar( strName );
	if item && !item:IsValid() then
		self:SetNWItem( strName, nil );
		return nil;
	end
	return item;
end
IF.Items:ProtectKey( "GetNWItem" );

--[[
* SHARED
* Protected

Returns a networked inventory with the given name.
If the networked inventory is no longer valid it's set to nil.
]]--
function ITEM:GetNWInventory( strName )
	local inv = self:GetNWVar( strName );
	if inv && !inv:IsValid() then
		self:SetNWInventory( strName, nil );
		return nil;
	end
	return inv;
end
IF.Items:ProtectKey( "GetNWInventory" );

--[[
* SHARED
* Internal
* Protected

Returns a networked var.
Don't call this directly.
]]--
function ITEM:GetNWVar( strName )
	if self.NWVarsByName[strName] == nil then self:Error( "There is no networked var by the name "..strName..".\n" ); return nil; end
	
	if self.NWVars && self.NWVars[strName] != nil then		--Return this NWVar if it has been set
		return self.NWVars[strName];
	else													--If it hasn't, let's check for a default value to return.
		local d = self.NWVarsByName[strName].Default;
		
		--[[
		If the default value is a function we'll run it and return what it returns
		If it isn't, we'll just return whatever the default value was
		if the default value is nil, we return nil
		]]--
		if IF.Util:IsFunction( d ) then
			local s, r = pcall( d, self );
			if !s then		self:Error( "Couldn't get default value for NWVar \""..strName.."\": "..r.."\n" );	return nil;
			else			return r;
			end
		else
			return d;
		end
	end
end
IF.Items:ProtectKey( "GetNWVar" );

--Shitload of aliases for your convenience
ITEM.SetNetworkedAngle		= ITEM.SetNWAngle;			IF.Items:ProtectKey( "SetNetworkedAngle" );
ITEM.SetNetworkedBool		= ITEM.SetNWBool;			IF.Items:ProtectKey( "SetNetworkedBool" );
ITEM.SetNetworkedColor		= ITEM.SetNWColor;			IF.Items:ProtectKey( "SetNetworkedColor" );
ITEM.SetNetworkedEntity		= ITEM.SetNWEntity;			IF.Items:ProtectKey( "SetNetworkedEntity" );
ITEM.SetNetworkedFloat		= ITEM.SetNWFloat;			IF.Items:ProtectKey( "SetNetworkedFloat" );
ITEM.SetNetworkedInt		= ITEM.SetNWInt;			IF.Items:ProtectKey( "SetNetworkedInt" );
ITEM.SetNetworkedString		= ITEM.SetNWString;			IF.Items:ProtectKey( "SetNetworkedString" );
ITEM.SetNetworkedVector		= ITEM.SetNWVector;			IF.Items:ProtectKey( "SetNetworkedVector" );
ITEM.SetNetworkedItem		= ITEM.SetNWItem;			IF.Items:ProtectKey( "SetNetworkedItem" );
ITEM.SetNetworkedInventory	= ITEM.SetNWInventory;		IF.Items:ProtectKey( "SetNetworkedInventory" );
ITEM.SetNetworkedInv		= ITEM.SetNWInventory;		IF.Items:ProtectKey( "SetNetworkedInv" );

ITEM.SetNWInv				= ITEM.SetNWInventory;		IF.Items:ProtectKey( "SetNWInv" );

ITEM.GetNetworkedAngle		= ITEM.GetNWVar;			IF.Items:ProtectKey( "GetNetworkedAngle" );
ITEM.GetNetworkedBool		= ITEM.GetNWVar;			IF.Items:ProtectKey( "GetNetworkedBool" );
ITEM.GetNetworkedColor		= ITEM.GetNWVar;			IF.Items:ProtectKey( "GetNetworkedColor" );
ITEM.GetNetworkedEntity		= ITEM.GetNWEntity;			IF.Items:ProtectKey( "GetNetworkedEntity" );
ITEM.GetNetworkedFloat		= ITEM.GetNWVar;			IF.Items:ProtectKey( "GetNetworkedFloat" );
ITEM.GetNetworkedInt		= ITEM.GetNWVar;			IF.Items:ProtectKey( "GetNetworkedInt" );
ITEM.GetNetworkedString		= ITEM.GetNWVar;			IF.Items:ProtectKey( "GetNetworkedString" );
ITEM.GetNetworkedVector		= ITEM.GetNWVar;			IF.Items:ProtectKey( "GetNetworkedVector" );
ITEM.GetNetworkedItem		= ITEM.GetNWItem;			IF.Items:ProtectKey( "GetNetworkedItem" );
ITEM.GetNetworkedInventory	= ITEM.GetNWInventory;		IF.Items:ProtectKey( "GetNetworkedInventory" );
ITEM.GetNetworkedInv		= ITEM.GetNWInv;			IF.Items:ProtectKey( "GetNetworkedInv" );

ITEM.GetNWAngle				= ITEM.GetNWVar;			IF.Items:ProtectKey( "GetNWAngle" );
ITEM.GetNWBool				= ITEM.GetNWVar;			IF.Items:ProtectKey( "GetNWBool" );
ITEM.GetNWColor				= ITEM.GetNWVar;			IF.Items:ProtectKey( "GetNWColor" );
ITEM.GetNWFloat				= ITEM.GetNWVar;			IF.Items:ProtectKey( "GetNWFloat" );
ITEM.GetNWInt				= ITEM.GetNWVar;			IF.Items:ProtectKey( "GetNWInt" );
ITEM.GetNWString			= ITEM.GetNWVar;			IF.Items:ProtectKey( "GetNWString" );
ITEM.GetNWVector			= ITEM.GetNWVar;			IF.Items:ProtectKey( "GetNWVector" );
ITEM.GetNWInv				= ITEM.GetNWInventory;		IF.Items:ProtectKey( "GetNWInv" );


if SERVER then




--[[
* SERVER
* Internal
* Protected

Sends a networked var to the given player.
We'll tell the clients to set the var to nil if the networked var:
	Hasn't been set
	Was set to nil
	Hasn't been set to something other than the default yet
Otherwise we'll tell the clients to set the var to what we changed.
	
strName is the name of a networked var to send.
plTo is an optional player to send to.
	If this is nil, we will send the networked var to everybody (or to the owner if the item is private).

true is returned if the networked var was sent to the requested player.
	If we tried to send to everybody, true is returned if the networked var was successfully sent to all players.
false is returned otherwise.
]]--
function ITEM:SendNWVar( strName, plTo )
	local plOwner = self:GetOwner();
	if		plOwner	!= nil then		plTo = plOwner;
	elseif	plTo	== nil then		return IF.Util:RunForEachPlayer( function( pl ) return self:SendNWVar( strName, pl ) end );
	end

	local nwvar = self.NWVarsByName[strName];
	local varid = nwvar.ID - 128;
	local type = nwvar.Type;
	local val = nil;
	
	if self.NWVars then val = self.NWVars[strName] end
	
	if val == nil then
		IF.Items:IFIStart( plTo, IFI_MSG_SETNIL, self:GetID() );
		IF.Items:IFIChar( varid );
		IF.Items:IFIEnd();
	elseif type == 1 then
		if IF.Util:IsInRange( val, -128, 127 ) then						--Send as a char
			IF.Items:IFIStart( plTo, IFI_MSG_SETCHAR, self:GetID() );
			IF.Items:IFIChar( varid );
			IF.Items:IFIChar( val );
			IF.Items:IFIEnd();
		elseif IF.Util:IsInRange( val, 0, 255 ) then					--Send as an unsigned char
			IF.Items:IFIStart( plTo, IFI_MSG_SETUCHAR, self:GetID() );
			IF.Items:IFIChar( varid );
			IF.Items:IFIChar( val - 128 );
			IF.Items:IFIEnd();
		elseif IF.Util:IsInRange( val, -32768, 32767 ) then				--Send as a short
			IF.Items:IFIStart( plTo, IFI_MSG_SETSHORT, self:GetID() );
			IF.Items:IFIChar( varid );
			IF.Items:IFIShort( val );
			IF.Items:IFIEnd();
		elseif IF.Util:IsInRange( val, 0, 65535 ) then					--Send as an unsigned short
			IF.Items:IFIStart( plTo, IFI_MSG_SETUSHORT, self:GetID() );
			IF.Items:IFIChar( varid );
			IF.Items:IFIShort( val - 32768 );
			IF.Items:IFIEnd();
		elseif IF.Util:IsInRange( val, -2147483648, 2147483647 ) then	--Send as a long
			IF.Items:IFIStart( plTo, IFI_MSG_SETLONG, self:GetID() );
			IF.Items:IFIChar( varid );
			IF.Items:IFILong( val );
			IF.Items:IFIEnd();
		elseif IF.Util:IsInRange( val, 0, 4294967295 ) then				--Send as an unsigned long
			IF.Items:IFIStart( plTo, IFI_MSG_SETULONG, self:GetID() );
			IF.Items:IFIChar( varid );
			IF.Items:IFILong( val - 2147483648 );
			IF.Items:IFIEnd();
		else
			--TODO better error handling here
			self:Error( "Trying to send NWVar \""..strName.."\" failed - the number "..tostring( val ).." is too large to be sent!\n" );
			
			--It's an invalid number to send
			self:SetNWVar( strName, 0 );
			IF.Items:IFIStart( plTo, IFI_MSG_SETCHAR, self:GetID() );
			IF.Items:IFIChar( varid );
			IF.Items:IFIChar( 0 );
			IF.Items:IFIEnd();
		end
	elseif type == 3 then
		IF.Items:IFIStart( plTo, IFI_MSG_SETBOOL, self:GetID() );
		IF.Items:IFIChar( varid );
		IF.Items:IFIBool( val );
		IF.Items:IFIEnd();
	elseif type == 2 then
		IF.Items:IFIStart( plTo, IFI_MSG_SETFLOAT, self:GetID() );
		IF.Items:IFIChar( varid );
		IF.Items:IFIFloat( val );
		IF.Items:IFIEnd();
	elseif type == 4 then
		IF.Items:IFIStart( plTo, IFI_MSG_SETSTRING, self:GetID() );
		IF.Items:IFIChar( varid );
		IF.Items:IFIString( val );
		IF.Items:IFIEnd();
	elseif type == 6 then
		IF.Items:IFIStart( plTo, IFI_MSG_SETVECTOR, self:GetID() );
		IF.Items:IFIChar( varid );
		IF.Items:IFIVector( val );
		IF.Items:IFIEnd();
	elseif type == 7 then
		IF.Items:IFIStart( plTo, IFI_MSG_SETANGLE, self:GetID() );
		IF.Items:IFIChar( varid );
		IF.Items:IFIAngle( val );
		IF.Items:IFIEnd();
	elseif type == 8 then
		IF.Items:IFIStart( plTo, IFI_MSG_SETITEM, self:GetID() );
		IF.Items:IFIChar( varid );
		IF.Items:IFIShort( val:GetID() - 32768 );
		IF.Items:IFIEnd();
	elseif type == 9 then
		IF.Items:IFIStart( plTo, IFI_MSG_SETINV, self:GetID() );
		IF.Items:IFIChar( varid );
		IF.Items:IFIShort( val:GetID() - 32768 );
		IF.Items:IFIEnd();
	elseif type == 5 then
		IF.Items:IFIStart( plTo, IFI_MSG_SETENTITY, self:GetID() );
		IF.Items:IFIChar( varid );
		IF.Items:IFIEntity( val );
		IF.Items:IFIEnd();
	elseif type == 10 then
		IF.Items:IFIStart( plTo, IFI_MSG_SETCOLOR, self:GetID() );
		IF.Items:IFIChar( varid );
		IF.Items:IFIChar( val.r - 128 );
		IF.Items:IFIChar( val.g - 128 );
		IF.Items:IFIChar( val.b - 128 );
		IF.Items:IFIChar( val.a - 128 );
		IF.Items:IFIEnd();
	end
end
IF.Items:ProtectKey( "SendNWVar" );




else




--[[
* CLIENT
* Internal
* Protected

Whenever a networked var is received from the server, this function is called.
]]--
function ITEM:ReceiveNWVar( strName, vVal )
	local nwvar = self.NWVarsByName[strName];
	if !nwvar			then return self:Error( "Couldn't receive network var from server. Network var by name \""..strName.."\" doesn't exist clientside.\n" ) end
	
	if nwvar.Predicted then
		if !self.NWVarsThisTick then self.NWVarsThisTick = {} end
		self.NWVarsThisTick[strName] = vVal;
	else
		self:SetNWVar( strName, vVal );
	end
end
IF.Items:ProtectKey( "ReceiveNWVar" );




end