--[[
base_lock
SHARED

base_lock is a base. That means that other items borrow code from this so they can be created easier.
Any item that inherits from this has everything this item has, and can override anything this item has.

The base_lock's purpose is to provide a variety of functions that all locks use, including (but not limited to):
	Attaching and detatching to items and entities
	Locking and unlocking attached items and entities
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

ITEM.CanAttachSound=Sound("ambient/energy/weld1.wav");
ITEM.CantAttachSound=Sound("weapons/physcannon/physcannon_charge.wav");
ITEM.AttachSound=Sound("weapons/physcannon/superphys_small_zap3.wav");

if SERVER then
	ITEM.HoldType="slam";
	ITEM.AttachRange=128;
	ITEM.Welding=false;
end




function ITEM:GetAttachedEnt()
	return self:GetNWEntity("AttachedTo");
end




if SERVER then




function ITEM:OnUse(pl)
	if self:InWorld() then
		local att=self:GetAttachedEnt();
		
		if att then	self:OpenAttachedEnt();
		else		self:WorldAttach();
		end
	elseif self:IsHeld() then
	
	end
	return true;
end

--In-world attachment behavior. The item tries to find something to attach itself to.
function ITEM:WorldAttach()
	if !self:InWorld() || self.Welding then return false end
	
	local ent=self:GetEntity();
	
	--Lets find something to attach to
	local tr={};
	tr.start=ent:GetPos();
	tr.endpos=tr.start+((ent:GetForward()*-1)*self.AttachRange);
	tr.filter=ent;
	local traceRes=util.TraceLine(tr);
	
	if traceRes.Hit && traceRes.Entity && traceRes.Entity:IsValid() && (traceRes.Entity:GetClass()=="prop_door_rotating" || traceRes.Entity:GetClass()=="func_door" || traceRes.Entity:GetClass()=="func_door_rotating") then
		local pos,ang=ent:GetPos(),ent:GetAngles();
		self:ToVoid();
		self.Welding=true;
		ent=self:ToWorld(pos,ang);
		
		local effectdata = EffectData();
		effectdata:SetOrigin(traceRes.HitPos);
		effectdata:SetAngle(traceRes.HitNormal:Angle())
		effectdata:SetEntity(ent);
		util.Effect("LockWeld",effectdata,true,true);
		
		self:EmitSound(self.CanAttachSound);
		self:SimpleTimer(0.5,self.AttachTo,traceRes.Entity,traceRes.Entity:WorldToLocal(traceRes.HitPos),traceRes.Entity:WorldToLocalAngles(traceRes.HitNormal:Angle()));
	else
		self:EmitSound(self.CantAttachSound);
	end
end

--Instantly teleports the item and parents it to the given ent. The given ent is recorded as our attached ent.
function ITEM:AttachTo(toEnt,lPos,lAng)
	local ent=self:ToWorld(toEnt:LocalToWorld(lPos),toEnt:LocalToWorldAngles(lAng));
	ent:SetParent(toEnt);
	ent:SetCollisionGroup(COLLISION_GROUP_NONE);
	
	if toEnt:GetClass()=="prop_door_rotating" || toEnt:GetClass()=="func_door" || toEnt:GetClass()=="func_door_rotating" then
		toEnt:Fire("Lock","",0);
	end
	
	self:EmitSound(self.AttachSound);
	self:SetNWEntity("AttachedTo",toEnt);
end

function ITEM:WorldDetach()
	if !self:InWorld() || !self:GetAttachedEnt() then return false end
	
	local ent=self:GetEntity();
	local pos,ang=ent:GetPos(),ent:GetAngles();
	
	--Sending the item to the void removes it from world, removing from world causes the Detach() function below to run
	self:ToVoid();
	
	--We respawn the entity at it's old position/angles, but with physics this time
	self:ToWorld(pos,ang);
end

--Clears the attachment
function ITEM:Detach()
	self.Welding=false;
	local attach=self:GetAttachedEnt();
	if attach:GetClass()=="prop_door_rotating" || attach:GetClass()=="func_door" || attach:GetClass()=="func_door_rotating" then
		attach:Fire("Unlock","",0);
	end
	self:SetNWEntity("AttachedTo",nil);
end

function ITEM:OpenAttachedEnt()
	local attach=self:GetAttachedEnt();
	if !attach then return false end
	
	if attach:GetClass()=="prop_door_rotating" || attach:GetClass()=="func_door" || attach:GetClass()=="func_door_rotating" then
		attach:Fire("Unlock","",0);
		attach:Fire("Open","",0);
		attach:Fire("Lock","",0);
		self:SimpleTimer(5,self.CloseAttachedEnt);
		
		return true;
	end
	return false;
end

function ITEM:CloseAttachedEnt()
	local attach=self:GetAttachedEnt();
	if !attach then return false end
	
	if attach:GetClass()=="prop_door_rotating" || attach:GetClass()=="func_door" || attach:GetClass()=="func_door_rotating" then
		attach:Fire("Unlock","",0);
		attach:Fire("Close","",0);
		attach:Fire("Lock","",0);
	end
end

--[[
This is the entity init function with some simple adjustments.
No physics are initialized if the item is being welded.
]]--
function ITEM:OnEntityInit(entity)
	entity:SetModel(self:GetWorldModel());
	
	if !self.Welding then
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
		
		--We don't want to draw shadows while we're on the wall
		entity:DrawShadow(false);
	end
	
	--We'll do some other stuff like set it to simple use here
	entity:SetUseType(SIMPLE_USE);
	
	return true;
end

function ITEM:OnExitWorld(forced)
	if self:GetAttachedEnt() then self:Detach(); end
end




else




function ITEM:OnPopulateMenu(pMenu)
	self["item"].OnPopulateMenu(self,pMenu);
	if self:GetAttachedEnt()!=nil && self:InWorld() then
		pMenu:AddOption("Detach",function(panel) self:SendNWCommand("WorldDetach") end);
	end
end




end

--Networked Vars
IF.Items:CreateNWVar(ITEM,"AttachedTo","entity");

--Networked Commands
IF.Items:CreateNWCommand(ITEM,"WorldDetach",ITEM.WorldDetach);