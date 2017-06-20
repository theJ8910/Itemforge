--[[
base_item
SERVER

base_item is the default item. All items except base_item inherit from this item-type.
NOTE: The item type is the name of the folder it is in (this is base_item/init.lua, so this item's type is "base_item")
]]--

AddCSLuaFile( "shared.lua" );
AddCSLuaFile( "cl_init.lua" );
AddCSLuaFile( "health.lua" );
AddCSLuaFile( "stacks.lua" );
AddCSLuaFile( "weight.lua" );
AddCSLuaFile( "nwvars.lua" );
AddCSLuaFile( "timers.lua" );
AddCSLuaFile( "sounds.lua" );
AddCSLuaFile( "events_shared.lua" );
AddCSLuaFile( "events_client.lua" );

include( "shared.lua" );
include( "events_server.lua" );

ITEM.GibEffect	= "auto";								--What kind of gibs does this item leave behind if it's destroyed while in the world? Can be "none" for no gibs, "auto" to use the model's default gibs, "metal" to break into metal pieces, or "wood" to break into wood pieces.

--Don't modify/override these. They're either set automatically or don't need to be changed.
local vZero = Vector( 0, 0, 0 );
local aZero = Angle( 0, 0, 0 );

--[[
* SERVER
* Protected
* Internal

This doesn't actually set the NetOwner, but it will publicize or privitize the item.

plLastOwner should be the player who was NetOwner of this item previously.
	This can be a player, or nil.
	Doing item:GetNetOwner() or getting the NetOwner of the old container should suffice in most cases.
plNewOwner should be the player who now owns this item.
	This can be a player, or nil.
	The NetOwner of an inventory the item is going in, or nil should work in most cases.
]]--
function ITEM:SetOwner( plLastOwner, plNewOwner )
	if plNewOwner != nil then
		if plLastOwner == nil then
			IF.Items:RemoveClientsideOnAllBut( self:GetID(), plNewOwner );
		
		elseif plLastOwner != plNewOwner then
			IF.Items:RemoveClientside( self:GetID(), plLastOwner );
			IF.Items:SendFullUpdate( self:GetID(), plNewOwner );
			
			for _, i in pairs( self.Inventories ) do
				if i.Inv:CanNetwork( plNewOwner ) then i.Inv:ConnectItem( self, plNewOwner ); end
			end
		end
	
	elseif plLastOwner != nil then
		for k,v in pairs( player.GetAll() ) do
			if v != plLastOwner then
				IF.Items:SendFullUpdate( self:GetID(), v );
				for _, i in pairs( self.Inventories ) do
					if i.Inv:CanNetwork( v ) then i.Inv:ConnectItem( self, v ); end
				end
			end
		end
	end
end

--[[
* SERVER
* Protected

This function returns true if this item can send information about itself to a given player.
It will return true in two case:
	This item's NetOwner is nil (this item is public)
	This item's NetOwner is the same as the given player (this is a private item "owned" by this player)
]]--
function ITEM:CanNetwork( pl )
	local plOwner = self:GetOwner();
	return plOwner == nil || plOwner == pl;
end
IF.Items:ProtectKey( "CanNetwork" );

--[[
* SERVER
* Protected

Run this function to use the item.
It will trigger the OnUse event in the item.

This function will only be run serverside if the item is used while on the ground (with the "e" key).
The function will be run clientside and then serverside in most other cases.
The server should have the final say on if something can be used or not though.

false is returned in three cases:
	The given player is invalid
	The given player is currently unable to use this item (CanPlayerInteract returned false)
	The item cannot be used (OnUse returned false).
Otherwise, true is returned.

TODO: Possibly have the item used by something other than a player
]]--
function ITEM:Use( pl )
	if !IF.Util:IsPlayer( pl ) || !self:Event( "CanPlayerInteract", false, pl ) then return false end
	
	if !self:Event( "OnUse", true, pl ) then
		pl:PrintMessage( HUD_PRINTTALK, "I can't use this!" );
		IF.Vox:PlayRandomFailure( pl );
		return false;
	end
	
	return true;
end
IF.Items:ProtectKey( "Use" );

--[[
* SERVER
* Protected
* Internal

Protected start touch event.
World Merge attempts are triggered here.
After an _unsuccessful_ world merge attempt, this calls the overridable OnStartTouch event.

eEntity should be the entity the item is using while it's in the world (the same as self:GetEntity()).
eActivator is the entity that has been bumped into by our item's entity.
touchItem will usually be nil, but if it isn't, that means this item has touched another item in the world.
]]--
function ITEM:OnStartTouchSafe( eEntity, eActivator, touchItem )
	--[[
	If this item touched an item of the same type and both items' events approve a world merge
	then we'll merge the two items here. We can only merge the whole stack or nothing (otherwise we'd constantly be swapping items between piles back and forth).
	If it works, we stop here. Otherwise, we call the OnStartTouch event.
	]]--
	if touchItem && self:GetType() == touchItem:GetType() && self:Event( "CanWorldMerge", false, touchItem ) && touchItem:Event( "CanWorldMerge", false, self ) && self:Merge( touchItem, false ) then
		return;
	end
	
	--If a merger isn't possible we pass the touch onto the item's OnStartTouch and let it handle it.
	self:Event( "OnStartTouch", nil, eEntity, eActivator, touchItem );
end
IF.Items:ProtectKey( "OnStartTouchSafe" );

--[[
* SERVER
* Protected

Changes the item's world model.

strModel should be the filepath of the model you want to use.

true is returned if the model was changed.
false is returned if this cannot be done for some reason.
]]--
function ITEM:SetWorldModel( strModel )
	if !strModel then return self:Error( "Couldn't change world model. No model was given.\n" ) end
	
	local strOldModel = self:GetWorldModel();
	if strModel == strOldModel then return true end
	
	self:SetNWString( "WorldModel", strModel );
	
	--If we're in the world when the model changes...
	local eEntity = self:GetEntity();
	if eEntity then
		local vPos = eEntity:GetPos();
		local aAng = eEntity:GetAngles();
		
		--We must respawn the entity. This means taking the item out of the world and returning it to where it was. In the case of a failure, false is returned and the world model is reset.
		if !self:ToVoid() || !self:ToWorld( vPos, aAng ) then self:SetNWString( "WorldModel", strOldModel ); return false end
	end
	
	return true;
end

--[[
* SERVER
* Protected

Changes this item's view model.

strModel should be the filepath of the model you want to use.

TODO actually change visible viewmodel.
]]--
function ITEM:SetViewModel( strModel )
	if !strModel then return self:Error( "Couldn't change view model. No model was given.\n" ) end
	self:SetNWString( "ViewModel", strModel );
	
	return true;
end
IF.Items:ProtectKey( "SetViewModel" );

--[[
* SERVER
* Protected

Sets the item's gib effect to the given string.

strGibEffect should be the gib effect you want to use.
	See ITEM.GibEffect at the top of this file for a list of valid gib effects.
]]--
function ITEM:SetGibEffect( strGibEffect )
	self.GibEffect = strGibEffect;
end
IF.Items:ProtectKey( "SetGibEffect" );

--[[
* SERVER
* Protected

Returns the name of the item's gib effect.
]]--
function ITEM:GetGibEffect()
	return self.GibEffect
end
IF.Items:ProtectKey( "GetGibEffect" );

--[[
* SERVER
* Protected

Sends all of the necessary item data to a player.
Triggers the "OnSendFullUpdate" event.

pl is the player to send the update to.
]]--
function ITEM:SendFullUpdate( pl )
	
	--Send networked vars. We'll only send networked vars that have changed (NWVars that have been set to something other than the default value)
	if self.NWVars then
		for k, v in pairs( self.NWVars ) do
			local var = self.NWVarsByName[k];
			
			--This shouldn't happen, but just in case.
			if !var then self:Error( "Couldn't send networked var \""..k.."\" via full update. This networked var has not been defined in the itemtype with IF.Items:CreateNWVar. This shouldn't be happening.\n" ); end
			
			if !var.HoldFromUpdate then self:SendNWVar( k, pl ); end
		end
	end
	
	local container, cslot = self:GetContainer();
	if container then self:ToInventory( container, cslot, pl, true ); end
	
	self:Event( "OnSendFullUpdate", nil, pl );
end
IF.Items:ProtectKey( "SendFullUpdate" );

--[[
* SERVER
* Protected

Runs every time the server ticks.
]]--
function ITEM:Tick()
	if !self.NWVars then return false end
	
	--Send predicted network vars.
	for k, v in pairs( self.NWVars ) do
		local var = self.NWVarsByName[k];
		--This shouldn't happen, but just in case.
		if !var then return self:Error( "Couldn't send networked var \""..k.."\" via tick. This networked var has not been defined in the itemtype with IF.Items:CreateNWVar. This shouldn't be happening.\n" ) end
		
		if var.Predicted then
			--Create the "Last Tick" table if it hasn't been created yet
			if !self.NWVarsLastTick then self.NWVarsLastTick = {}; end
			
			--Only send networked vars that have changed since the last tick
			if self.NWVars[k] != self.NWVarsLastTick[k] then
				self.NWVarsLastTick[k] = self.NWVars[k];
				self:SendNWVar( k );
			end
		end
	end
	
	self:Event( "OnTick" );
end
IF.Items:ProtectKey( "Tick" );

--[[
* SERVER

Removes the item and creates an explosion where it was at.

TODO: If the item is in an inventory, explosion spreads out based on factors such as
      open / closed inventories (open footlocker vs closed footlocker),
	  damage absorption (metal safe vs paper bag),
	  items in inventory (if slots are limited, spread evenly amonst slots)

iExplosionDamage should be the amount of damage the explosion should do.
iRadius is an optional value. If iRadius is:
	a number, the explosion will not damage things outside a sphere of this radius.
	nil / not given, the radius is automatically assigned based on damage.

eWhoTriggered is an optional player / entity to credit the kill to.
]]--
function ITEM:Explode( iExplosionDamage, iRadius, eWhoTriggered )

	local eExplode = ents.Create( "env_explosion" )
	eExplode:SetPos( self:GetPos() );
	eExplode:SetOwner( eWho );
	eExplode:SetKeyValue( "iMagnitude", tostring( iExplosionDamage ) );
	if IF.Util:IsNumber( iRadius ) then eExplode:SetKeyValue( "iRadiusOverride", tostring( iRadius ) ) end
	eExplode:Spawn();
	
	self:Remove();

	eExplode:Fire( "Explode", 0, 0 );
end

--[[
* SERVER
* Protected
* WIRE

Triggers a Wire output on this item. This will not work if Wiremod is not installed.
Whenever a wire output is triggered, it will send the given value to anything that happened to be wired to that output.

strOutputName is the name of the output to trigger (ex: "Energy", "DetectedPlayer", etc)
vValue is what value you want to output.
	Most wire inputs take numbers, so I recommend using a number for value.
	An on/off type output usually uses 0 for off and 1 for on.
	vValue can be any kind of data you want - bools, tables, numbers, vectors, angles, whatever. Just keep in mind that it has to be understood by the other side.

Returns false if wiremod is not supported on this server, or if the item is not in the world.
Returns true if the Wire output was triggered successfully.
]]--
function ITEM:WireOutput( strOutputName, vValue )
	--This only works if we are in the world and have wire capabilities
	local eEntity = self:GetEntity();
	if !eEntity || !eEntity.IsWire then return false end

	Wire_TriggerOutput( eEntity, strOutputName, vValue );
	return true;
end
IF.Items:ProtectKey( "WireOutput" );

--[[
* SERVER
* Protected

Sends a networked command by name with the supplied arguments
Serverside, this sends usermessages.

strName should be the name of the network command to send.
	The network command should be server-to-client.
pl can be a player, a recipient filter, or 'nil' to send to all players (clients).
	If nil is given for player, and the item is in a private inventory, then the command is sent to that player only.
]]--
function ITEM:SendNWCommand( strName, pl, ... )
	local command = self.NWCommandsByName[strName];
	if command == nil				then return self:Error( "Couldn't send networked command \""..strName.."\" - there is no NWCommand by this name!\n" ) end
	if command.Hook != nil			then return self:Error( "Couldn't send networked command \""..strName.."\" - this command cannot be sent serverside. It has a hook, meaning this command is recieved serverside, not sent.\n" ) end
	
	if pl != nil then	if !IF.Util:IsPlayer( pl )  then return self:Error( "Couldn't send networked command - The player to send \""..strName.."\" to isn't a valid player!\n" ); end
	else
		local bAllSuccess = true;
		for k, v in pairs( player.GetAll() ) do
			if !self:SendNWCommand( strName, v, unpack( arg ) ) then
				bAllSuccess = false;
			end
		end
		return bAllSuccess;
	end
	
	IF.Items:IFIStart( pl or self:GetOwner(), IFI_MSG_SV2CLCOMMAND, self:GetID() );
	IF.Items:IFIChar( command.ID - 128 );
	
	--If our command sends data, then we need to send the appropriate type of data.
	for i = 1, table.maxn( command.Datatypes ) do
		local v = command.Datatypes[i];
		
		if v == 1 then
			IF.Items:IFILong( math.floor( arg[i] or 0 ) );
		elseif v == 2 then
			IF.Items:IFIChar( math.floor( arg[i] or 0 ) );
		elseif v == 3 then
			IF.Items:IFIShort( math.floor( arg[i] or 0 ) );
		elseif v == 4 then
			IF.Items:IFIFloat( arg[i] or 0 );
		elseif v == 5 then
			IF.Items:IFIBool( arg[i] or false );
		elseif v == 6 then
			IF.Items:IFIString( arg[i] or "" );
		elseif v == 7 then
			IF.Items:IFIEntity( arg[i] );
		elseif v == 8 then
			IF.Items:IFIVector( arg[i] or vZero );
		elseif v == 9 then
			IF.Items:IFIAngle( arg[i] or aZero );
		elseif v == 10 || v == 11 then
			if arg[i] != nil && arg[i]:IsValid() then	IF.Items:IFIShort( arg[i]:GetID() - 32768 );
			else										IF.Items:IFIShort( 0 );
			end
		elseif v == 12 then
			if arg[i] != nil then						IF.Items:IFIChar( math.floor( arg[i] ) - 128);
			else										IF.Items:IFIChar( 0 );
			end
		elseif v == 13 then
			if arg[i] != nil then						IF.Items:IFILong( math.floor( arg[i] ) - 2147483648 );
			else										IF.Items:IFILong( 0 );
			end
		elseif v == 14 then
			if arg[i] != nil then						IF.Items:IFIShort( math.floor( arg[i] ) - 32768 );
			else										IF.Items:IFIShort( 0 );
			end
		elseif v == 0 then
			IF.Items:IFIChar( 0 );
		end
	end
	
	IF.Items:IFIEnd();
end
IF.Items:ProtectKey( "SendNWCommand" );

local NIL = "%%00";		--If a command isn't given, this is substituted. It means we received nil (nothing).

--[[
* SERVER
* Internal
* Protected

This function is called automatically, whenever a networked command from a client is received.

plFrom is the player who the networked command was received from.
iCommandID is the ID of the command recieved from the server
args will be a table of arguments (should be converted to the correct datatype as specified in CreateNWCommand).

There's no need to override this, we'll call the hook the command is associated if there is one.
]]--
function ITEM:ReceiveNWCommand( plFrom, iCommandID, args )
	local command = self.NWCommandsByID[iCommandID];
	
	if command == nil			then return self:Error( "Couldn't find a NWCommand with ID "..iCommandID..". Make sure commands are created in the same order BOTH serverside and clientside.\n" ) end
	if command.Hook == nil		then return self:Error( "Command \""..command.Name.."\" was received, but there is no Hook to run!\n" ) end
	
	--If our command sends data, then we need to receive the appropriate type of data.
	--We'll pass this onto the hook function.
	local hookArgs = {};
	
	for i = 1, table.maxn( command.Datatypes ) do
		local v = command.Datatypes[i];
		local currentArg = args[i];

		if currentArg == NIL then
			hookArgs[i] = nil;
		elseif v == 1 || v == 2 || v == 3 || v == 4 || v == 12 || v == 13 || v == 14 then
			hookArgs[i] = tonumber( currentArg );
		elseif v == 5 then
			if currentArg == "t" then	hookArgs[i] = true;
			else						hookArgs[i] = false;
			end
		elseif v == 6 then				hookArgs[i] = string.gsub( currentArg, "%%20", " " );
		elseif v == 7 then				hookArgs[i] = ents.GetByIndex( currentArg );
		elseif v == 8 then
			local strBreak = string.Explode( ",", currentArg );
			
			hookArgs[i] = Vector( tonumber( strBreak[1] ), tonumber( strBreak[2] ), tonumber( strBreak[3] ) );
		elseif v == 9 then
			local strBreak = string.Explode( ",", currentArg );
			
			hookArgs[i] = Angle( tonumber( strBreak[1] ), tonumber( strBreak[2] ), tonumber( strBreak[3] ) );
		elseif v == 10 then
			local iItemID = tonumber( currentArg );
			hookArgs[i] = IF.Items:Get( iItemID );
		elseif v == 11 then
			local iItemID = tonumber( currentArg );
			hookArgs[i] = IF.Inv:Get( iItemID );
		end
	end
	command.Hook( self, plFrom, unpack( hookArgs ) );
end
IF.Items:ProtectKey( "ReceiveNWCommand" );

--[[
* SERVER
* Protected

Runs when a client requests to send this item to the world somewhere.

pl is the player who tried to send the item to the world.
vFrom and vTo are two Vector()s representing positions in the world.
	Basically, the item is first dropped at vFrom, and then instantaneously slides from vFrom to vTo in a straight line.
	Ideally, the item will make it to vTo (where the player intended to drop the item).
	However, if the path is obstructed, it may end up somewhere inbetween vFrom and vTo instead,
	and will be stuck at vFrom in the worst case (meaning it was collding with something when it appeared at vFrom).
]]--
function ITEM:PlayerSendToWorld( pl, vFrom, vTo )
	if !self:Event( "CanPlayerInteract", false, pl ) then return false end
	
	local eEntity = self:ToWorld( vFrom );
	
	local tr		=	{};
	tr.start		=	vFrom;
	tr.endpos		=	vFrom + 64 * ( ( vTo - vFrom ):Normalize() );
	tr.filter		=	{ pl, pl:GetViewEntity(), eEntity };
	traceRes		=	util.TraceEntity( tr, eEntity );
	
	if traceRes.HitPos:Distance( pl:GetPos() ) > 200 then return false end
	
	self:ToWorld( traceRes.HitPos );
end
IF.Items:ProtectKey( "PlayerSendToWorld" );

--[[
* SERVER
* Protected

Runs when a client requests to hold an item.

pl is the player who requested to hold this item.
]]--
function ITEM:PlayerHold( pl )
	if !self:Event( "CanPlayerInteract", false, pl ) then return false end
	self:Hold(pl);
end
IF.Items:ProtectKey( "PlayerHold" );

--[[
* SERVER
* Protected

Runs when a client requests to merge this stack and another stack

pl is the player trying to merge the two stacks.
otherItem is the stack that the player wants to merge this stack with.
]]--
function ITEM:PlayerMerge( pl, otherItem )
	if !self:Event( "CanPlayerInteract", false, pl ) || !otherItem:Event( "CanPlayerInteract", false, pl ) then return false end
	self:Merge( otherItem );
end
IF.Items:ProtectKey( "PlayerMerge" );

--[[
* SERVER
* Protected

Runs when a client requests to split this stack.

pl is the player who wants to split the stack.
iAmt is the number of items the player wants to split off from this stack.
]]--
function ITEM:PlayerSplit( pl, iAmt )
	if !self:Event( "CanPlayerInteract", false, pl ) || !self:Event( "CanPlayerSplit", true, pl ) then return false end
	return self:Split( iAmt );
end
IF.Items:ProtectKey( "PlayerSplit" );

--[[
* SERVER
* Internal
* Protected
* Event

There should be no reason for a scripter to call this directly.
Runs if a certain player was supposed to hold the item as a weapon, but:
	It was picked up by the wrong player.
	The player it was intended for left the game.

I'm having it send the item to the void in the case of one of these rare failures until I can find a better solution to this problem.
]]--
function ITEM:HoldFailed()
	self:ToVoid();
end
IF.Items:ProtectKey( "HoldFailed" );

--Place networked commands here in the same order as in cl_init.lua.
IF.Items:CreateNWCommand( ITEM, "ToInventory",				nil,															{ "inventory", "short" }				);
IF.Items:CreateNWCommand( ITEM, "RemoveFromInventory",		nil,															{ "bool", "inventory" }					);
IF.Items:CreateNWCommand( ITEM, "TransferInventory",		nil,															{ "inventory", "inventory", "short" }	);
IF.Items:CreateNWCommand( ITEM, "TransferSlot",				nil,															{ "inventory", "short", "short" }		);
IF.Items:CreateNWCommand( ITEM, "PlayerUse",				function( self, ... ) self:Use( ... )					end												);
IF.Items:CreateNWCommand( ITEM, "PlayerHold",				function( self, ... ) self:PlayerHold( ... )			end												);
IF.Items:CreateNWCommand( ITEM, "PlayerSendToInventory",	function( self, ... ) self:PlayerSendToInventory( ... )	end,	{ "inventory", "short" }				);
IF.Items:CreateNWCommand( ITEM, "PlayerSendToWorld",		function( self, ... ) self:PlayerSendToWorld( ... )		end,	{ "vector", "vector" }					);
IF.Items:CreateNWCommand( ITEM, "PlayerMerge",				function( self, ... ) self:PlayerMerge( ... )			end,	{ "item" }								);
IF.Items:CreateNWCommand( ITEM, "PlayerSplit",				function( self, ... ) self:PlayerSplit( ... )			end,	{ "int" }								);