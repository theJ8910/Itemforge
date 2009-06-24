--[[
weapon_shotgun
SHARED

The Itemforge version of the Half-Life 2 Shotgun.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Shotgun";
ITEM.Description="This is a 12 gauge, double-barrelled combat shotgun.\nThis weapon can fire up to two shells at once.\nThis shotgun can be loaded with any 12 gauge shotgun shells.";
ITEM.Base="base_firearm";
ITEM.WorldModel="models/weapons/w_shotgun.mdl";
ITEM.ViewModel="models/weapons/v_shotgun.mdl";
ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;
if SERVER then
	ITEM.HoldType="shotgun";
end

--Overridden Base Weapon stuff
ITEM.PrimaryDelay=0.33333334326744;
ITEM.SecondaryDelay=.5;

--Overridden Base Ranged Weapon stuff
ITEM.Clips={};
ITEM.Clips[1]={Type="ammo_buckshot",Size=6};

ITEM.PrimaryClip=1;
ITEM.PrimaryTakes=1;
ITEM.PrimaryFiresUnderwater=false;
ITEM.PrimaryFireSounds={Sound("weapons/shotgun/shotgun_fire7.wav")};
ITEM.PrimaryEmptySounds={Sound("weapons/shotgun/shotgun_empty.wav")};

ITEM.SecondaryClip=1;
ITEM.SecondaryTakes=2;
ITEM.SecondaryFiresUnderwater=false;
ITEM.SecondaryFireSounds={Sound("weapons/shotgun/shotgun_dbl_fire7.wav")};
ITEM.SecondaryEmptySounds={Sound("weapons/shotgun/shotgun_empty.wav")};

ITEM.ReloadsSingly=true;
ITEM.ReloadDelay=0.5;
ITEM.ReloadStartDelay=0.5;
ITEM.ReloadFinishDelay=0.43333333730698;
ITEM.ReloadSounds={										--Finally! A chance to take advantage of multiple reload sounds!
	Sound("weapons/shotgun/shotgun_reload1.wav"),
	Sound("weapons/shotgun/shotgun_reload2.wav"),
	Sound("weapons/shotgun/shotgun_reload3.wav")
}

--Overridden Base Firearm stuff
ITEM.BulletDamage=4;
ITEM.BulletsPerShot=6;
ITEM.BulletSpread=Vector(0.08716,0.08716,0.08716);		--Taken directly from modcode; this is 10 degrees deviation
ITEM.ViewKickMin=Angle(-2,-2,0);
ITEM.ViewKickMax=Angle(-1,2,0);

--Shotgun Weapon
ITEM.PumpDelay=0.53333336114883;
ITEM.PumpSound=Sound("weapons/shotgun/shotgun_cock.wav");
ITEM.ViewKickMinSec=Angle(-5,0,0);						--The secondary kicks more than primary
ITEM.ViewKickMaxSec=Angle(5,0,0);

--[[
The shotgun's primary attack does everything the base_firearm does,
but we also require that the shotgun be pumped before the next attack.
]]--
function ITEM:OnPrimaryAttack()
	if self:GetNWBool("NeedsPump") || !self["base_firearm"].OnPrimaryAttack(self) then return false end
	
	self:SetNWBool("NeedsPump",true)
end

--[[
The shotgun's secondary attack is pretty much the same thing as base_firearm's primary attack,
except we shoot twice as many bullets; we also have a more intense kick.
We require that the shotgun be pumped before the next attack.
]]--
function ITEM:OnSecondaryAttack()
	--If we don't have two shells we'll just try to do a normal attack instead
	local sAmmo=self:GetAmmo(self.SecondaryClip);
	if sAmmo && sAmmo:GetAmount()<self.SecondaryTakes then return self:OnPrimaryAttack(); end
	
	if self:GetNWBool("NeedsPump") || !self["base_firearm"].OnSecondaryAttack(self) then return false end
	
	self:ShootBullets(self.BulletsPerShot*2,self.BulletDamage,1,self:GetBulletSpread());
	self:MuzzleFlash();
	self:AddViewKick(self.ViewKickMinSec,self.ViewKickMaxSec);
	
	self:SetNWBool("NeedsPump",true);
	return true;
end

--If the shotgun needs to be pumped we'll do that
function ITEM:OnThink()
	self["base_firearm"].OnThink(self);
	if self:GetNWBool("NeedsPump") then self:Pump(); end
end

--Start reloading shells
function ITEM:StartReload()
	if !self["base_firearm"].StartReload(self) then return false end
	if self:IsHeld() then
		self:GetWeapon():SendWeaponAnim(ACT_SHOTGUN_RELOAD_START);
	end
	
	return true;
end

--Stop reloading shells
function ITEM:FinishReload()
	if !self["base_firearm"].FinishReload(self) then return false end
	if self:IsHeld() then
		self:GetWeapon():SendWeaponAnim(ACT_SHOTGUN_RELOAD_FINISH);
	end
	
	return true;
end

--Pump the shotgun; lets it fire again. We can't pump if we're cooling down from an attack.
function ITEM:Pump()
	--Can't pump while we're cooling down
	if !self:CanPrimaryAttack() || !self:CanSecondaryAttack() then return false end
	
	--Can't pump unless the player has us out
	if self:IsHeld() && self:GetWOwner():GetActiveWeapon()!=self:GetWeapon() then return false end
	
	self:EmitSound(self.PumpSound);
	self:SetNWBool("NeedsPump",false);
	self:SetNextBoth(CurTime()+self.PumpDelay);
	
	if !self:IsHeld() then return true end
	self:GetWeapon():SendWeaponAnim(ACT_SHOTGUN_PUMP);				
	
	return true;
end

IF.Items:CreateNWVar(ITEM,"NeedsPump","bool",false,true,true);