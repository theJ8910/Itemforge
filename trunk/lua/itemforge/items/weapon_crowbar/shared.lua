--[[
weapon_crowbar
SHARED

Bashes people. Opens doors.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Crowbar";
ITEM.Description="A long, fairly heavy steel rod with teeth.\nGood for prying open doors or pulverising skulls.";
ITEM.Base="base_melee";
ITEM.Size=19;
ITEM.Weight=1500;

ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

if SERVER then

ITEM.GibEffect = "metal";

end

--Overridden Base Weapon stuff
ITEM.PrimaryDelay=.4;

--Overridden Base Melee stuff
ITEM.HitRange=75;
ITEM.HitForce=1;
ITEM.HitDamage=25;
ITEM.ViewKickMin=Angle(1.0,-2.0,0);
ITEM.ViewKickMax=Angle(2.0,-1.0,0);

--Crowbar
ITEM.ForceOpenSound=Sound("doors/vent_open2.wav");
ITEM.ImpactSounds={
	Sound("weapons/crowbar/crowbar_impact1.wav"),
	Sound("weapons/crowbar/crowbar_impact2.wav"),
};

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

function ITEM:OnHit(pOwner,hitent,hitpos,traceRes)
	return self:OpenDoor(hitent);
end

function ITEM:OpenDoor(door)
	if !door || !door:IsValid() || door:GetClass()!="prop_door_rotating" then return false end
	
	--Clientside we can't actually open doors, so we just return true if they can be opened
	if CLIENT then return true end
	
	door:Fire("unlock","","0");
	door:Fire("open","","0");
	door:EmitSound(self.ForceOpenSound);
	return true;
end

if SERVER then




--[[
Impact sounds.
CollisionData is information about the collision passed on from the entity's event.
HitPhysObj is the physics object belonging to this entity which collided.
]]--
function ITEM:OnPhysicsCollide(entity,CollisionData,HitPhysObj)
	if (CollisionData.Speed > 50 && CollisionData.DeltaTime > 0.05 ) then
		self:EmitSound(self.ImpactSounds,CollisionData.Speed,100+math.Rand(-20,20));
	end
end




end