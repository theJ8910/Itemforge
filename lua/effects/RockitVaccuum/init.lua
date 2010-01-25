--[[
RockitVaccuum
CLIENT

The rockit vaccum is a particle effect created when the vaccuum on a rock-it launcher is activated.
]]--
local smokeMat=Material("effects/smoke");

function EFFECT:Init(data)
	self.LockEnt		=	data:GetEntity();
end

function EFFECT:Think( )
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