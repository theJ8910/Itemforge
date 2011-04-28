--[[
itemforge_item
SHARED

This entity is an 'avatar' of an item. When on the ground, this entity represents that item.
]]--
ENT.Type 			= "anim";
ENT.Base 			= "base_anim";

ENT.PrintName		= "Itemforge Item"
ENT.Author			= "theJ89"
ENT.Contact			= "theJ89@charter.net"
ENT.Purpose			= "This entity is an 'avatar' of an item. When on the ground, this entity represents that item."
ENT.Instructions	= "This will be spawned by the game when an item is placed into the world. You can interact with it by using it, hitting it, etc."

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

ENT.BeingRemoved=false;

--WIRE
ENT.IsWire = false;
ENT.BaseWireEntity=nil;

--[[
* SHARED

Set up the first DT int to be the item ID.
This is good because when the entity gets created the item ID goes with it!
This pretty much allows us to link with the item ASAP, although it's still possible for late
linking to occur (such as when the item is created in the world, or when the item is created out
of the PVS of the player, and then the player discovers it).
]]--
function ENT:SetupDataTables()
	self:DTVar("Int",0,"i");
end

function ENT:Initialize()
	self:GiveWire();	--WIRE
end

function ENT:SetItem(item)
	if self:IsBeingRemoved() || !item then return false end
	
	self.Item=item;
	self:GiveWire();	--WIRE
	item:Event("OnEntityInit",nil,self.Entity);
	self.PrintName=item:Event("GetName","Itemforge Item");
	if SERVER then
		--WIRE
		if self.IsWire then
			--Set Debug Name, declare inputs and outputs
			self.WireDebugName=item:Event("GetWireDebugName","Itemforge Item");
			self.Inputs=item:Event("GetWireInputs",nil,self.Entity);
			self.Outputs=item:Event("GetWireOutputs",nil,self.Entity);	
		end
		
		--Tell clients what item we use
		self:SetDTInt("i",item:GetID());
		
		self:Spawn();
	else
		item:ToWorld(self.Entity:GetPos(),self.Entity:GetAngles(),self.Entity,false);
	end
end

--[[
Returns the item that is piloting this entity.
If the item has been removed, then nil is returned and self.Item is set to nil.
]]--
function ENT:GetItem()
	if !self.Item then
		if CLIENT && !self:SetItem(IF.Items:Get(self.Entity:GetDTInt("i"))) then 
			return nil;
		end
	elseif !self.Item:IsValid() then
		self.Item=nil;
	end
	return self.Item;
end

--Is the entity being removed right now?
function ENT:IsBeingRemoved()
	return self.BeingRemoved;
end

--WIRE
function ENT:GiveWire()
	--If we already have wire
	if self.IsWire then return true end
	
	local wvType = type(WireVersion);

	--Wiremod is such a mess. WireVersion can be a string, it can be a number, it can be a string with no numbers, it can be a string with something other than numbers... ugh...
	if wvType=="nil" then
		self.IsWire = false;
	elseif wvType=="number" then
		self.IsWire = WireVersion>=843;
	elseif wvType=="string" then
	    local delim = string.find(WireVersion,"[^%d]");

		local wv;
		if delim != nil then	wv = tonumber( string.sub( WireVersion, 1, delim-1 ) );
	    else					wv = tonumber( string.sub( WireVersion, 1, string.len( WireVersion ) ) );
		end

		if wv == nil then
			wv = 0;
		end

		self.IsWire = wv>=843;
	end
	
	if self.IsWire then self["BaseWireEntity"]=scripted_ents.Get("base_wire_entity"); end
end

--[[
May allow items to take advantage of this later
Every frame physics change it runs apparantly
]]--
function ENT:PhysicsUpdate()
end