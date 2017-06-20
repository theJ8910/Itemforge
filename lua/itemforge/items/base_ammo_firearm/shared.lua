--[[
base_ammo_firearm
SHARED

base_ammo_firearm is a base. That means that other items borrow code from this so they can be created easier.
Any item that inherits from this has everything this item has, and can override anything this item has.

The base_ammo_firearm item's purpose is to create some basic stuff that all firearm ammo has in common.
Additionally, you can tell if something is firearm ammunition by seeing if it's based off of this item.
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name				= "Base Firearm Ammunition";
ITEM.Description		= "This item is the base firearm ammunition.\nAll firearm ammunition inherits from this.\n\nThis is not supposed to be spawned.";
ITEM.Base				= "base_ammo";

--We don't want players spawning it.
ITEM.Spawnable			= false;
ITEM.AdminSpawnable		= false;

--Base Firearm Ammo
ITEM.FireOnBreakChance	= 4;								--Bullets have a ( 1 / ITEM.FireOnBreakChance ) chance of firing a bullet when the bullet is damaged 
ITEM.BulletSounds		= nil;								--This sound plays when a bullet is fired

ITEM.BulletsPerShot		= 1;								--How many bullets/fragments are fired from a single shot of this kind of ammo? This is usually one, but may be more: Think shotgun.
ITEM.BulletDamage		= 12;								--How much damage do invidual bullets/fragments of this type do?
ITEM.BulletForce		= 1;								--This is a bullet impact force multiplier. Higher numbers knock around physics objects more.
ITEM.BulletSpread		= Vector( 0, 0, 0 );				--What is the maximum amount bullets deviate from the direction they're aimed at? This appears to take a vector, whose x, y, and z are positive half-angles in radians. So, if you wanted a 3 degree spread cone, you'd divide 3 by 2 and then convert that to radians; then replace x in Vector( x, x, x ) with that value.
ITEM.BulletCallback		= nil;
ITEM.BulletTracer		= "Tracer";							--What do you see when bullets of this type are fired?
ITEM.BulletHL2AmmoType	= nil;								--Given to ShootBullets. Mostly only useful for HL2 Weapons; leave nil unless making a weapon based off the HL2 weapon. See the description for iAmmoType in the ShootBullets function in base_item/shared.lua for more information.

local vZero = Vector( 0, 0, 0 );

--[[
* SHARED
* Event

This event determines what sound should be played when a bullet is fired.
If it returns:
	nil or an empty table:				no sound is played
	a Sound( "filepath.wav" ):			that sound is played
	a table of Sound( "filepath.wav" ):	a random sound from that table is played
]]--
function ITEM:GetBulletSound()
	return self.BulletSounds;
end

if SERVER then




--[[
* SERVER
* Event

If ammunition is destroyed, there is a random chance bullets will go flying
]]--
function ITEM:OnBreak( iHowMany, bLastBroke, eWho )
	local eEntity = self:GetEntity();
	if !eEntity then return false end

	local iNumFired = 0;
	debug.Trace();

	for i = 1, iHowMany do
		
		if math.random( 1, self.FireOnBreakChance ) == 1 then
			iNumFired = iNumFired + 1;
			self:ShootBullets( eEntity:GetPos(), IF.Util:RandomAngle():Forward(), eEntity,
							   self.BulletsPerShot,
							   self.BulletDamage,
							   self.BulletForce,
							   self.BulletSpread,
							   self.BulletTracer,
							   self.BulletCallback,
							   self.BulletHL2AmmoType
							 );
		end
	end

	if iNumFired > 0 then self:EmitSound( self:Event( "GetBulletSound" ), nil, 100 + math.min( iNumFired - 1, 4 ) * 38.75 ) end

	self:BaseEvent( "OnBreak", nil, iHowMany, bLastBroke, eWho );
end




end