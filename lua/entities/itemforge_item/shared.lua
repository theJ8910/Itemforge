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
		self:SetNWInt("i",item:GetID());
		
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
		if CLIENT && !self:SetItem(IF.Items:Get(self.Entity:GetNWInt("i"))) then 
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
	
	self.IsWire=(WireVersion&&WireVersion>=843);
	if self.IsWire then self["BaseWireEntity"]=scripted_ents.Get("base_wire_entity"); end
end

--[[
May allow items to take advantage of this later
Every frame physics change it runs apparantly
]]--
function ENT:PhysicsUpdate()
end