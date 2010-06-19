--[[
weapon_rpg
SHARED

The Itemforge version of the Half-Life 2 RPG Launcher.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="MBT LAW";
ITEM.Description="This is a Rocket Propelled Grenade launcher.\n This particular model is known as the Main Battle Tank and Light Armour Weapon, abbreviated MBT LAW.\nThis Swedish weapon was developed by Saab Bofors Dynamics.\nThis device has an optional targeting laser that can guide laser-guided RPGs.";
ITEM.Base="base_ranged";
ITEM.Weight=1160;				--Based upon http://www.army-technology.com/projects/mbt_law/
ITEM.Size=27;

ITEM.WorldModel="models/weapons/w_rocket_launcher.mdl";
ITEM.ViewModel="models/weapons/v_RPG.mdl";

if SERVER then
	ITEM.GibEffect = "metal";
end

ITEM.HoldType="rpg";

ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

--Overridden Base Weapon stuff
ITEM.PrimaryDelay=2;									--Taken directly from the modcode.

--Overridden Base Ranged Weapon stuff
ITEM.Clips={};
ITEM.Clips[1]={Type="ammo_rpg",Size=1};

ITEM.PrimaryClip=1;
ITEM.PrimaryFiresUnderwater=false;
ITEM.PrimaryFireSounds={								--These sound identical to me, but what the hell.
	Sound("weapons/357/357_fire2.wav"),
};

ITEM.ReloadDelay=3.6666667461395;
ITEM.ReloadSounds={										--There is no reload sound
}

ITEM.DryFireDelay=0.2;

function ITEM:OnSWEPPrimaryAttack()
	if !self["base_ranged"].OnSWEPPrimaryAttack(self) then return false end
	
	return true;
end

function ITEM:OnSWEPSecondaryAttack()
	if !self["base_ranged"].OnSWEPSecondaryAttack(self) then return false end
	
	--Secondary attack swaps firemode
	self:SetNWVar("LaserSight",!self:GetNWVar("LaserSight"));
	return true;
end

IF.Items:CreateNWVar(ITEM,"LaserSight","bool",true);