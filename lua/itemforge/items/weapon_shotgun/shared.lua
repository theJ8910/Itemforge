--[[
weapon_shotgun
SHARED

The Itemforge version of the Half-Life 2 Shotgun.
This shotgun is heavily based off of the HL2 Shotgun's modcode.
Delays are taken from the SequenceDuration() of the viewmodel animations.
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name						= "Franchi SPAS-12";
ITEM.Description				= "This is a Franchi SPAS-12, a double-barrelled combat shotgun.\nThis weapon can fire up to two shells at once.\nThis shotgun can be loaded with any 12 gauge shotgun shells.";
ITEM.Base						= "base_firearm";
ITEM.Weight						= 4400;										--Based on http://half-life.wikia.com/wiki/SPAS-12_(HL2) and http://en.wikipedia.org/wiki/Franchi_SPAS-12
ITEM.Size						= 19;
ITEM.WorldModel					= "models/weapons/w_shotgun.mdl";
ITEM.ViewModel					= "models/weapons/v_shotgun.mdl";

if SERVER then




ITEM.GibEffect					= "metal";




end

ITEM.Spawnable					= true;
ITEM.AdminSpawnable				= true;

ITEM.SWEPHoldType				= "shotgun";

--Overridden Base Weapon stuff
ITEM.HasPrimary					= true;
ITEM.PrimaryDelay				= 0.33333334326744;
ITEM.PrimarySounds				= Sound( "Weapon_Shotgun.Single" );

ITEM.HasSecondary				= true;
ITEM.SecondaryDelay				= 0.5;
ITEM.SecondarySounds			= Sound( "Weapon_Shotgun.Double" );

--Overridden Base Ranged Weapon stuff
ITEM.Clips						= {};
ITEM.Clips[1]					= { Type = "ammo_buckshot", Size = 6 };

ITEM.PrimaryClip				= 1;
ITEM.PrimaryTakes				= 1;
ITEM.PrimaryFiresUnderwater		= false;

ITEM.SecondaryClip				= 1;
ITEM.SecondaryTakes				= 2;
ITEM.SecondaryFiresUnderwater	= false;

ITEM.ReloadsSingly				= true;
ITEM.ReloadDelay				= 0.5;										--Every time a shell is loaded it's a half-second cooldown
ITEM.ReloadStartDelay			= 0.5;										--Before we start loading shells, we have to cooldown for this long
ITEM.ReloadFinishDelay			= 0.43333333730698;							--After all the shells have been loaded we can't attack for this long
ITEM.ReloadSounds = {														--Finally! A chance to take advantage of multiple reload sounds!
	Sound( "weapons/shotgun/shotgun_reload1.wav" ),
	Sound( "weapons/shotgun/shotgun_reload2.wav" ),
	Sound( "weapons/shotgun/shotgun_reload3.wav" )
}

ITEM.DryFireDelay				= 0.33333334326744;
ITEM.DryFireSounds				= { Sound( "Weapon_Shotgun.Empty" ) };

--Overridden Base Firearm stuff
ITEM.BulletDamage				= 4;										--Each pellet does this much damage; not much on it's own, but luckily we have several pellets per shot
ITEM.BulletsPerShot				= 7;										--The shotgun's primary fires 7 distinct pellets per shot
ITEM.BulletSpread				= Vector( 0.08716, 0.08716, 0.08716 );		--Unfortunately they have 10 degrees deviation
ITEM.ViewKickMin				= Angle( -2, -2, 0 );						--The shotgun's primary kicks this much
ITEM.ViewKickMax				= Angle( -1, 2, 0 );

--Shotgun Weapon
ITEM.BulletsPerShotSec			= 12;										--WHAT? The shotgun's secondary takes two shells and only shoots 12 pellets?!
ITEM.ViewKickMinSec				= Angle( -5, 0, 0 );							--The secondary kicks more than primary
ITEM.ViewKickMaxSec				= Angle( 5, 0, 0 );

ITEM.PumpDelay					= 0.53333336114883;
ITEM.PumpSound					= Sound( "Weapon_Shotgun.Special1" );
ITEM.ShellEjectAngle			= Angle( 0, 90, 0 );

--[[
* SHARED
* Event

The shotgun's primary attack does everything the base_firearm does, but it's behavior is modified a little bit.
Since it's a shotgun it needs to be pumped before it can be fired again.
]]--
function ITEM:OnSWEPPrimaryAttack()
	local pAmmo = self:GetAmmoSource( self.PrimaryClip );
	
	--If we're reloading, we wait until we have enough ammo, then we stop the reload and attack
	if self:GetNWBool( "InReload" ) then
		if !pAmmo || pAmmo:GetAmount() < self.PrimaryTakes then return false end
		self:SetNWBool( "InReload", false );
		self:SetNextBoth( 0 );
	end
	
	--Can't attack if we need to pump the shotgun
	if self:GetNWBool( "NeedsPump" ) || !self:BaseEvent( "OnSWEPPrimaryAttack", false ) then return false end
	
	self:SetNWBool( "NeedsPump", true );
	return true;
end

--[[
* SHARED
* Event

The shotgun's secondary attack is pretty much the same thing as it's primary attack except it shoots more bullets and does more kick or whatever
]]--
function ITEM:OnSWEPSecondaryAttack()
	local itemCurAmmo = self:GetAmmoSource( self.SecondaryClip );
	local notEnoughAmmo = ( !itemCurAmmo || itemCurAmmo:GetAmount() < self.SecondaryTakes );
	
	--If we're reloading, we wait until we have enough ammo, then we stop the reload and attack
	if self:GetNWBool( "InReload" ) then
		if notEnoughAmmo then return false end
		
		self:SetNWBool( "InReload", false );
		self:SetNextBoth( 0 );
	
	--We're not reloading, that means we can attack immediately.
	--If it turns out we don't have enough ammo for the secondary attack, we try to do a primary attack instead.
	elseif notEnoughAmmo then
		return self:Event( "OnSWEPPrimaryAttack", false );
	end
	
	--Can't attack if we need to pump the shotgun
	if self:GetNWBool( "NeedsPump" ) || !self:BaseEvent( "OnSWEPSecondaryAttack", false ) then return false end
	
	self:ShootBullets( self:Event( "GetBulletsPerShot",	1,			itemCurAmmo ),
					   self:Event( "GetBulletDamage",	12,			itemCurAmmo ),
					   self:Event( "GetBulletForce",	1,			itemCurAmmo ),
					   self:Event( "GetBulletSpread",	vZero,		itemCurAmmo ),
					   self:Event( "GetBulletTracer",	"Tracer",	itemCurAmmo ),
					   self:Event( "GetBulletCallback",	nil,		itemCurAmmo )
					 );
	self:MuzzleFlash();
	self:AddViewKick( self.ViewKickMinSec, self.ViewKickMaxSec );
	
	self:SetNWBool( "NeedsPump", true );
	return true;
end

--[[
* SHARED
* Event

If the shotgun needs to be pumped we'll do that
]]--
function ITEM:OnSWEPThink()
	self:BaseEvent( "OnSWEPThink" );
	if self:GetNWBool( "NeedsPump" ) then
		--The shotgun has something called "delayed reload"; if the player presses reload before the shotgun is pumped, then the shotgun reloads after pumping.
		local plOwner = self:GetWOwner();
		if plOwner && plOwner:KeyDownLast( IN_RELOAD ) then
			self:SetNWBool( "DelayedReload", true );
		end
		
		self:Pump();
	end
end

--[[
* SHARED
* Event

If the shotgun needs to be pumped (while in the world / an inventory) we'll do that
]]--
function ITEM:OnThink()
	self:BaseEvent( "OnThink" );
	if self:GetNWBool( "NeedsPump" ) then
		self:Pump();
	end
end

--[[
* SHARED

Adds a shotgun reload start animation
]]--
function ITEM:StartReload( pl )
	if !self:BaseEvent( "StartReload", false, pl ) then return false end
	
	local eWep = self:GetWeapon();
	if eWep then
		self:SendWeaponAnim( ACT_SHOTGUN_RELOAD_START );
	end
	
	return true;
end

--[[
* SHARED

Adds a shotgun reload finish animation
]]--
function ITEM:FinishReload()
	if !self:BaseEvent( "FinishReload", false ) then return false end

	local eWep = self:GetWeapon();
	if eWep then
		self:SendWeaponAnim( ACT_SHOTGUN_RELOAD_FINISH );
	end
	
	return true;
end

--[[
* SHARED

Pumps the shotgun (ejects the spent shell allowing the next attack to proceed).
We can't pump if we're cooling down from an attack.
]]--
function ITEM:Pump()
	--Can't pump while we're cooling down
	if !self:CanPrimaryAttack() || !self:CanSecondaryAttack() then return false end
	
	--If the weapon is being held by a player, we don't pump unless the player has us out
	local eWep = self:GetWeapon();
	if eWep && self:GetWOwner():GetActiveWeapon() != eWep then return false end
	
	--Do pump effects & cooldown
	if SERVER && self:InWorld() then self:SendNWCommand( "ShellEject" ); end
	self:EmitSound( self.PumpSound, true );
	self:SetNWBool( "NeedsPump", false );
	self:SetNextBoth( CurTime() + self.PumpDelay );

	--If we were waiting on a delayed reload, do that instead of playing the pump animation
	if self:GetNWBool( "DelayedReload" ) then
		self:SetNWBool( "DelayedReload", false );
		self:Event( "StartReload", false );
	else
		if !eWep then return true end
		self:SendWeaponAnim( ACT_SHOTGUN_PUMP );	
	end
		
	return true;
end

IF.Items:CreateNWVar( ITEM, "NeedsPump",		"bool", false, nil, true, true );
IF.Items:CreateNWVar( ITEM, "DelayedReload",	"bool", false, nil, true, true );

if SERVER then

IF.Items:CreateNWCommand( ITEM, "ShellEject" );

else

--[[
* CLIENT

Ejects a shell from the shotgun.

Returns true if a shell was ejected,
Otherwise, returns false.
]]--
function ITEM:ShellEject()
	local eEnt = self:GetEntity();
	if !eEnt then return false end

	local effectdata = EffectData();
	effectdata:SetOrigin( eEnt:GetPos() );
	effectdata:SetAngle( eEnt:LocalToWorldAngles( self.ShellEjectAngle ) );
    util.Effect( "ShotgunShellEject", effectdata );
	
	return true;
end

IF.Items:CreateNWCommand( ITEM, "ShellEject", function( self ) self:ShellEject() end );

end