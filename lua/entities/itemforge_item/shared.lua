--[[
itemforge_item
SHARED

This entity is an 'avatar' of an item. When on the ground, this entity represents that item.
]]--

ENT.Type 				= "anim";
ENT.Base 				= "base_anim";

ENT.PrintName			= "Itemforge Item";
ENT.Author				= "theJ89";
ENT.Contact				= "theJ89@charter.net";
ENT.Purpose				= "This entity is an 'avatar' of an item. When on the ground, this entity represents that item.";
ENT.Instructions		= "This will be spawned by the game when an item is placed into the world. You can interact with it by using it, hitting it, etc.";

ENT.Spawnable			= false;
ENT.AdminSpawnable		= false;

ENT.BeingRemoved		= false;

--WIRE
ENT.IsWire				= false;
ENT.BaseWireEntity		= nil;

--[[
* SHARED
* Event

Set up the first DT int to be the item ID.
Datatable variables are great because when the entity gets created the item ID goes with it!
This pretty much allows us to link the entity with the item ASAP on the client,
although it's still possible for late linking to occur (such as when the item is created in the world,
or when the item is created out of the PVS of the player, and then the player discovers it).
]]--
function ENT:SetupDataTables()
	self:DTVar( "Int", 0, "i" );
end

--[[
* SHARED
* Event
* WIRE

Gives the entity Wiremod functionality as soon as it's created.
]]--
function ENT:Initialize()
	if CLIENT then self:RegisterAsItemless() end
	self:GiveWire();
end

--[[
* SHARED

This function links the entity and the item that created it.

On the server, the item calls this function immediately after creating the entity,
	telling the entity that the provided item is it's item. Additionally, this triggers the Initialization.

On the client, the roles are reversed; the entity receives the item ID via a DataVar,
	and calls ToWorld() on the item clientside to communicate that this is it's world entity.
]]--
function ENT:SetItem( item )
	if item then
		self.Item = item;

		if SERVER then
		
			--WIRE
			self:GiveWire();

			item:Event( "OnEntityInit", nil, self.Entity );

			--WIRE
			if self.IsWire then
				--Set Debug Name, declare inputs and outputs
				self.WireDebugName	= item:Event( "GetWireDebugName", "Itemforge Item" );
				self.Inputs			= item:Event( "GetWireInputs", nil, self.Entity );
				self.Outputs		= item:Event( "GetWireOutputs", nil, self.Entity );	
			end
		
			--Tell clients what item we use
			self:SetDTInt( "i", item:GetID() );
		
			self:Spawn();
		else
			if !self.HasInitialized then
				--WIRE
				self:GiveWire();
			
				item:Event( "OnEntityInit", nil, self.Entity );
				self.HasInitialized = true;
			else
				self.BeingRemoved = false;
			end

			item:ToWorld( self.Entity:GetPos(), self.Entity:GetAngles(), self.Entity, false );
			self:UnregisterAsItemless();
			self:SwapToItemEvents();
		end
	else
		self.Item = nil;
		if CLIENT then
			self:RegisterAsItemless();
			self:SwapToItemlessEvents();
		end
	end
end

--[[
* SHARED

Returns the item that is piloting this entity.
]]--
function ENT:GetItem()
	if self.Item && !self.Item:IsValid() then
		self.Item = nil;
	end
	return self.Item;
end

--[[
* SHARED

Is the entity being removed right now?
Returns true if the entity is being removed,
or false if not.
]]--
function ENT:IsBeingRemoved()
	return self.BeingRemoved;
end

--[[
* SHARED
* WIRE

Attempts to give this entity Wiremod capabilities.
If successful, marks the item as being a wire entity.
]]--
function ENT:GiveWire()
	--If we already have wire
	if self.IsWire then return true end
	
	local wvType = type( WireVersion );

	--Wiremod is such a mess. WireVersion can be a string, it can be a number, it can be a string with no numbers, it can be a string with something other than numbers... ugh...
	if wvType == "nil" then
		self.IsWire = false;
	elseif wvType == "number" then
		self.IsWire = WireVersion >= 843;
	elseif wvType == "string" then
	    local iDelim = string.find( WireVersion, "[^%d]" );

		local wv;
		if iDelim != nil then	wv = tonumber( string.sub( WireVersion, 1, iDelim - 1 ) );
	    else					wv = tonumber( string.sub( WireVersion, 1, string.len( WireVersion ) ) );
		end

		if wv == nil then		wv = 0; end

		self.IsWire = ( wv >= 843 );
	end
	
	if self.IsWire then		self["BaseWireEntity"] = scripted_ents.Get( "base_wire_entity" )	end
end

--[[
* SHARED
* Event

May allow items to take advantage of this later
Every frame physics change it runs apparently
]]--
function ENT:PhysicsUpdate()
end