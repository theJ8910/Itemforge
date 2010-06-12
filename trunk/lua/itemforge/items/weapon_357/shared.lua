--[[
weapon_357
SHARED

The Itemforge version of the Half-Life 2 .357 revolver.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Colt Python";
ITEM.Description="This is a Colt Python, a .357 revolver.\nThis weapon is designed for use with .357 rounds.";
ITEM.Base="base_firearm";
ITEM.Weight=1360;			--48 oz from http://half-life.wikia.com/wiki/.357_Magnum and http://en.wikipedia.org/wiki/Colt_Python
ITEM.Size=13;

ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

ITEM.WorldModel="models/weapons/W_357.mdl";
ITEM.ViewModel="models/weapons/v_357.mdl";

--Overridden Base Weapon stuff
ITEM.PrimaryDelay=.75;									--Taken directly from the modcode.

--Overridden Base Ranged Weapon stuff
ITEM.Clips={};
ITEM.Clips[1]={Type="ammo_357",Size=6};

ITEM.PrimaryClip=1;
ITEM.PrimaryFiresUnderwater=false;
ITEM.PrimaryFireSounds={								--These sound identical to me, but what the hell.
	Sound("weapons/357/357_fire2.wav"),
	Sound("weapons/357/357_fire3.wav")
};

ITEM.ReloadDelay=3.6666667461395;
ITEM.ReloadSounds={										--The viewmodel is responsible for playing the reload sounds
}

--Overridden Base Firearm stuff
ITEM.BulletDamage=75;
ITEM.BulletSpread=Vector(0,0,0);						--Taken directly from modcode; this is 0 degrees. The .357 is perfectly accurate.
ITEM.ViewKickMin=Angle(-8,-2,0);						--Taken directly from modcode. The view kicks up.
ITEM.ViewKickMax=Angle(-8,2,0);

function ITEM:OnSWEPPrimaryAttack()
	if !self["base_firearm"].OnSWEPPrimaryAttack(self) then return false end
	
	--We need to snap the holding player's eyes on the server;
	--if we can't do that for some reason just return true to indicate everything else went as planned
	if CLIENT || !self:IsHeld() then return true end
	local pl=self:GetWOwner();
	
	ang=pl:GetLocalAngles()
	ang.p=ang.p+math.random(-1,1);
	ang.y=ang.y+math.random(-1,1);
	ang.r=0;
	
	pl:SnapEyeAngles(ang);
end

function ITEM:OnSWEPSecondaryAttack()
	--Secondary attack does NOTHING
end