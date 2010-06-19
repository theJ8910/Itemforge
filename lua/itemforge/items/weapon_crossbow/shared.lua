--[[
weapon_crossbow
SHARED

The Itemforge version of the Half-Life 2 Crossbow.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Crossbow";
ITEM.Description="An unconvential, experimental weapon developed by the Resistance.\nA scope and industrial-sized battery is attached.\nRumor has it the weapon heats and launches bolts made of steel rebar.";
ITEM.Base="base_ranged";
ITEM.Weight=7000;				--Arbitrary.
ITEM.Size=30;

ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

ITEM.WorldModel="models/weapons/W_crossbow.mdl";
ITEM.ViewModel="models/weapons/v_crossbow.mdl";

if SERVER then
	ITEM.GibEffect = "metal";
end

ITEM.HoldType="crossbow";

--Overridden Base Weapon stuff
ITEM.PrimaryDelay=.1;

--Overridden Base Ranged Weapon stuff
ITEM.Clips={};
ITEM.Clips[1]={Type="ammo_crossbow",Size=1};

ITEM.PrimaryClip=1;
ITEM.PrimaryFiresUnderwater=true;
ITEM.PrimaryFireSounds={Sound("weapons/crossbow/fire1.wav")};

ITEM.ReloadDelay=1.8333333730698;
ITEM.ReloadSounds={
	Sound("weapons/crossbow/reload1.wav"),
	--weapons\crossbow\bolt_fly4.wav
	--weapons\crossbow\bolt_load1.wav
	--weapons\crossbow\bolt_load2.wav
	--weapons\crossbow\bolt_skewer1.wav
	--weapons\crossbow\fire1.wav
	--weapons\crossbow\hit1.wav
	--weapons\crossbow\hitbod1.wav
	--weapons\crossbow\hitbod2.wav
}

function ITEM:OnSWEPPrimaryAttack()
	if !self["base_ranged"].OnSWEPPrimaryAttack(self) then return false end
	
end

function ITEM:OnSWEPSecondaryAttack()
	--Secondary attack toggles scope zoom
end

--This is a big weapon size-wise. Items of size 30 or greater can't be held, so we make an exception here.
function ITEM:CanHold(pl)
	return true;
end