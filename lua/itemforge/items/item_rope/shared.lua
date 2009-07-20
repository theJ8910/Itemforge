--[[
item_rope
SHARED

It's rope! You can rope things together with it.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Rope";
ITEM.Description="A rope woven from strands of hemp fibers. ";
ITEM.Base="item";
ITEM.WorldModel="models/Items/CrossbowRounds.mdl";
ITEM.StartAmount=1000;
ITEM.MaxAmount=0;

ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

--Rope Item
ITEM.Strength=40000;				--The rope breaks when this much force is applied to it
ITEM.Width=3;						--The rope graphic appears to be this thick
ITEM.Material="cable/rope";			--The rope graphic uses this material
ITEM.FirstEntity=nil;
ITEM.FirstBone=0;
ITEM.FirstAnchor=Vector(0,0,0);

function ITEM:GetDescription()
	return self.Description.."It is "..self:GetAmount().." units long.";
end

--The player can't split the rope directly
function ITEM:CanPlayerSplit(pl)
	return false;
end

if SERVER then

--[[
Ropes two entities together.
The length of the rope is determined by the amount of this item.

ent1 is the first entity you want to rope.
bone1 is a physics bone number on ent1 you want to rope to. For all non-ragdoll entities, this is pretty much always 0.
point1 is the local position on ent1 you want to anchor one end of the rope to.

ent2 is the second entity you want to rope.
bone2 is a physics bone number on ent2 you want to rope to. For all non-ragdoll entities, this is pretty much always 0.
point2 is the local position on ent2 you want to anchor the other end of the rope to.

The total length between point1 and point2 cannot be greater than the length (amount) of the rope. This function will return false if this is the case.

This function returns false if we couldn't rope the two entities, or true if we did.
]]--
function ITEM:RopeTogether(ent1,bone1,point1,ent2,bone2,point2)
	local len=self:GetAmount();
	
	local p1,p2=ent1:GetPhysicsObjectNum(bone1),ent2:GetPhysicsObjectNum(bone2);
	if !p1 || !p1:IsValid() || !p2 || !p2:IsValid() then return false end
	
	local w1,w2=p1:LocalToWorld(point1),p2:LocalToWorld(point2);
	local dis=w1:Distance(w2);
	if dis>len then return false end
	
	local dis=point1:Distance(point2);
	if !constraint.Rope(ent1,ent2,bone1,bone2,point1,point2,dis,len-dis,self.Strength,self.Width,self.Material,false) then return false end
	
	self:Remove();
	return true;
end

function ITEM:OnPrimaryAttack()
	local pl=self:GetWOwner();
	--TODO Minimum distance
	local traceRes=pl:GetEyeTrace();
	
	local ent=traceRes.Entity;
	if !ent:IsValid() then return false end
	
	local phys=ent:GetPhysicsObjectNum(traceRes.PhysicsBone);
	if !phys || !phys:IsValid() then return false end
	
	if !self.FirstEntity || !self.FirstEntity:IsValid() then
		self.FirstEntity=ent;
		self.FirstBone=traceRes.PhysicsBone;
		self.FirstAnchor=phys:WorldToLocal(traceRes.HitPos);
	else
		self:RopeTogether(self.FirstEntity,self.FirstBone,self.FirstAnchor,ent,traceRes.PhysicsBone,phys:WorldToLocal(traceRes.HitPos));
	end
	
	return true;
end

end