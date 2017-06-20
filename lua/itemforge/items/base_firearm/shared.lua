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

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name				= "Base Firearm";
ITEM.Description		= "This item is the base firearm.\nFirearms, such as pistols, rifles, etc, can inherit from this\nto make their creation easier.\n\nThis is not supposed to be spawned.";
ITEM.Base				= "base_ranged";

--We don't want players spawning it.
ITEM.Spawnable			= false;
ITEM.AdminSpawnable		= false;

--Base Firearm
ITEM.BulletDamage		= 12;							--How much damage do bullets fired from this weapon do?
ITEM.BulletForce		= 1;							--This is a bullet impact force multiplier. Higher numbers knock around physics objects more.
ITEM.BulletsPerShot		= 1;							--How many bullets are fired with a single shot? This is usually one, but may be more: Think shotgun.
ITEM.BulletSpread		= Vector( 0, 0, 0 );			--What is the maximum amount bullets deviate from the direction they're aimed at? This appears to take a vector, whose x, y, and z are positive half-angles in radians. So, if you wanted a 3 degree spread cone, you'd divide 3 by 2 and then convert that to radians; then replace x in Vector( x, x, x ) with that value.
ITEM.BulletCallback		= nil;
ITEM.BulletTracer		= "Tracer";						--What do you see when you fire bullets?
ITEM.BulletHL2AmmoType	= nil;							--Given to ShootBullets. Mostly only useful for HL2 Weapons; leave nil unless making a weapon based off the HL2 weapon. See the description for iAmmoType in the ShootBullets function in base_item/shared.lua for more information.

local vZero = Vector( 0, 0, 0 );

--[[
* SHARED
* Event

In addition to things that normally happen when a base_ranged weapon is fired,
when firearms attack they shoot bullets, do a muzzle-flash, and apply a view kick.
]]--
function ITEM:OnPrimaryAttack()
	self:DoBullets();
	self:MuzzleFlash();
	self:AddViewKick( self.ViewKickMin, self.ViewKickMax );
end

--[[
* SHARED
* Event

This function determines how many bullets are fired per shot.
By default, this returns self.BulletsPerShot.
]]--
function ITEM:GetBulletsPerShot( itemAmmo )
	return self.BulletsPerShot;
end

--[[
* SHARED
* Event

This function determines how much damage a single bullet does.
By default, this returns self.BulletDamage.
]]--
function ITEM:GetBulletDamage( itemAmmo )
	return self.BulletDamage;
end

--[[
* SHARED
* Event

This function determines the impact force modifier of a single bullet.
By defualt, this returns self.BulletForce.
]]--
function ITEM:GetBulletForce( itemAmmo )
	return self.BulletForce;
end

--[[
* SHARED
* Event

This function determines how much random spread the bullets have.
By default, this returns self.BulletSpread.
]]--
function ITEM:GetBulletSpread( itemAmmo )
	return self.BulletSpread;
end

--[[
* SHARED
* Event

This function determines the tracer (the visible trail) the bullet uses.
By default, this returns self.BulletTracer.
]]--
function ITEM:GetBulletTracer( itemAmmo )
	return self.BulletTracer;
end

--[[
* SHARED
* Event

This function determines the bullet callback function.
By default, this returns self.BulletCallback.
]]--
function ITEM:GetBulletCallback( itemAmmo )
	return self.BulletCallback;
end

--[[
* SHARED
* Event

This function determines the HL2 ammotype assigned to fired bullets.
By default, this returns self.BulletHL2AmmoType.
]]--
function ITEM:GetBulletHL2AmmoType( itemAmmo )
	return self.BulletHL2AmmoType;
end

--[[
* SHARED

Shortcut for standard bullet firing behavior
]]--
function ITEM:DoBullets()
	local itemAmmo = self:GetAmmoSource( self.PrimaryClip );
	local vPos, vDir, eKillCredit = self:GetFireOriginDir();
	self:ShootBullets( vPos, vDir, eKillCredit,
					   self:Event( "GetBulletsPerShot",		1,			itemAmmo ),
					   self:Event( "GetBulletDamage",		12,			itemAmmo ),
					   self:Event( "GetBulletForce",		1,			itemAmmo ),
					   self:Event( "GetBulletSpread",		vZero,		itemAmmo ),
					   self:Event( "GetBulletTracer",		"Tracer",	itemAmmo ),
					   self:Event( "GetBulletCallback",		nil,		itemAmmo ),
					   self:Event( "GetBulletHL2AmmoType",	nil,		itemAmmo )
					 );
end

--[[
* SHARED

Makes a muzzle flash effect play on all clients.

Only works when the item is in the world.
Does nothing and returns false if ran on the client.

Returns true if the muzzle flash effect was created,
or false otherwise.
]]--
function ITEM:MuzzleFlash()
	local eEntity = self:GetEntity();
	if CLIENT || !eEntity then return false end

	local posang = self:GetMuzzle( eEntity );
	local effect = EffectData();
	effect:SetOrigin( posang.Pos );
	effect:SetAngle( posang.Ang );
	effect:SetScale( 1 );
	util.Effect( "MuzzleEffect", effect, true, true );
	
	return true;
end