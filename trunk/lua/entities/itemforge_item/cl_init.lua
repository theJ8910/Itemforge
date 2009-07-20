--[[
itemforge_item
CLIENT

This entity is an 'avatar' of an item. When on the ground, this entity represents that item.
]]--
include("shared.lua")

language.Add("itemforge_item","Item");

function ENT:Draw()
	--If the item can't be found we'll just draw the model (no hook)
	local item=self:GetItem();
	if !item then
		self.Entity:DrawModel();
		return true;
	end
	
	item:Event("OnDraw3D",nil,self.Entity,false);
	
	if self.IsWire then Wire_Render(self.Entity) end	--WIRE
	
	return true;
end

function ENT:DrawTranslucent()
	--If the item can't be found we'll just draw the model (no hook)
	local item=self:GetItem();
	if !item then
		self.Entity:DrawModel();
		return true;
	end
	
	item:Event("OnDraw3D",nil,self.Entity,false);
	
	if self.IsWire then Wire_Render(self.Entity) end	--WIRE
	
	return true;
end

--Clear the item's association to this entity if it's removed clientside
function ENT:OnRemove()
	--We're removing the item right now, don't try to reaquire the item
	self.BeingRemoved=true;
	self.Entity:SetNWInt("i",0);
	
	--Clear the one-way connection between entity and item
	local item=self:GetItem();
	if !item then return true end
	self.Item=nil;
	
	--Clear the item's connection to the entity (the item "forgets" that this was it's entity)
	item:ToVoid(false,self.Entity,nil,false);
	
	return true;
end

--[[
The item this entity is supposed to be representing may not be known or exist clientside when the item is created. We'll search for it until we find it. 
THIS IS SHARED but we only use it clientside
]]--
function ENT:Think()
	if !self:GetItem() then return; end
	
	--WIRE
	if self.IsWire then self["BaseWireEntity"].Think(self); end
end