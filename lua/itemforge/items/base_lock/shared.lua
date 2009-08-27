--[[
base_lock
SHARED

base_lock is a base. That means that other items borrow code from this so they can be created easier.
Any item that inherits from this has everything this item has, and can override anything this item has.

The base_lock's purpose is to provide a variety of functions that all locks use, including (but not limited to):
	Attaching to and detaching from items and entities
	Locking and unlocking attached items and entities
	
Attention! Locks can be attached to other items, but the items the locks attach to must have these functions serverside:
	ITEM:OnAttachLock(item) - Having this function in your item allows locks to be attached. Runs when after a lock has been attached (this will be item).
	ITEM:Lock() - This should lock your item.
	ITEM:Unlock() - This should unlock your item.
	ITEM:IsLocked() - Returns true if the item is locked, false if it isn't (I personally recommend making this a shared function if you can)
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Base Lock";
ITEM.Description="This item is the base lock.\nThis item contains common functionality used by all locks.\n\nThis is not supposed to be spawned.";
ITEM.Base="item";
ITEM.WorldModel="models/props_combine/combine_lock01.mdl";
ITEM.ViewModel="models/Weapons/v_crossbow.mdl";
ITEM.MaxHealth=500;

--We don't want players spawning it.
ITEM.Spawnable=false;
ITEM.AdminSpawnable=false;

if SERVER then
	ITEM.HoldType="slam";
end

--Base Lock
ITEM.AttachRange=128;
ITEM.CanAttachSound=Sound("ambient/energy/weld1.wav");
ITEM.CantAttachSound=Sound("weapons/physcannon/physcannon_charge.wav");
ITEM.AttachSound=Sound("weapons/physcannon/superphys_small_zap3.wav");

if SERVER then
	ITEM.InitWithoutPhysics=false;
end

--[[
Returns the attached entity, or nil if the ent is not attached to an entity.
]]--
function ITEM:GetAttachedEnt()
	return self:GetNWEntity("AttachedEnt");
end

--[[
Returns the attached item, or nil if the lock is not attached to an item.
]]--
function ITEM:GetAttachedItem()
	return self:GetNWItem("AttachedItem");
end

--[[
Returns true/false depending on if the ent/item this lock is attached to is locked.
]]--
function ITEM:IsAttachmentLocked()
	local ent=self:GetAttachedEnt();
	local item=self:GetAttachedItem();
	if ent then
		return (ent.ItemforgeLocked==true);
	elseif item then
		return item:Event("IsLocked",false);
	end
end

--[[
Returns the position of the item this is attached to (while the item is attached to another item it is in the void)
]]--
function ITEM:GetVoidPos()
	local i=self:GetAttachedItem();
	if i then return i:GetPos() end
end
	
--[[
Runs when the player attempts to detach this from whatever it's attached to.
If this is run serverside, the item is detached from whatever it's attached from.
If this is run clientside, the client requests the server to run this function.
Nothing happens in either case if the given player can't interact with the item.
]]--
function ITEM:PlayerDetach(player)
	if !self:Event("CanPlayerInteract",false,player) then return false end
	
	if SERVER then	self:DetachFromEnt();
	else			self:SendNWCommand("PlayerDetach");
	end
end

--[[
The item can't exit the world while it's attached to an entity,
in addition to any other case that it can't exit.
]]--
function ITEM:CanExitWorld(ent)
	return (self:GetAttachedEnt()==nil && self["item"].CanExitWorld(self,ent));
end

--[[
A slightly modified version of the base item's CanPlayerInteract.
If the lock is attached to something and you're nearby the attachment, you can interact with it.
]]--
function ITEM:CanPlayerInteract(pl)
	if !pl:Alive() then return false end
	if CLIENT && pl!=LocalPlayer() then	return false end
	
	local c=self:GetContainer();
	if c && !c:Event("CanPlayerInteract",false,pl,self) then return false end
	
	if self:IsHeld() && self:GetWOwner()!=pl then
		return true;
	else
		local pos=self:GetPos();
		if pos==nil then
			
		end
		
		local postype=type(pos);
		if postype=="Vector" then
			if pos:Distance(pl:GetPos())<=256 then return true end
		elseif postype=="table" then
			for k,v in pairs(pos) do
				if v:Distance(pl:GetPos())<=256 then return true end
			end
		else
			return false;
		end
	end
end




if SERVER then




--[[
This is the entity init function with some simple adjustments.
No physics are initialized if the item says they shouldn't be (in the case that we are)
]]--
function ITEM:OnEntityInit(entity)
	entity:SetModel(self:GetWorldModel());
	
	if !self.InitWithoutPhysics then
		entity:PhysicsInit(SOLID_VPHYSICS);
		local phys = entity:GetPhysicsObject();
		if (phys:IsValid()) then
			phys:Wake();
		end
	else
		--We don't have a physics model so we need to set collision bounds
		entity:SetCollisionBounds(Vector(0,-3,-5.5),Vector(3,3,5.5));
		
		--Interestingly enough, we can use SOLID_VPHYSICS for an OBB even if we don't have physics!
		entity:SetSolid(SOLID_VPHYSICS);
		entity:SetCollisionGroup(COLLISION_GROUP_NONE);
		
		--We don't want to draw shadows while we're on the wall
		entity:DrawShadow(false);
	end
	
	--We'll do some other stuff like set it to simple use here
	entity:SetUseType(SIMPLE_USE);
	
	return true;
end

--[[
When the item exits
]]--
function ITEM:OnExitWorld(forced)
	if self:GetAttachedEnt() then self:Detach(); end
end

function ITEM:OnUse(pl)
	if self:InWorld() then
		local att=self:GetAttachedEnt();
		
		if att then
			if self:IsAttachmentLocked() then	self:UnlockAttachment();
			else								self:LockAttachment();
			end
		else		self:WorldAttach();
		end
	elseif self:IsHeld() then
		
	else
	end
	return true;
end

--In-world attachment behavior. The item tries to find something to attach itself to.
function ITEM:WorldAttach()
	if !self:InWorld() || self.InitWithoutPhysics then return false end
	
	local ent=self:GetEntity();
	
	--Lets find something to attach to
	local tr={};
	tr.start=ent:GetPos();
	tr.endpos=tr.start+((ent:GetForward()*-1)*self.AttachRange);
	tr.filter=ent;
	local traceRes=util.TraceLine(tr);
	
	if traceRes.Hit && traceRes.Entity && traceRes.Entity:IsValid() then
		local item=IF.Items:GetEntItem(traceRes.Entity);
		if item && item.OnAttachLock then
			self:EmitSound(self.CanAttachSound);
			item:Event("OnAttachLock",nil,self);
			self:SetNWItem("AttachedItem",item);
		elseif (traceRes.Entity:GetClass()=="prop_door_rotating" || traceRes.Entity:GetClass()=="func_door" || traceRes.Entity:GetClass()=="func_door_rotating") then
			--We remove the item's current world entity, and then send it back to the world without physics
			local pos,ang=ent:GetPos(),ent:GetAngles();
			if !self:ToVoid() then return false end
			self.InitWithoutPhysics=true;
			ent=self:ToWorld(pos,ang);
			
			--[[
			This plays the Lock Weld effect, which lasts about half a second.
			This effect animates the lock into position clientside.
			Once it finishes playing, the lock item's position, angles, parent entity, etc are finalized in a seperate function (hence the half-second timer beneath the effect)
			]]--
			local effectdata = EffectData();
			effectdata:SetOrigin(traceRes.HitPos);
			effectdata:SetAngle(traceRes.HitNormal:Angle())
			effectdata:SetEntity(ent);
			util.Effect("LockWeld",effectdata,true,true);
			self:SimpleTimer(0.5,self.AttachTo,traceRes.Entity,traceRes.Entity:WorldToLocal(traceRes.HitPos),traceRes.Entity:WorldToLocalAngles(traceRes.HitNormal:Angle()));
			
			self:EmitSound(self.CanAttachSound);
			return true;
		end
	end
	
	self:EmitSound(self.CantAttachSound);
end

--Instantly teleports the item and parents it to the given ent. The given ent is recorded as our attached ent.
function ITEM:AttachTo(toEnt,lPos,lAng)
	--Teleport the ent to the correct position
	local ent=self:ToWorld(toEnt:LocalToWorld(lPos),toEnt:LocalToWorldAngles(lAng));
	ent:SetParent(toEnt);
	
	self:EmitSound(self.AttachSound);
	self:SetNWEntity("AttachedEnt",toEnt);
end

--Clears any attachments
function ITEM:Detach()	
	self:UnlockAttachment();
	
	self:SetNWEntity("AttachedEnt",nil);
	self:SetNWItem("AttachedItem",nil);
end

--[[
If attached to an entity, causes it to fall off
]]--
function ITEM:DetachFromEnt()
	if !self:GetAttachedEnt() then return false end
	
	local ent=self:GetEntity();
	local pos,ang=ent:GetPos(),ent:GetAngles();
	
	--First, the connection is cleared. Then we respawn the entity at it's old position/angles, but with physics this time
	self:Detach();
	self:ToVoid();
	self.InitWithoutPhysics=false;
	self:ToWorld(pos,ang);
	
	return true;
end

--[[
Locks the attached entity/item
]]--
function ITEM:LockAttachment()
	local ent=self:GetAttachedEnt();
	local item=self:GetAttachedItem();
	if ent then
		ent:Fire("Lock","",0);
		ent.ItemforgeLocked=true;
	elseif item then
		item:Event("Lock",nil,self);
	end
end

--[[
Unlocks the attached entity/item
]]--
function ITEM:UnlockAttachment()
	local ent=self:GetAttachedEnt();
	local item=self:GetAttachedItem();
	
	if ent then
		ent:Fire("Unlock","",0);
		ent.ItemforgeLocked=false;
	else
		item:Event("Unlock",nil,self);
	end
end

IF.Items:CreateNWCommand(ITEM,"PlayerDetach",function(self,...) self:PlayerDetach(...) end);




else




function ITEM:OnPopulateMenu(pMenu)
	self["item"].OnPopulateMenu(self,pMenu);
	if self:GetAttachedEnt() || self:GetAttachedItem() then
		if self:IsAttachmentLocked() then	pMenu:AddOption("Unlock",function(panel) self:PlayerUnlock(LocalPlayer()) end);
		else								pMenu:AddOption("Lock",function(panel) self:PlayerLock(LocalPlayer()) end)
		end
		pMenu:AddOption("Detach",function(panel) self:PlayerDetach(LocalPlayer()) end);
	end
end

IF.Items:CreateNWCommand(ITEM,"PlayerDetach");




end

IF.Items:CreateNWVar(ITEM,"AttachedEnt","entity");
IF.Items:CreateNWVar(ITEM,"AttachedItem","item");