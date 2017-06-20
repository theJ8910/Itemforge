--[[
weapon_ar2
SHARED

The Itemforge version of the Half-Life 2 Pulse Rifle.
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name						= "Pulse Rifle";
ITEM.Description				= "A futuristic assult rifle employed by the Combine.\nThe Pulse Rifle is standard issue to all Overwatch infantry.\nThis rifle is designed to fire Pulse Ammunition.\nA combine energy ball launcher is attached.";
ITEM.Base						= "base_machinegun";
ITEM.Weight						= 5400;
ITEM.Size						= 26;

ITEM.Spawnable					= true;
ITEM.AdminSpawnable				= true;

ITEM.WorldModel					= "models/weapons/w_IRifle.mdl";
ITEM.ViewModel					= "models/weapons/v_IRifle.mdl";

if SERVER then




ITEM.GibEffect					= "metal";




end

ITEM.SWEPHoldType				= "ar2";

--Overridden Base Weapon stuff
ITEM.HasPrimary					= true;
ITEM.PrimaryDelay				= 0.1;									--Taken directly from the modcode.
ITEM.PrimarySounds				= Sound( "Weapon_AR2.Single" );

ITEM.HasSecondary				= false;
ITEM.SecondarySounds			= nil;

--Overridden Base Ranged Weapon stuff
ITEM.Clips						= {};
ITEM.Clips[1]					= { Type = "ammo_ar2",			Size = 30 };
ITEM.Clips[2]					= { Type = "ammo_ar2_altfire",	Size = 1, BackColor = Color( 0, 115, 183 ), BarColor = Color( 0, 159, 255 ) };

ITEM.PrimaryClip				= 1;
ITEM.PrimaryFiresUnderwater		= false;

ITEM.SecondaryClip				= 2;
ITEM.SecondaryFiresUnderwater	= true;


ITEM.ReloadDelay				= 1.5666667222977;
ITEM.ReloadSounds				= {										--The viewmodel is responsible for playing the reload sounds
}

ITEM.DryFireSounds				= {
	Sound( "Weapon_AR2.Empty" )
}

--Overridden Base Firearm stuff
ITEM.BulletDamage				= 11;
ITEM.BulletSpread				= Vector( 0, 0, 0 );					--Taken directly from modcode
ITEM.BulletTracer				= "AR2Tracer";
ITEM.ViewKickMin				= Angle( 0, 0, 0 );						--Taken directly from modcode (TODO: There IS viewkick. I'll have to look into it.)
ITEM.ViewKickMax				= Angle( 0, 0, 0 );

--[[
* SHARED
* Event

Secondary attack fires a combine ball but right now it does nothing
]]--
function ITEM:OnSWEPSecondaryAttack()
end