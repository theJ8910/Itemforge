--[[
BladeBlood
CLIENT

Whenever the sawblade is pulled out of flesh this effect plays.
]]--

EFFECT.Fan = 45;
EFFECT.BloodSpin=1440;	--Up to four full rotations per second in either direction
EFFECT.SawbladeRadius=18;
local Sounds = {
	Sound("ambient/water/rain_drip1.wav"),
	Sound("ambient/water/rain_drip2.wav"),
	Sound("ambient/water/rain_drip3.wav"),
	Sound("ambient/water/rain_drip4.wav")
};

local oneup=Vector(0,0,1);

local DecalTypes = {
	[1] = "Blood",
	[2] = "YellowBlood"
}

local ParticleCollides = {
	[1] =	function(self,hit)
				if !self.Hit then
					util.Decal(DecalTypes[1],hit+oneup,hit-oneup);
					WorldSound(Sounds[math.random(1,#Sounds)],hit);
					self.Hit=true;
					self:SetDieTime(0);
				end
			end,
	[2] =	function(self,hit)
				if !self.Hit then
					util.Decal(DecalTypes[2],hit+oneup,hit-oneup);
					WorldSound(Sounds[math.random(1,#Sounds)],hit);
					self.Hit=true;
					self:SetDieTime(0);
				end
			end,
	[3] =	function(self,hit)
				if !self.Hit then
					WorldSound(Sounds[math.random(1,#Sounds)],hit);
					self.Hit=true;
					self:SetDieTime(0);
				end
			end
}

function EFFECT:Init(data)
	local ent = data:GetEntity();
	if !ent || !ent:IsValid() then return false end
	
	local entpos=ent:GetPos();
	local entup=ent:GetAngles():Up();
	local entvel=Vector(0,0,0);
	local phys=ent:GetPhysicsObject();
	if phys && phys:IsValid() then
		entvel=phys:GetVelocity();
	end
	
	
	local ang = data:GetAngle();
	local bloodtype = data:GetAttachment();
	local vGravity = Vector(0,0,-700 * (GetConVarNumber("sv_gravity")*0.0016666667) );		--Note: 0.0016666667 = 1/600
	local ParticleCollide = ParticleCollides[bloodtype];
	local strDecal = DecalTypes[bloodtype];

	local emitter = ParticleEmitter(ent:GetPos());
	for i=1,30 do 
		local fwd=ent:LocalToWorldAngles(ang+Angle(0,math.Rand(-self.Fan,self.Fan),0)):Forward();
		local particle = emitter:Add("effects/blood_core",entpos+(fwd*self.SawbladeRadius));
		if (particle) then
			particle:SetLifeTime(0);
			particle:SetDieTime(math.Rand(0.3,1));
			local r = math.random(100,180); 
			if bloodtype == 1 then			particle:SetColor(r,0,0);
			elseif bloodtype == 2 then		particle:SetColor(r,r,0);
			else							particle:SetColor(r,r,r);
			end

			particle:SetStartAlpha(255);
			particle:SetEndAlpha(255);
			particle:SetStartSize(5);
			particle:SetEndSize(25);
			particle:SetVelocity(entvel+(fwd*100));
			particle:SetRoll(math.Rand(0,360));
			particle:SetRollDelta(math.Rand(-self.BloodSpin,self.BloodSpin));
			particle:SetAirResistance(50);
			particle:SetGravity(vGravity);
			particle:SetCollide(true);
			particle:SetCollideCallback(ParticleCollide);
		end 
	end 
	 
 	emitter:Finish();
	
	if strDecal then
		local v=ent:LocalToWorld(ang:Forward()*(self.SawbladeRadius-5));
		util.Decal(strDecal,v+entup,v-entup);
	end
end

function EFFECT:Think()
	return false;
end

function EFFECT:Render()
end