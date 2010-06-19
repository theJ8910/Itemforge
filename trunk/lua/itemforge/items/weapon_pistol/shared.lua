--[[
weapon_pistol
SHARED

The Itemforge version of the Half-Life 2 Pistol (the metrocop pistol, not the .357).
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="H&K USP Match";
ITEM.Description="This is a Heckler & Koch USP (or Universal Self-Loading Pistol), Match variant.\nThis weapon is designed for use with 9mm rounds.";
ITEM.Base="base_firearm";
ITEM.Weight=771;				--Based on http://en.wikipedia.org/wiki/Heckler_&_Koch_USP Tactical 9mm (USP Match weight unavailable)
ITEM.Size=7;

if SERVER then
	ITEM.GibEffect = "metal";
end

ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

--Overridden Base Weapon stuff
ITEM.PrimaryDelay=.1;		--When rapidly clicking, the modcode says the pistol can fire at a rate of 10 shots per second (meaning 1 bullet every .1 sec)
ITEM.PrimaryDelayAuto=.5;	--However, when simply holding attack, the pistol fires at a rate of 2 shots per sec (meaning 1 bullet every .5 sec);

--Overridden Base Ranged Weapon stuff
ITEM.Clips={};
ITEM.Clips[1]={Type="ammo_pistol",Size=18};
ITEM.PrimaryClip=1;
ITEM.ReloadDelay=1.4333332777023;
ITEM.PrimaryFireSounds={	Sound("weapons/pistol/pistol_fire2.wav")};

--Overridden Base Firearm stuff
ITEM.BulletDamage=12;
ITEM.BulletSpread=Vector(0.00873,0.00873,0.00873);		--Taken directly from modcode; this is 1 degree deviation
ITEM.ViewKickMin=Angle(0.25,-.6,0);						--Taken directly from modcode. The view kicks down and to the left/right when firing.
ITEM.ViewKickMax=Angle(0.5,.6,0);

--Pistol Weapon
--[[
The HL2 pistol does something irritating;
The bullet spread varies from 1 to 6 degrees depending on an "accuracy penalty".
This accuracy penalty increases when bullets are fired and degrades over time.
]]--
ITEM.PenaltyPerShot=0.2;		--Add 0.2 seconds of accuracy penalty per shot
ITEM.PenaltyMax=1.5;			--The max accuracy penality is 1.5 seconds


--The max spread is how inaccurate the pistol will be when the accuracy penalty is maxed out (turns out it's worse than the SMG; that being said, fire carefully to avoid maxing out the penalty)
ITEM.BulletSpreadMax=Vector(0.05234,0.05234,0.05234);			--Taken directly from modcode; this is 6 degrees deviation

function ITEM:OnSWEPPrimaryAttack()
	--This does all the base ranged stuff - determine if we can fire, do cooldown, consume ammo, play sounds, etc
	if !self["base_ranged"].OnSWEPPrimaryAttack(self) then return false end
	
	local pAmmo=self:GetAmmo(self.PrimaryClip);
	if !pAmmo then return false end
	
	self:ShootBullets(pAmmo.BulletsPerShot,pAmmo.BulletDamage,1,self:GetBulletSpread(pAmmo.BulletSpread,pAmmo.BulletSpreadMax));
	self:MuzzleFlash();
	
	local owner=self:GetWOwner();
	if owner then owner:ViewPunchReset() end
	
	self:AddViewKick(self.ViewKickMin,self.ViewKickMax);
	self:AddPenalty(self.PenaltyPerShot);
end

function ITEM:OnSWEPSecondaryAttack()
	--Secondary attack does NOTHING
end

--The pistol loses it's accuracy penalty over time
function ITEM:OnThink()
	self["base_firearm"].OnThink(self);
	if self:CanPrimaryAttack() then self:AddPenalty(-FrameTime()) end
end

--[[
Add time to the accuracy penalty
If amt is negative it subtracts accuracy penalty time instead
]]--
function ITEM:AddPenalty(amt)
	self:SetNWFloat("Penalty",math.Clamp(self:GetNWFloat("Penalty")+amt,0,self.PenaltyMax));
end

--Bullet spread depends on penalty amount
function ITEM:GetBulletSpread(min,max)
	return min+((max-min)*(self:GetNWFloat("Penalty")/self.PenaltyMax));
end

--[[
The HL2 pistol uses a different viewmodel activity for each attack,
depending on how many bullets have been fired in recent time.
I cheated here; the number of bullets fired and the last attack time are set here instead of the PrimaryAttack function above;
In order for this function to work right, the last attack time and number of bullets fired must be set after firing a bullet but before playing the animation;
To do that I would have had to have rewritten the primary attack function; No use rewriting the whole function for something like this right?
]]--
function ITEM:GetPrimaryActivity()
	local BulletsFired=self:GetNWInt("BulletsFired");
	local LastAttack=self:GetNWFloat("LastAttack");
	if CurTime()-LastAttack>0.5 then	self:SetNWInt("BulletsFired",0);
	else								self:SetNWInt("BulletsFired",BulletsFired+1);
	end
	self:SetNWFloat("LastAttack",CurTime());
	
	if		BulletsFired==0 then return ACT_VM_PRIMARYATTACK;
	elseif	BulletsFired==1 then return ACT_VM_RECOIL1;
	elseif	BulletsFired==2 then return ACT_VM_RECOIL2; end
	return ACT_VM_RECOIL3;
end

IF.Items:CreateNWVar(ITEM,"Penalty","float",0.0,true,true);
IF.Items:CreateNWVar(ITEM,"LastAttack","float",0.0,true,true);
IF.Items:CreateNWVar(ITEM,"BulletsFired","int",0,true,true);
