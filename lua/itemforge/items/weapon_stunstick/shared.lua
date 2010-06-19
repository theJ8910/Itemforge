--[[
weapon_stunstick
SHARED

Pick up that can
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Stunstick";
ITEM.Description="An electrical melee weapon similiar to a cattle prod.\nCombine Civil Protection often employ these batons when dealing with uncooperative citizens.";
ITEM.Base="base_melee";
ITEM.Size=12;
ITEM.Weight=1300;

ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

ITEM.WorldModel="models/weapons/W_stunbaton.mdl";
ITEM.ViewModel="models/weapons/v_stunstick.mdl";

if SERVER then
	ITEM.GibEffect = "metal";
end

--Overridden Base Weapon stuff
ITEM.PrimaryDelay=.9;

--Overridden Base Melee stuff
ITEM.HitRange=75;
ITEM.HitForce=2;
ITEM.HitDamage=40;
ITEM.ViewKickMin=Angle(1.0,-2.0,0);
ITEM.ViewKickMax=Angle(2.0,-1.0,0);

ITEM.HitSounds={
	Sound("weapons/stunstick/stunstick_fleshhit1.wav"),
	Sound("weapons/stunstick/stunstick_fleshhit2.wav"),
	Sound("weapons/stunstick/stunstick_impact2.wav"),
}

ITEM.MissSounds={
	Sound("weapons/stunstick/stunstick_swing1.wav"),
	Sound("weapons/stunstick/stunstick_swing2.wav"),
}

--Stunstick
ITEM.DeploySounds={
	Sound("weapons/stunstick/spark1.wav"),
	Sound("weapons/stunstick/spark2.wav"),
	Sound("weapons/stunstick/spark3.wav"),
}

function ITEM:OnSWEPDeploy()
	if !self["base_melee"].OnSWEPDeploy(self) then return false end
	self:EmitSound(self.DeploySounds,true);
	
	return true;
end

function ITEM:OnSWEPHolster()
	if !self["base_melee"].OnSWEPHolster(self) then return false end
	
	--This isn't a mistake. The holster sounds are the same as the deploy sounds.
	self:EmitSound(self.DeploySounds,true);
	
	return true;
end