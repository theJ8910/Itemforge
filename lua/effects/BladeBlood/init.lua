--[[
BladeBlood
CLIENT

Whenever the sawblade is pulled out of flesh this effect plays.
]]--

EFFECT.Fan = math.pi*.5;
EFFECT.BloodSpin=math.pi;
EFFECT.SawbladeRadius=18;
local twoPi=math.pi*2;

function EFFECT:Init(data)
	local ent = data:GetEntity();
	if !ent || !ent:IsValid() then return false end
	
	local ang=data:GetAngle();
	local emitter=ParticleEmitter(ent:GetPos());
 	 
	for i=1,50 do 
		local fwd=ent:LocalToWorldAngles(ang+Angle(0,math.Rand(-self.Fan,self.Fan),0)):Forward();
		local particle = emitter:Add("effects/blood_core",ent:GetPos()+(fwd*self.SawbladeRadius)) 
		if (particle) then
			particle:SetLifeTime(0);
			particle:SetDieTime(math.Rand(0.5,1)); 
			particle:SetColor(200,0,0);
			particle:SetStartAlpha(math.Rand(200,255));
			particle:SetEndAlpha(0);
			particle:SetStartSize(1);
			particle:SetEndSize(3);
			particle:SetVelocity(fwd*4);
			particle:SetRoll(math.Rand(0,twoPi));
			particle:SetRollDelta(math.Rand(-self.BloodSpin,self.BloodSpin));
			particle:SetAirResistance(100);
			particle:SetGravity(Vector(0,0,-700));
			particle:SetCollide(false);
		end 
	end 
	 
 	emitter:Finish();
end

function EFFECT:Think()
	return false;
end

function EFFECT:Render()
end