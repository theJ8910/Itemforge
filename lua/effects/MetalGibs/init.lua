--[[
MetalGibs
CLIENT

This effect spawns a few metal gibs where it's told to.
]]--
local GibModels={
	"models/Gibs/metal_gib1.mdl",
	"models/Gibs/metal_gib2.mdl",
	"models/Gibs/metal_gib3.mdl",
	"models/Gibs/metal_gib4.mdl",
	"models/Gibs/metal_gib5.mdl"
};

EFFECT.DecayDelay = 10;
EFFECT.FadeDelay = 8;
EFFECT.StartFadeAt = 0;
EFFECT.DecayedAt = 0;
EFFECT.Gibs = nil;

function EFFECT:Init(data)
	self.Gibs = {};
	
	local origin = data:GetOrigin();
	local rot = data:GetAngle();
	local maxcorner = data:GetStart();
	local mincorner = Vector(-maxcorner.x,
							 -maxcorner.y,
							 -maxcorner.z);
	local basevel = data:GetNormal() * data:GetScale();
	local minrandomvel= Vector(-5,-5,-5);
	local maxrandomvel= Vector(5,5,5);
	for i=1,5 do
		local offset = self:RandomVector(mincorner,maxcorner);
		offset:Rotate(rot);
		
		local gib=ents.Create("prop_physics");
		gib:SetModel(GibModels[math.random(1,#GibModels)]);
		gib:SetAngles(self:RandomAngle());
		gib:SetPos(origin + offset);
		gib:SetCollisionGroup(COLLISION_GROUP_DEBRIS);
		gib:PhysicsInit(SOLID_VPHYSICS);
		gib:SetMoveType(MOVETYPE_VPHYSICS);
		gib:Spawn();
		
		local gibphys = gib:GetPhysicsObject();
		gibphys:Wake();
		gibphys:SetVelocity(basevel + self:RandomVector(minrandomvel,maxrandomvel));
		
		table.insert(self.Gibs,gib);
	end
	
	self.StartFadeAt = CurTime() + self.FadeDelay;
	self.DecayedAt = CurTime() + self.DecayDelay;
end

function EFFECT:RandomVector(vMin,vMax)
	return Vector(math.Rand(vMin.x,vMax.x),
				  math.Rand(vMin.y,vMax.y),
				  math.Rand(vMin.z,vMax.z));
end

function EFFECT:RandomAngle()
	return Angle( math.Rand(0,360), math.Rand(0,360), math.Rand(0,360) );
end

function EFFECT:Think()
	if CurTime() < self.DecayedAt then
		local a=Lerp(math.TimeFraction(self.StartFadeAt,self.DecayedAt,CurTime()),255,0);
		for k,v in pairs(self.Gibs) do
			v:SetColor(255,255,255,a);
		end
		return true;
	else
		for k,v in pairs(self.Gibs) do
			v:Remove();
		end
		return false;
	end
end

function EFFECT:Render()
end