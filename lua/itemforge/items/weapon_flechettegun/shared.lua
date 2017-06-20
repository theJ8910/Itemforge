--[[
weapon_flechettegun
SHARED

A gun that fires hunter flechettes.
Adapted from the GMod flechette gun.
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name				= "Flechette Gun";
ITEM.Description		= "A standard pistol, modified to fire hunter flechettes instead.";
ITEM.Base				= "base_ranged";
ITEM.Weight				= 850;							--This is somewhat arbitrary. It's heavier than the H&K USP Match, which the Flechette Gun resembles somewhat.
ITEM.Size				= 7;
ITEM.ViewModel			= "models/weapons/v_pistol.mdl";
ITEM.WorldModel			= "models/weapons/w_pistol.mdl";

if SERVER then




ITEM.GibEffect			= "metal";




end

ITEM.Spawnable			= true;
ITEM.AdminSpawnable		= true;

--Overridden Base Weapon stuff
ITEM.HasPrimary			= true;
ITEM.PrimaryDelay		= 0.1;
ITEM.PrimarySounds		= Sound( "NPC_Hunter.FlechetteShoot" );

--Overridden Base Ranged stuff
ITEM.Clips				= {};
ITEM.Clips[1]			= { Type = "ammo_flechette", Size = 30 };
ITEM.PrimaryClip		= 1;

--[[
* SHARED
* Event

The gun's primary attack fires a flechette.
]]--
function ITEM:OnPrimaryAttack()
	self:ShootFlechette( 2000 );
end

--[[
* SHARED

Fires a flechette from the gun at the given speed.
Doesn't consume ammo, just fires a flechette.

Clientside, this function does nothing; flechettes must be created on the server.
If something is killed by the flechette...
	If this gun is held, kill credit goes to the player holding this gun.
	If this gun is in the world, kill credit goes to the gun entity.

fSpeed should be the speed you want to fire the flechette at (in game units / sec).

Returns true if a flechette was created and fired.
Otherwise, returns false.
]]--
function ITEM:ShootFlechette( fSpeed )
	if CLIENT then return false end
	
	local vPos, aAng, eOwner = self:GetFireOriginAngles();
	if !vPos then return false end

	local eFlechette = ents.Create( "hunter_flechette" );
	if !eFlechette:IsValid() then return false end

	local vFwd = aAng:Forward();
	eFlechette:SetPos( vPos + 32 * vFwd );
	eFlechette:SetAngles( aAng );
	eFlechette:SetVelocity( fSpeed * vFwd );
	eFlechette:SetOwner( eOwner );
	eFlechette:Spawn();

	return true;
end
