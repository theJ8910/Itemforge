--[[
base_melee
SHARED

base_melee is a base. That means that other items borrow code from this so they can be created easier.
Any item that inherits from this has everything this item has, and can override anything this item has.

The base_melee has two purposes:
	You can tell if an item is a melee weapon (like a knife or crowbar) by checking to see if it inherits from base_melee.
	It's designed to help you create melee weapons easier (like a knife, crowbar, pipe, etc). You just have to change/override some variables or replace some stuff with your own code.
]]--
if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Base Melee Weapon";
ITEM.Description="This item is the base melee weapon.\nItems used as melee weapons, such as a crowbar or a pipe, can inherit from this\n to make their creation easier.\n\nThis is not supposed to be spawned.";
ITEM.Base="base_weapon";
ITEM.WorldModel="models/weapons/w_crowbar.mdl";
ITEM.ViewModel="models/weapons/v_crowbar.mdl";

--We don't want players spawning it.
ITEM.Spawnable=false;
ITEM.AdminSpawnable=false;

--Base Melee Weapon
ITEM.HitDamage=25;					--We do this much damage per hit
ITEM.HitRange=75;					--We must be this close to attack with this weapon
ITEM.HitForce=1;					--When a physics object is hit, it's hit with "x" times more power than it would if a bullet hit it.
ITEM.ViewKickMin=Angle(0,0,0);
ITEM.ViewKickMax=Angle(0,0,0);
ITEM.SwingHullDims = 16;
ITEM.SwingHullMax = Vector(ITEM.SwingHullDims,ITEM.SwingHullDims,ITEM.SwingHullDims);
ITEM.SwingHullMin = Vector(-ITEM.SwingHullDims,-ITEM.SwingHullDims,-ITEM.SwingHullDims);

ITEM.HitSounds={
	Sound("physics/flesh/flesh_impact_bullet1.wav"),
	Sound("physics/flesh/flesh_impact_bullet2.wav"),
	Sound("physics/flesh/flesh_impact_bullet3.wav"),
	Sound("physics/flesh/flesh_impact_bullet4.wav"),
	Sound("physics/flesh/flesh_impact_bullet5.wav")
};

ITEM.MissSounds={
	Sound("weapons/iceaxe/iceaxe_swing1.wav")
};

ITEM.HoldType="melee";


--TODO: Garry needs to add the TraceAttackToTriggers binding so I can make melee weapon swings break glass
function ITEM:OnSWEPPrimaryAttack()
	--We do base_weapon's primary attack first (it handles the cooldown and tells us if we can attack or not)
	if !self:InheritedEvent("OnSWEPPrimaryAttack","base_weapon",false) then return false end
	
	local eWeapon=self:GetWeapon();
	local pOwner=self:GetWOwner();
	
	--We play the player's attack animation
	pOwner:SetAnimation(PLAYER_ATTACK1);
	
	--We have to figure out if the player hit something before dealing damage.
	--First we'll see if the player is looking directly at something.
	local shoot=pOwner:GetShootPos();
	local aim=pOwner:GetAimVector();
	local bIndirectHit = false;
	
	local tr={};
	tr.start=shoot;
	tr.endpos=shoot+(aim*self:GetHitRange());
	tr.filter=pOwner;
	tr.mask=MASK_SHOT;
	local traceRes=util.TraceLine(tr);
	
	--[[
	If he wasn't looking directly at something we'll try a hull trace instead.
	This is a box trace basically. We'll run a 32x32 box along the same line and see if it
	hits anything. It's not entirely clear if this trace is an OBB or AABB...
	I'd assume an OBB, because an AABB would offer a wider hit range when swinging diagonal
	to the world axes... but who knows? NOTE: the 1.732*self.SwingHullDims is me pulling the
	box back by it's bounding radius, like the modcode does. If I didn't do this the hits would
	reach further than they're supposed to. 1.732 is the square root of 3.
	]]--
	if !traceRes.Hit then
		tr.endpos = shoot + aim * (self:Event("GetHitRange",75)-1.732*self.SwingHullDims);
		tr.mins = self.SwingHullMin;
		tr.maxs = self.SwingHullMax;
		
		traceRes=util.TraceHull(tr);
		bIndirectHit = true;
	end
	
	local eHit = traceRes.Entity;
	if traceRes.HitNonWorld && IsValid(eHit) && self:Event("IsValidHit",false,shoot,aim,eHit) then
		traceRes.Hit = false;
	end
	
	if traceRes.Hit then
		--If he hit, we'll display his weapon hitting, play a hit sound, and then it's up to the weapon to decide what happens
		eWeapon:SendWeaponAnim(ACT_VM_HITCENTER);
		self:HitSound(traceRes);
		
		if !self:OnHit(pOwner,traceRes.Entity,traceRes.HitPos,traceRes) then
			--Melee weapons apply damage with trace attack dispatches.
			local dmg = DamageInfo();
			dmg:SetDamagePosition(shoot);
			dmg:SetDamageForce(aim*self:Event("GetHitForce",1,traceRes));
			dmg:SetInflictor(pOwner);
			dmg:SetAttacker(pOwner);
			dmg:SetDamage(self:Event("GetHitDamage",0,traceRes));
			dmg:SetDamageType(DMG_CLUB);
			
			eHit:DispatchTraceAttack(dmg,traceRes.StartPos,traceRes.HitPos);
			
			--We have to use bullets clientside for impact effects since garry doesn't
			--have UTIL_ImpactEffect either... additonally should avoid the effects if it's not a direct
			--hit. In the case it's not a direct hit a bullet goes flying off into the sunset.
			if CLIENT && !bIndirectHit then
				local hitbullet={};
				hitbullet.Num    = 1;
				hitbullet.Src    = shoot;
				hitbullet.Dir    = aim;
				hitbullet.Spread = Vector(0,0,0);
				hitbullet.Tracer = 0;
				hitbullet.Force  = self:Event("GetHitForce",1,traceRes);
				hitbullet.Damage = self:Event("GetHitDamage",1,traceRes);

				pOwner:FireBullets(hitbullet);
			end
		end
	else
		--If he missed, we'll display him missing and play a miss sound
		eWeapon:SendWeaponAnim(ACT_VM_MISSCENTER);
		self:MissSound(traceRes);
	end
	
	self:AddViewKick(self.ViewKickMin,self.ViewKickMax);
	return true;
end

--[[
* SHARED
* Event

This event should return how far your melee attack with this weapon reaches. Maybe a breakable
sword would swing longer when whole, and shorter when broken?
]]--
function ITEM:GetHitRange()
	return self.HitRange;
end

--[[
* SHARED
* Event

This event should return the amount of force that is applied to the target.
The default is based off of Source's model, where enough force to propel a
75 kg man at 4 in / sec (75*4 = 300) per point of damage (and scaled by the hit force scalar)
is applied.
]]--
function ITEM:GetHitForce(traceRes)
	return 300 * self:Event("GetHitDamage",0,traceRes) * self.HitForce;
end

--[[
* SHARED
* Event

This event should return the amount of damage that is applied to the target.
You could potentially use it for damaging things differently depending on what was hit.
]]--
function ITEM:GetHitDamage(traceRes)
	return self.HitDamage;
end

--[[
* SHARED
* Event

This event should determine if hitting an entity is valid, returning true if it is,
or false if it isn't.

If a hit is invalid, the weapon misses.

vShoot should be the player's shoot position.
vAimDir should be a normalized vector pointing the direction the player is facing.
eHit should be the entity hit.

]]--
function ITEM:IsValidHit(vShoot,vAimDir,eHit)
	local vCenter=eHit:LocalToWorld(eHit:OBBCenter());
	--Did this occur within the hit range and within a 90 degree cone from the player's view
	return vShoot:Distance(vCenter) <= self:Event("GetHitRange",75)+eHit:BoundingRadius() && (vAimDir:Dot(vCenter-vShoot)<0.70721);
end

--[[
* SHARED

Punches the player's view around by a random amount.
min and max are angles, representing the minimum and maximum angle
]]--
function ITEM:AddViewKick(min,max)
	local pl=self:GetWOwner();
	if !pl then return false end
	
	pl:ViewPunch(Angle(math.Rand(min.p,max.p),math.Rand(min.y,max.y),math.Rand(min.r,max.r)));
end

--[[
* SHARED
* Event

This function is called when the weapon needs a hit sound played.
traceRes is a full trace results table, containing information regarding the shot.
]]--
function ITEM:HitSound(traceRes)
	return self:EmitSound(self.HitSounds,true);
end

--[[
* SHARED
* Event

This function is called when the weapon needs a miss sound played.
traceRes is a full trace results table, containing information regarding the miss.
	Even though a valid entity wasn't hit, the trace results table still has information
	like where the attack missed.
]]--
function ITEM:MissSound(traceRes)
	return self:EmitSound(self.MissSounds,true);
end

--[[
* SHARED
* Event

When the melee weapon hits something, this is called. This is before damage is applied.
You can use this hook to give a special function to your weapon, like healing other items or players, for example.
hitent is the entity hit. This may be nil or invalid so make sure to check for that with IsValid.
hitpos is the position something was hit.
traceRes is a full trace result table, it has everything that's normally in a trace result:
	FractionLeftSolid,HitNonWorld,Fraction,Entity,HitNoDraw,HitSky,HitPos,StartSolid,HitWorld,HitGroup,HitNormal,HitBox,Normal,Hit,MatType,StartPos,PhysicsBone

Return false to do damage (fires an invisible bullet).
Return true to not do damage (doesn't fire an invisible bullet).
]]--
function ITEM:OnHit(pOwner,hitent,hitpos,traceRes)
	return false;
end

if SERVER then




--[[
* SERVER
* Event

This event runs when an NPC weilds this item as a weapon. This function should tell the NPC
how he's allowed to use the weapon.

Since this is a melee weapon we return that he's allowed to use attack 1.
]]--
function ITEM:GetSWEPCapabilities()
	return CAP_WEAPON_MELEE_ATTACK1;
end




end