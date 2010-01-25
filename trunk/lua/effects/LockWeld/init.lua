--[[
LockWeld
CLIENT

This effect is applied when you attach a lock. It displays a bunch of beams and pulls the affected entity into place clientside.
This is my first effect, it was originally the tool tracer but has been heavily modified.
]]--

local third=1/3;

--return number with smallest absolute value
local function SmAb(a,b,c)
	local abA,abB,abC=math.abs(a),math.abs(b),math.abs(c);
	local smallest=math.min(abA,abB,abC);
	
	if smallest==abA then		return a;
	elseif smallest==abB then	return b;
	else						return c;
	end
end

EFFECT.Mat = Material("effects/tool_tracer");

function EFFECT:Init(data)
	self.LockEnt		=	data:GetEntity();
	if !self.LockEnt then return false end
	
	local a=self.LockEnt:GetAngles();
	local b=data:GetAngle();
	
	self.Alpha			=	255;
	self.EndsAt			=	CurTime()+.5;
	
	self.StartPos		=	self.LockEnt:GetPos();
	self.EndPos			=	data:GetOrigin();
	self.Normal			=	(self.EndPos-self.StartPos):GetNormal();
	self.Distance		=	self.LockEnt:GetPos():Distance(self.EndPos);
	
	self.StartAngles	=	a;
	
	--This is messy, but the purpose of it is to find the smallest distance to rotate on each axis
	self.OffsetAngles	=	Angle(	SmAb(b.p-a.p,b.p-(a.p-360),b.p-(a.p+360)),
									SmAb(b.y-a.y,b.y-(a.y-360),b.y-(a.y+360)),
									SmAb(b.r-a.r,b.r-(a.r-360),b.r-(a.r+360)));
	
	
end

function EFFECT:Think()
	local timeleft=self.EndsAt-CurTime();

	--Kill the effect if it expires or we lose the entity OR if if the weld completed
	if !self.LockEnt || !self.LockEnt:IsValid() || timeleft<0 || self.LockEnt:GetParent()!=nil then return false; end
	
	local f=timeleft*2;	--(timeleft will at most be .5; 2 * .5 = 1)
	
	--The effect moves the entity
	self.LockEnt:SetPos(self.StartPos+(self.Normal*(self.Distance*(1-f))));
	self.LockEnt:SetAngles(self.StartAngles+(self.OffsetAngles*(1-f)));
	
	self.Alpha=(timeleft*510);
	self.Entity:SetRenderBoundsWS(self.LockEnt:GetPos(),self.EndPos);
	
	return true;
end

function EFFECT:Render()
	if ( self.Alpha < 1 ) then return end
	
	local min,max=self.LockEnt:OBBMins(),self.LockEnt:OBBMaxs();
	local c=Color(255,255,255,self.Alpha);
	render.SetMaterial(self.Mat);
	for i=1,20 do
		local p=self.LockEnt:LocalToWorld(Vector(0,math.Rand(min.y,max.y),math.Rand(min.z,max.z)));
		local l=p:Distance(self.EndPos);
		local texcoord = math.Rand(0,1);
		render.DrawBeam(p,self.EndPos,2,texcoord,texcoord+(l*.0078125),c);
	end
end