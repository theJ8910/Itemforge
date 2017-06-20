--[[
itemforge_item
SERVER

This entity is an 'avatar' of an item. When on the ground, this entity represents that item.
]]--

AddCSLuaFile( "cl_init.lua" );
AddCSLuaFile( "shared.lua" );
include( "shared.lua" );

ENT.ExpectRemoval = false;

--[[
* SERVER

Remove this entity and tell it that this was expected to happen.
]]--
function ENT:ExpectedRemoval()
	if !self.ExpectRemoval then
		self.ExpectRemoval = true;
		self.Entity:Remove();
	end
end

--[[
* SERVER
* Event

Input run on our ent
]]--
function ENT:AcceptInput( strName, eActivator, eCaller, data )
	return self:GetItem():Event( "OnInput", false, false, self, strName, eActivator, eCaller, data ) == true;
end

--[[
* SERVER
* Event

Keyvalue is set on our ent
]]--
function ENT:KeyValue( strKey, strValue )	
	local item = self:GetItem();
	if !item then return end

	return item:Event( "OnKeyValue", nil, false, self, strKey, strValue );
end

--[[
* SERVER
* Event

TODO next update may add ENT:StartTouch/Touch/EndTouch clientside
]]--
function ENT:StartTouch( eActivator )
	return self:GetItem():OnStartTouchSafe( self, eActivator, IF.Items:GetEntItem( eActivator ) );
end

--[[
* SERVER
* Event

]]--
function ENT:Touch( eActivator )
	return self:GetItem():Event( "OnTouch", nil, self, eActivator, IF.Items:GetEntItem( eActivator ) );
end

--[[
* SERVER
* Event

]]--
function ENT:EndTouch( eActivator )
	return self:GetItem():Event( "OnEndTouch", nil, self, eActivator, IF.Items:GetEntItem( eActivator ) );
end

--[[
* SERVER
* Event

We need to remove the item this entity is associated with if the removal wasn't expected (like if the remover toolgun was used on the entity, or it fell into something that removes entities)
Or not remove the item this entity was associated with if the removal was expected (like if the item was just being taken out of the world and put into a container or something)
]]--
function ENT:OnRemove()
	if self.IsWire then self["BaseWireEntity"].OnRemove( self ); end	--WIRE
	
	--This entity is being removed.
	self.BeingRemoved = true;
	
	--Clear the one-way connection between entity and item
	local item = self:GetItem();
	if !item then return end		--We didn't have an item set anyway. We can stop here.
	self:SetItem( nil );
		
	--[[
	Here's a long winded version of the condition for item removal below:
	This entity wasn't expecting to be removed (or in other words, this entity just got remover-gunned or something).
	This entity was carrying an item, and the item is still valid
	The item acknowledges that we are it's entity (or in other words, the item confirmed that it's still using this entity)
	That leaves us only once choice - remove the item being portrayed by this entity.
	If we didn't do this, the item would just float around in the void after it's entity got removed! That's analagous to a memory leak - not cool.
	]]--
	if !self.ExpectRemoval && item:GetEntity() == self.Entity then
		--DEBUG
		Msg( "Itemforge Item Entity (Ent ID "..self.Entity:EntIndex()..", Item "..item:GetID().."): Unexpected removal, removing item too.\n" );
		item:Remove();
	end
end

--[[
* SERVER
* Event

Our ent was used (with E probably) - we'll tell our item that it was used, SERVERSIDE.
There is no way to detect if an entity is used clientside currently.
]]--
function ENT:Use( eActivator, eCaller )
	if eActivator:IsPlayer() then
		self:GetItem():Use( eActivator );
	end
end

--[[
* SERVER
* Event

Our ent was damaged! Hurt the item!
]]--
function ENT:OnTakeDamage( dmg )
	local item = self:GetItem();
	if !item then
		self.Entity:TakePhysicsDamage( dmg );
		return;
	end
	
	return item:Event( "OnEntTakeDamage", nil, self.Entity, dmg );
end

--[[
* SERVER
* Event

Runs when a collision occurs
]]--
function ENT:PhysicsCollide( CollisionData, HitPhysObj )	
	return self:GetItem():Event( "OnPhysicsCollide", nil, self.Entity, CollisionData, HitPhysObj );
end

--[[
* SERVER
* WIRE

Run when a wire input receives some data
]]--
function ENT:TriggerInput( strInputName, vValue )	
	return self:GetItem():Event( "OnWireInput" ,nil, self.Entity, strInputName, vValue );
end

--[[
* SERVER
* WIRE

May allow items to take advantage of this later
Use GetNetworked* functions (entity) to restore data from a save-game
]]--
function ENT:OnRestore()
	if self.IsWire then return self["BaseWireEntity"].OnRestore(self); end
end

--[[
* SERVER
* WIRE

I don't have a clue what this is, I'm guessing it's something related to the advanced duplicator?
It's in the base wire entity though so I figure it's necessary to include it.
]]--
function ENT:BuildDupeInfo()
	if self.IsWire then return self["BaseWireEntity"].BuildDupeInfo(self); end
end

--[[
* SERVER
* WIRE

]]--
function ENT:ApplyDupeInfo(pl,ent,info,GetEntByID)
	if self.IsWire then return self["BaseWireEntity"].ApplyDupeInfo(self,pl,ent,info,GetEntByID); end
end

--[[
* SERVER
* WIRE

]]--
function ENT:PreEntityCopy()
	if self.IsWire then return self["BaseWireEntity"].PreEntityCopy(self); end
end

--[[
* SERVER
* WIRE
]]--
function ENT:PostEntityPaste(Player,Ent,CreatedEntities)
	if self.IsWire then return self["BaseWireEntity"].PostEntityPaste(self,Player,Ent,CreatedEntities); end
end

--[[
* SERVER
* Event

I definitely will not be allowing items to take advantage of this later unless explictly asked to by someone
]]--
--[[
function ENT:PhysicsSimulate( physObj, deltaTime )
end
]]--