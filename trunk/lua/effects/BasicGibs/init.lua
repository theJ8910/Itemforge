--[[
BasicGibs
CLIENT

This effect spawns a few metal gibs where it's told to.
]]--
EFFECT.Models={
	{
		"models/Gibs/metal_gib1.mdl",
		"models/Gibs/metal_gib2.mdl",
		"models/Gibs/metal_gib3.mdl",
		"models/Gibs/metal_gib4.mdl",
		"models/Gibs/metal_gib5.mdl"
	},
	{
		"models/Gibs/wood_gib01a.mdl",
		"models/Gibs/wood_gib01b.mdl",
		"models/Gibs/wood_gib01c.mdl",
		"models/Gibs/wood_gib01d.mdl",
		"models/Gibs/wood_gib01e.mdl"
	},
	{
		"models/Gibs/Glass_shard01.mdl",
		"models/Gibs/Glass_shard02.mdl",
		"models/Gibs/Glass_shard03.mdl",
		"models/Gibs/Glass_shard04.mdl",
		"models/Gibs/Glass_shard05.mdl",
		"models/Gibs/Glass_shard06.mdl"
	}
}

EFFECT.Volumes = {
	{
		7.1886806488037,
		83.349411010742,
		38.257247924805,
		7.8723797798157,
		9.2407827377319
	},
	{
		617.95361328125,
		544.78570556641,
		195.28387451172,
		179.21020507813,
		23.131534576416
	},
	{
		68.85701751709,
		60.127311706543,
		48.474346160889,
		39.053909301758,
		38.249416351318,
		35.314125061035
	}
}

EFFECT.Radii = {
	{
		5.0731797218323,
		8.7452411651611,
		9.4070749282837,
		4.2380547523499,
		8.1151390075684
	},
	{
		27.048402786255,
		21.923555374146,
		14.740992546082,
		17.448728561401,
		7.7401585578918
	},
	{
		11.460278511047,
		10.480204582214,
		7.6179137229919,
		11.718404769897,
		9.1695652008057,
		10.615882873535
	},
}

EFFECT.Sounds={
	{
		Sound("physics/metal/metal_box_break1.wav"),
		Sound("physics/metal/metal_box_break2.wav")
	},
	{
		Sound("physics/wood/wood_furniture_break1.wav"),
		Sound("physics/wood/wood_furniture_break2.wav"),
		Sound("physics/wood/wood_plank_break2.wav"),
		Sound("physics/wood/wood_plank_break3.wav"),
		Sound("physics/wood/wood_plank_break4.wav")
	},
	{
		Sound("physics/glass/glass_sheet_break1.wav"),
		Sound("physics/glass/glass_sheet_break2.wav"),
		Sound("physics/glass/glass_sheet_break3.wav")
	},
}

EFFECT.DecayDelay = 10;
EFFECT.FadeDelay = 8;
EFFECT.StartFadeAt = 0;
EFFECT.DecayedAt = 0;
EFFECT.Gibs = nil;

local minrandomvel= Vector(-150,-150,-150);
local maxrandomvel= Vector(150,150,150);

function EFFECT:Init(data)
	self.Gibs = {};
	
	local origin = data:GetOrigin();
	local rot = data:GetAngle();
	local maxcorner = data:GetStart();
	local mincorner = Vector(-maxcorner.x,
							 -maxcorner.y,
							 -maxcorner.z);
	local basevel = data:GetNormal() * data:GetScale();
	local vol = data:GetRadius();	--Total volume of broken prop
	local gibvol = 0;				--Total volume of gibs
	
	local set = data:GetAttachment();
	local GibModels = self.Models[set];
	local GibVolumes = self.Volumes[set];
	local GibRadii = self.Radii[set];
	local SoundSet = self.Sounds[set];
	
	local chosen;
	local chosenrad;
	local offset;
	local gib;
	local gibphys;
	
	while gibvol < vol do
		chosen = math.random(1,#GibModels);
		chosenrad = GibRadii[chosen];
		
		--Using the bounding box and radius of the props we spawn the gibs in a relatively "safe" area, so they won't be spawned in the world very often (hopefully).
		--This works best on boxy objects but can fairly closely approximate other objects, depending on their size.
		offset = self:RandomVector(Vector(math.min(mincorner.x+chosenrad,0),
								  math.min(mincorner.y+chosenrad,0),
								  math.min(mincorner.z+chosenrad,0))
								 ,Vector(math.max(maxcorner.x-chosenrad,0),
								  math.max(maxcorner.y-chosenrad,0),
								  math.max(maxcorner.z-chosenrad,0)));
		offset:Rotate(rot);
		
		
		gib=ents.Create("prop_physics");
		gib:SetModel(GibModels[chosen]);
		gib:SetAngles(self:RandomAngle());
		gib:SetPos(origin + offset);
		gib:SetCollisionGroup(COLLISION_GROUP_DEBRIS);
		gib:PhysicsInit(SOLID_VPHYSICS);
		gib:SetMoveType(MOVETYPE_VPHYSICS);
		gib:Spawn();
		
		gibphys = gib:GetPhysicsObject();
		gibphys:Wake();
		gibphys:SetVelocity(basevel + self:RandomVector(minrandomvel,maxrandomvel));
		
		table.insert(self.Gibs,gib);
		gibvol = gibvol + GibVolumes[chosen];
	end
	
	--Play a random break sound for this gib set
	WorldSound(SoundSet[math.random(1,#SoundSet)],origin);
	
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
	local t = CurTime();
	if t < self.StartFadeAt then
		return true;
	elseif t < self.DecayedAt then
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