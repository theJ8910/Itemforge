--[[
weapon_smg
SHARED

The Itemforge version of the Half-Life 2 SMG.
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name						= "H&K MP7";
ITEM.Description				= "This is a Heckler & Koch MP7, a German-manufactured submachine gun.\nThis weapon is designed for use with 4.6x30mm rounds.\nIt's also fitted with a grenade launcher.";
ITEM.Base						= "base_machinegun";
ITEM.WorldModel					= "models/weapons/w_smg1.mdl";
ITEM.ViewModel					= "models/weapons/v_smg1.mdl";
ITEM.Weight						= 1900;							--1.9kg according to http://en.wikipedia.org/wiki/Heckler_&_Koch_MP7
ITEM.Size						= 13;

if SERVER then




ITEM.GibEffect					= "metal";




end

ITEM.Spawnable					= true;
ITEM.AdminSpawnable				= true;

ITEM.SWEPHoldType				= "smg";

--Overridden Base Weapon stuff
ITEM.HasPrimary					= true;
ITEM.PrimaryDelay				= 0.075;								--Taken directly from modcode
ITEM.PrimarySounds				= Sound( "Weapon_SMG1.Single" );

ITEM.HasSecondary				= true;
ITEM.SecondaryDelay				= 1;									--Taken directly from modcode
ITEM.SecondarySounds			= Sound( "Weapon_SMG1.Double" );

--Overridden Base Ranged Weapon stuff
ITEM.Clips						= {};
ITEM.Clips[1]					= { Type = "ammo_smg",			Size = 45 };
ITEM.Clips[2]					= { Type = "ammo_smggrenade",	Size = 3, BackColor = Color( 0, 115, 183 ), BarColor = Color( 0, 159, 255 ) };

ITEM.PrimaryClip				= 1;
ITEM.PrimaryFiresUnderwater		= false;

ITEM.SecondaryClip				= 2;
ITEM.SecondaryFiresUnderwater	= false;
ITEM.SecondaryPlayerAnim		= PLAYER_ATTACK1;						--The secondary has the same player attack animation as the primary

ITEM.ReloadDelay				= 1.5;
ITEM.ReloadSounds				= Sound( "Weapon_SMG1.Reload" );

--Overridden Base Firearm stuff
ITEM.BulletDamage				= 12;
ITEM.BulletSpread				= Vector( 0.04362, 0.04362, 0.04362 );	--Taken directly from modcode; this is 5 degrees deviation

--[[
* SHARED
* Event

When a player is holding it and tries to secondary attack
]]--
function ITEM:OnSecondaryAttack()
	self:FireGrenade( 1000 );
	return true;
end

--[[
* SHARED

Fires a grenade from the gun at the given speed.
Doesn't consume ammo, just fires a grenade.

Clientside, this function does nothing; grenades must be created on the server.
If something is killed by the grenade...
	If this gun is held, kill credit goes to the player holding this gun.
	If this gun is in the world, kill credit goes to the gun entity.

fSpeed should be the speed you want to fire the flechette at (in game units / sec).

Returns true if a grenade was created and launched.
Otherwise, returns false.
]]--
function ITEM:FireGrenade( fSpeed )	
	if CLIENT then return false end

	local vPos, vDir, eOwner = self:GetFireOriginDir();
	if !vPos then return false end

	local eNade = ents.Create( "grenade_ar2" );
	if !eNade:IsValid() then return false end

	eNade:SetPos( vPos );
	eNade:SetVelocity( fSpeed * vDir );
	eNade:SetOwner( eOwner );
	eNade:Spawn();

	return true;
end