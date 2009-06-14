--[[
weapon_crowbar
SHARED

Bashes people. Opens doors.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Crowbar";
ITEM.Description="A long, fairly heavy iron rod with teeth.\nGood for prying open doors or pulverising skulls.";
ITEM.Base="base_melee";
ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

--Base Melee Weapon
ITEM.HitRange=75;
ITEM.HitForce=5;
ITEM.HitDamage=25;

ITEM.ForceOpenSound=Sound("doors/vent_open2.wav");

function ITEM:OnUse(pl)
	if self["base_melee"].OnUse(self,pl) then return true end
	
	--We'll try to find a door to open
	local tr={};
	tr.start=pl:GetShootPos();
	tr.endpos=tr.start+(pl:GetAimVector()*self:GetHitRange());
	tr.filter=pl;
	tr.mask=MASK_SHOT;
	local traceRes=util.TraceLine(tr);
	
	return self:OpenDoor(traceRes.Entity);
end

if SERVER then


ITEM.ImpactSounds={
	Sound("weapons/crowbar/crowbar_impact1.wav"),
	Sound("weapons/crowbar/crowbar_impact2.wav"),
};

function ITEM:OpenDoor(door)
	if !door || !door:IsValid() || door:GetClass()!="prop_door_rotating" then return false end
	door:Fire("unlock","","0");
	door:Fire("open","","0");
	door:EmitSound(self.ForceOpenSound);
	return true;
end

--[[
Impact sounds.
CollisionData is information about the collision passed on from the entity's event.
HitPhysObj is the physics object belonging to this entity which collided.
]]--
function ITEM:OnPhysicsCollide(entity,CollisionData,HitPhysObj)
	if (CollisionData.Speed > 50 && CollisionData.DeltaTime > 0.2 ) then
		self:EmitSound(self.ImpactSounds[math.random(1,table.getn(self.ImpactSounds))],100+(CollisionData.Speed-70),100+math.Rand(-20,20));
	end
end




else




--Clientside this doesn't actually open doors, just returns true if they can be opened
function ITEM:OpenDoor(door)
	if !door || !door:IsValid() || door:GetClass()!="prop_door_rotating" then return false end
	return true;
end




end

function ITEM:OnHit(pOwner,hitent,hitpos,traceRes)
	return self:OpenDoor(hitent);
end