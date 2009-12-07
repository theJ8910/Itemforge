--[[
weapon_shotgun
SHARED

The Itemforge version of the Half-Life 2 Shotgun.
This shotgun is heavily based off of the HL2 Shotgun's modcode.
Delays are taken from the SequenceDuration() of the viewmodel animations.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Franchi SPAS-12";
ITEM.Description="This is a Franchi SPAS-12, a double-barrelled combat shotgun.\nThis weapon can fire up to two shells at once.\nThis shotgun can be loaded with any 12 gauge shotgun shells.";
ITEM.Base="base_firearm";
ITEM.Weight=4400;	--Based on http://half-life.wikia.com/wiki/SPAS-12_(HL2) and http://en.wikipedia.org/wiki/Franchi_SPAS-12
ITEM.Size=19;
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

ITEM.SecondaryClip=1;
ITEM.SecondaryTakes=2;
ITEM.SecondaryFiresUnderwater=false;
ITEM.SecondaryFireSounds={Sound("weapons/shotgun/shotgun_dbl_fire7.wav")};

ITEM.ReloadsSingly=true;
ITEM.ReloadDelay=0.5;									--Every time a shell is loaded it's a half-second cooldown
ITEM.ReloadStartDelay=0.5;								--Before we start loading shells, we have to cooldown for this long
ITEM.ReloadFinishDelay=0.43333333730698;				--After all the shells have been loaded we can't attack for this long
ITEM.ReloadSounds={										--Finally! A chance to take advantage of multiple reload sounds!
	Sound("weapons/shotgun/shotgun_reload1.wav"),
	Sound("weapons/shotgun/shotgun_reload2.wav"),
	Sound("weapons/shotgun/shotgun_reload3.wav")
}

ITEM.DryFireDelay=0.33333334326744;
ITEM.DryFireSounds={Sound("weapons/shotgun/shotgun_empty.wav")};

--Overridden Base Firearm stuff
ITEM.BulletDamage=4;									--Each pellet does this much damage; not much on it's own, but luckily we have several pellets per shot
ITEM.BulletsPerShot=7;									--The shotgun's primary fires 7 distinct pellets per shot
ITEM.BulletSpread=Vector(0.08716,0.08716,0.08716);		--Unfortunately they have 10 degrees deviation
ITEM.ViewKickMin=Angle(-2,-2,0);						--The shotgun's primary kicks this much
ITEM.ViewKickMax=Angle(-1,2,0);

--Shotgun Weapon
ITEM.BulletsPerShotSec=12;								--WHAT? The shotgun's secondary takes two shells and only shoots 12 pellets?!
ITEM.ViewKickMinSec=Angle(-5,0,0);						--The secondary kicks more than primary
ITEM.ViewKickMaxSec=Angle(5,0,0);

ITEM.PumpDelay=0.53333336114883;
ITEM.PumpSound=Sound("weapons/shotgun/shotgun_cock.wav");


--[[
The shotgun's primary attack does everything the base_firearm does, but it's behavior is modified a little bit.
Since it's a shotgun it needs to be pumped before it can be fired again.
]]--
function ITEM:OnPrimaryAttack()
	local pAmmo=self:GetAmmo(self.PrimaryClip);
	
	--If we're reloading, we wait until we have enough ammo, then we stop the reload and attack
	if self:GetNWBool("InReload") then
		if !pAmmo || pAmmo:GetAmount()<self.PrimaryTakes then return false end
		self:SetNWBool("InReload",false);
		self:SetNextBoth(0);
	end
	
	--Can't attack if we need to pump the shotgun
	if self:GetNWBool("NeedsPump") || !self["base_firearm"].OnPrimaryAttack(self) then return false end
	
	self:SetNWBool("NeedsPump",true);
	return true;
end

--[[
The shotgun's secondary attack is pretty much the same thing as it's primary attack except it shoots more bullets and does more kick or whatever
]]--
function ITEM:OnSecondaryAttack()
	local sAmmo=self:GetAmmo(self.SecondaryClip);
	local notEnoughAmmo=(!sAmmo || sAmmo:GetAmount()<self.SecondaryTakes);
	
	--If we're reloading, we wait until we have enough ammo, then we stop the reload and attack
	if self:GetNWBool("InReload") then
		if notEnoughAmmo then return false end
		
		self:SetNWBool("InReload",false);
		self:SetNextBoth(0);
	
	--We're not reloading, that means we can attack immediately.
	--If it turns out we don't have enough ammo for the secondary attack, we try to do a primary attack instead.
	elseif notEnoughAmmo then
		return self:OnPrimaryAttack();
	end
	
	--Can't attack if we need to pump the shotgun
	if self:GetNWBool("NeedsPump") || !self["base_firearm"].OnSecondaryAttack(self) then return false end
	
	self:ShootBullets(self.BulletsPerShotSec,self.BulletDamage,1,self:GetBulletSpread());
	self:MuzzleFlash();
	self:AddViewKick(self.ViewKickMinSec,self.ViewKickMaxSec);
	
	self:SetNWBool("NeedsPump",true);
	return true;
end

--If the shotgun needs to be pumped we'll do that
function ITEM:OnThink()
	self["base_firearm"].OnThink(self);
	if self:GetNWBool("NeedsPump") then
		local pOwner=self:GetWOwner();
		
		--The shotgun has something called "delayed reload"; if the player presses reload before the shotgun is pumped, then the shotgun reloads after pumping.
		if pOwner && pOwner:KeyDownLast(IN_RELOAD) then
			self:SetNWBool("DelayedReload",true);
		end
		
		self:Pump();
	end
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
	
	if self:GetNWBool("DelayedReload") then
		self:SetNWBool("DelayedReload",false);
		self:StartReload();
	end
	
	self:EmitSound(self.PumpSound,true);
	self:SetNWBool("NeedsPump",false);
	self:SetNextBoth(CurTime()+self.PumpDelay);
	
	if !self:IsHeld() then return true end
	self:GetWeapon():SendWeaponAnim(ACT_SHOTGUN_PUMP);				
	
	return true;
end

IF.Items:CreateNWVar(ITEM,"NeedsPump","bool",false,true,true);
IF.Items:CreateNWVar(ITEM,"DelayedReload","bool",false,true,true);