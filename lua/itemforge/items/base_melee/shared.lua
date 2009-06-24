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
ITEM.HitForce=5;					--When a physics object is hit, it's hit with "x" times more power than it would if a bullet hit it.
ITEM.ViewKickMin=Angle(0,0,0);
ITEM.ViewKickMax=Angle(0,0,0);

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

if SERVER then
	ITEM.HoldType="melee";
end

function ITEM:OnPrimaryAttack()
	--We do base_weapon's primary attack (it handles the cooldown and tells us if we can attack or not)
	if !self["base_weapon"].OnPrimaryAttack(self) then return false end
	
	local eWeapon=self:GetWeapon();
	local pOwner=self:GetWOwner();
	
	--We play the player's attack animation
	pOwner:SetAnimation(PLAYER_ATTACK1);
	
	--We have to figure out if the player hit something before dealing damage.
	local tr={};
	tr.start=pOwner:GetShootPos();
	tr.endpos=tr.start+(pOwner:GetAimVector()*self:GetHitRange());
	tr.filter=pOwner;
	tr.mask=MASK_SHOT;
	local traceRes=util.TraceLine(tr);
	
	if traceRes.Hit then
		--If he hit, we'll display his weapon hitting, play a hit sound, and then it's up to the weapon to decide what happens
		eWeapon:SendWeaponAnim(ACT_VM_HITCENTER);
		self:HitSound(traceRes);
		
		if !self:OnHit(pOwner,traceRes.Entity,traceRes.HitPos,traceRes) then
			hitbullet={};
			hitbullet.Num    = 1;
			hitbullet.Src    = tr.start;
			hitbullet.Dir    = pOwner:GetAimVector();
			hitbullet.Spread = Vector(0,0,0);
			hitbullet.Tracer = 0;
			hitbullet.Force  = self:GetHitForce(pOwner,traceRes.Entity);
			hitbullet.Damage = self:GetHitDamage(pOwner,traceRes.Entity);
			
			pOwner:FireBullets(hitbullet);
			
		end
	else
		--If he missed, we'll display him missing and play a miss sound
		eWeapon:SendWeaponAnim(ACT_VM_MISSCENTER);
		self:MissSound();
	end
	self:AddViewKick(self.ViewKickMin,self.ViewKickMax);
	return true;
end

function ITEM:GetHitRange()
	return self.HitRange;
end

function ITEM:GetHitForce()
	return self.HitForce;
end

function ITEM:GetHitDamage()
	return self.HitDamage;
end

function ITEM:AddViewKick(min,max)
	if !self:IsHeld() then return false end
	self:GetWOwner():ViewPunch(Angle(math.Rand(min.p,max.p),math.Rand(min.y,max.y),math.Rand(min.r,max.r)));
end

function ITEM:MissSound()
	return self:EmitSound(self.MissSounds[math.random(1,#self.MissSounds)]);
end

function ITEM:HitSound(traceRes)
	return self:EmitSound(self.HitSounds[math.random(1,#self.HitSounds)]);
end

--[[
When the melee weapon hits something, this is called. This is before damage is applied.
You can use this hook to give a special function to your weapon, like healing other items or players, for example.
hitent is the entity hit. This may be nil or invalid so make sure to check for that with IsValid.
Hitpos is the position something was hit.
traceRes is a full trace result table, it has everything that's normally in a trace result (FractionLeftSolid,HitNonWorld,Fraction,Entity,HitNoDraw,HitSky,HitPos,StartSolid,HitWorld,HitGroup,HitNormal,HitBox,Normal,Hit,MatType,StartPos,PhysicsBone)

Return false to do damage (fires an invisible bullet).
Return true to not do damage (doesn't fire an invisible bullet).
]]--
function ITEM:OnHit(pOwner,hitent,hitpos,traceRes)
	return false;
end