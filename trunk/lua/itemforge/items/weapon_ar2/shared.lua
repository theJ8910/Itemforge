--[[
weapon_ar2
SHARED

The Itemforge version of the Half-Life 2 Pulse Rifle.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Pulse Rifle";
ITEM.Description="A futuristic assult rifle employed by the Combine.\nThe Pulse Rifle is standard issue to all Overwatch infantry.\nThis rifle is designed to fire Pulse Ammunition.\nIt also seems there is a secondary attack mode.";
ITEM.Base="base_firearm";
ITEM.Weight=5400;
ITEM.Size=26;

ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

ITEM.WorldModel="models/weapons/w_IRifle.mdl";
ITEM.ViewModel="models/weapons/v_IRifle.mdl";

if SERVER then
	ITEM.HoldType="ar2";
end

--Overridden Base Weapon stuff
ITEM.PrimaryDelay=.1;									--Taken directly from the modcode.

--Overridden Base Ranged Weapon stuff
ITEM.Clips={};
ITEM.Clips[1]={Type="ammo_ar2",Size=30};
ITEM.Clips[2]={Type="ammo_combine_ball",Size=0};

ITEM.PrimaryClip=1;
ITEM.PrimaryFiresUnderwater=false;
ITEM.PrimaryFireSounds={
	Sound("weapons/ar2/fire1.wav")
};

ITEM.SecondaryClip=1;
ITEM.SecondaryFiresUnderwater=true;
ITEM.SecondaryFireSounds={
};

ITEM.ReloadDelay=1.5666667222977;
ITEM.ReloadSounds={										--The viewmodel is responsible for playing the reload sounds
}

ITEM.DryFireSounds={
	Sound("weapons/ar2/ar2_empty.wav")
}

--Overridden Base Firearm stuff
ITEM.BulletDamage=11;
ITEM.BulletSpread=Vector(0,0,0);						--Taken directly from modcode
ITEM.BulletTracer="AR2Tracer";
ITEM.ViewKickMin=Angle(0,0,0);							--Taken directly from modcode
ITEM.ViewKickMax=Angle(0,0,0);


function ITEM:OnPrimaryAttack()
	if !self["base_firearm"].OnPrimaryAttack(self) then return false end
end

function ITEM:OnSecondaryAttack()
	--Secondary attack fires a combine ball but right now it does nothing
end