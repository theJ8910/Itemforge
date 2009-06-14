--[[
base_firearm
SHARED

base_firearm is a base. That means that other items borrow code from this so they can be created easier.
Any item that inherits from this has everything this item has, and can override anything this item has.

The base_firearm has two purposes:
	It's designed to help you create traditional firearms (guns that fire bullets - pistols, machine guns, miniguns, rifles, etc) easier. You just have to change/override some variables or replace some stuff with your own code.
	You can tell if an item is a firearm by checking to see if it inherits from base_firearm.

By default, firearms fire bullets with their primary attack.
Firearms' secondary attack is no different from base_ranged's secondary attack; it plays sounds and animations, does cooldown, takes ammo, etc.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

local ZeroVector=Vector(0,0,0);

ITEM.Name="Base Firearm";
ITEM.Description="This item is the base firearm.\nFirearms, such as pistols, rifles, etc, can inherit from this\nto make their creation easier.\n\nThis is not supposed to be spawned.";
ITEM.Base="base_ranged";

--We don't want players spawning it.
ITEM.Spawnable=false;
ITEM.AdminSpawnable=false;

--Base Firearm
ITEM.BulletDamage=12;								--How much damage do bullets fired from this weapon do?
ITEM.BulletsPerShot=1;								--How many bullets are fired with a single shot? This is usually one, but may be more: Think shotgun.
ITEM.BulletSpread=Vector(0,0,0);					--What is the maximum amount bullets deviate from the direction they're aimed at? This appears to take a vector, whose x,y, and z are positive half-angles in radians. So, if you wanted a 3 degree spread cone, you'd divide 3 by 2 and then convert that to radians; then replace x in Vector(x,x,x) with that value.
ITEM.ViewKickMin=Angle(0,0,0);						
ITEM.ViewKickMax=Angle(0,0,0);
--[[
When a player is holding it and tries to primary attack
]]--
function ITEM:OnPrimaryAttack()
	--This does all the base ranged stuff - determine if we can fire, do cooldown, consume ammo, play sounds, etc
	if !self["base_ranged"].OnPrimaryAttack(self) then return false end
	
	self:ShootBullets(self.BulletsPerShot,self.BulletDamage,1,self:GetBulletSpread());
	self:MuzzleFlash();
	self:AddViewKick(self.ViewKickMin,self.ViewKickMax);
	
	return true;
end

--[[
This function determines how much random spread the bullets have. By default, this returns self.Spread.
HEY! You can override this function if you don't like the way I do my bullet spread.
]]--
function ITEM:GetBulletSpread()
	return self.BulletSpread;
end

--[[
Fires bullets from this item. Doesn't consume ammo or play sounds or anything, just fires bullets.
]]--
function ITEM:ShootBullets(num,damage,force,spread)
	local bullet={
		Tracer=1,
		TracerName="Tracer",
		Num=num or 1,
		Spread=spread,
		Force=force,
		Damage=damage;
	};
	
	if self:IsHeld() then
		local pOwner=self:GetWOwner();
		
		bullet.Src		= pOwner:GetShootPos();
		bullet.Dir		= pOwner:GetAimVector();
		
		pOwner:FireBullets(bullet);
	elseif self:InWorld() then
		local eEnt=self:GetEntity();
		local posang=self:GetMuzzle();
		
		bullet.Src    = posang.Pos;
		bullet.Dir    = posang.Ang:Forward();
		
		eEnt:FireBullets(bullet);
	end
end

--[[
The weapon kicks the holding player's vier.
When the player fires a firearm, his view will be "kicked" (temporarily rotate and then snap back).
The angle that the player's view is kicked is random, between min and max.
No effect if not held.
]]--
function ITEM:AddViewKick(min,max)
	if !self:IsHeld() then return false end
	self:GetWOwner():ViewPunch(Angle(math.Rand(min.p,max.p),math.Rand(min.y,max.y),math.Rand(min.r,max.r)));
end

--[[
Makes a muzzle flash effect play on all clients.
Only works when the item is in the world
]]--
function ITEM:MuzzleFlash()
	if CLIENT || !self:InWorld() then return false end
	local posang=self:GetMuzzle();
	local effect = EffectData();
	effect:SetOrigin(posang.Pos);
	effect:SetAngle(posang.Ang);
	effect:SetScale(1);
	util.Effect("MuzzleEffect",effect,true,true);
	
	return true;
end