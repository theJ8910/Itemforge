--[[
itemforge_item
SERVER

This entity is an 'avatar' of an item. When on the ground, this entity represents that item.
]]--
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include("shared.lua")
ENT.ExpectRemoval=false;

--Remove this entity and tell it that this was expected to happen.
function ENT:ExpectedRemoval()
	if !self.ExpectRemoval then
		self.ExpectRemoval=true;
		self.Entity:Remove();
	end
end

--Input run on our ent
function ENT:AcceptInput(name,activator,caller,data)
	local item=self:GetItem();
	if !item then return false end
	
	local s,r=pcall(item.OnInput,item,false,self.Entity,name,activator,caller,data);
	if !s then
		ErrorNoHalt(r.."\n");
		return false;
	else
		return r==true;
	end
end

--Keyvalue is set on our ent
function ENT:KeyValue(key,value)
	local item=self:GetItem();
	if !item then return false end
	
	local s,r=pcall(item.OnKeyValue,item,false,self.Entity,key,value);
	if !s then ErrorNoHalt(r.."\n") end
	
	return true;
end

--TODO next update may add ENT:StartTouch/Touch/EndTouch clientside
function ENT:StartTouch(activator)
	local item=self:GetItem();
	if !item then return false; end
	
	local touchItem=false;
	if activator:GetClass()=="itemforge_item" then
		touchItem=activator:GetItem();
	end
	if !touchItem || !touchItem:IsValid() then touchItem=nil; end
	
	item:OnStartTouchSafe(self.Entity,activator,touchItem);
	
	return true;
end

function ENT:Touch(activator)
	local item=self:GetItem();
	if !item then return false; end
	
	local touchItem=false;
	if activator:GetClass()=="itemforge_item" then
		touchItem=activator:GetItem();
	end
	if !touchItem || !touchItem:IsValid() then touchItem=nil; end
	
	local s,r=pcall(item.OnTouch,item,self.Entity,activator,touchItem);
	if !s then ErrorNoHalt(r.."\n") end;
	
	return true;
end

function ENT:EndTouch(activator)
	local item=self:GetItem();
	if !item then return false; end
	
	local touchItem=false;
	if activator:GetClass()=="itemforge_item" then
		touchItem=activator:GetItem();
	end
	if !touchItem || !touchItem:IsValid() then touchItem=nil; end
	
	local s,r=pcall(item.OnEndTouch,item,self.Entity,activator,touchItem);
	if !s then ErrorNoHalt(r.."\n") end;
	
	return true;
end

--[[
We need to remove the item this entity is associated with if the removal wasn't expected (like if the remover toolgun was used on the entity, or it fell into something that removes entities)
Or not remove the item this entity was associated with if the removal was expected (like if the item was just being taken out of the world and put into a container or something)
]]--
function ENT:OnRemove()
	if self.IsWire then self["BaseWireEntity"].OnRemove(self); end	--WIRE
	
	--This entity is being removed.
	self.BeingRemoved=true;
	
	--Clear the one-way connection between entity and item
	local item=self:GetItem();
	if !item then return true end		--We didn't have an item set anyway. We can stop here.
	self.Item=nil;
	
	--[[
	Here's a long winded version of the condition for item removal below:
	This entity wasn't expecting to be removed (or in other words, this entity just got remover-gunned or something).
	This entity was carrying an item, and the item is still valid
	The item acknowledges that we are it's entity (or in other words, the item confirmed that it's still using this entity)
	That leaves us only once choice - remove the item being portrayed by this entity.
	If we didn't do this, the item would just float around in the void after it's entity got removed! That's analagous to a memory leak - not cool.
	]]--
	if !self.ExpectRemoval && item:GetEntity()==self.Entity then
		--DEBUG
		Msg("Itemforge Item Entity (Ent ID "..self.Entity:EntIndex()..", Item "..item:GetID().."): Unexpected removal, removing item too.\n");
		item:Remove();
	end
	
	return true;
end

--Our ent was used (with E probably) - we'll tell our item that it was used, SERVERSIDE. There is no way to detect if an entity is used clientside currently, however Itemforge offers a clientside Use() event for items. Clientside Use() is triggered when doing the Use() action on the item while in an inventory.
function ENT:Use(activator,caller)
	if activator:IsPlayer() then
		local item=self:GetItem();
		if !item then return false end
		item:Use(activator);
	end
end

--Our ent was damaged! Hurt the item!
function ENT:OnTakeDamage(dmg)
	local item=self:GetItem();
	if !item then
		self.Entity:TakePhysicsDamage(dmg);
		return false;
	end
	
	local s,r=pcall(item.OnEntTakeDamage,item,self.Entity,dmg);
	if !s then ErrorNoHalt(r.."\n") end;
	
	return true;
end

--Runs when a collision occurs
function ENT:PhysicsCollide(CollisionData,HitPhysObj)
	local item=self:GetItem();
	if !item then return false; end
	
	local s,r=pcall(item.OnPhysicsCollide,item,self.Entity,CollisionData,HitPhysObj);
	if !s then ErrorNoHalt(r.."\n"); end
	
	return true;
end

--Run when a wire input receives some data
--WIRE
function ENT:TriggerInput(inputName,value)
	local item=self:GetItem();
	if !item then return false end
	
	local s,r=pcall(item.OnWireInput,item,self.Entity,inputName,value);
	if !s then ErrorNoHalt(r.."\n"); end
end

--[[
May allow items to take advantage of this later
Use GetNetworked* functions (entity) to restore data from a save-game
WIRE
]]--
function ENT:OnRestore()
	if self.IsWire then return self["BaseWireEntity"].OnRestore(self); end
end

--[[
I don't have a clue what this is, I'm guessing it's something related to the advanced duplicator?
It's in the base wire entity though so I figure it's necessary to include it.
WIRE
]]--
function ENT:BuildDupeInfo()
	if self.IsWire then return self["BaseWireEntity"].BuildDupeInfo(self); end
end

--WIRE
function ENT:ApplyDupeInfo(pl,ent,info,GetEntByID)
	if self.IsWire then return self["BaseWireEntity"].ApplyDupeInfo(self,pl,ent,info,GetEntByID); end
end

--WIRE
function ENT:PreEntityCopy()
	if self.IsWire then return self["BaseWireEntity"].PreEntityCopy(self); end
end

--WIRE
function ENT:PostEntityPaste(Player,Ent,CreatedEntities)
	if self.IsWire then return self["BaseWireEntity"].PostEntityPaste(self,Player,Ent,CreatedEntities); end
end

--[[
--I definitely will not be allowing items to take advantage of this later unless explictly asked to by someone
function ENT:PhysicsSimulate(physObj,deltaTime)
end
]]--