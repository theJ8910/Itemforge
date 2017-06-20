--[[
weapon_pistol
SHARED

The Itemforge version of the Half-Life 2 Pistol (the metrocop pistol, not the .357).
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name				= "H&K USP Match";
ITEM.Description		= "This is a Heckler & Koch USP (or Universal Self-Loading Pistol), Match variant.\nThis weapon is designed for use with 9mm rounds.";
ITEM.Base				= "base_firearm";
ITEM.Weight				= 771;				--Based on http://en.wikipedia.org/wiki/Heckler_&_Koch_USP Tactical 9mm (USP Match weight unavailable)
ITEM.Size				= 7;

if SERVER then




ITEM.GibEffect			= "metal";




end

ITEM.Spawnable			= true;
ITEM.AdminSpawnable		= true;

--Overridden Base Weapon stuff
ITEM.HasPrimary			= true;
ITEM.PrimaryDelay		= 0.1;										--When rapidly clicking, the modcode says the pistol can fire at a rate of 10 shots per second (meaning 1 bullet every 0.1 sec)
ITEM.PrimaryDelayAuto	= 0.5;										--However, when simply holding attack, the pistol fires at a rate of 2 shots per sec (meaning 1 bullet every 0.5 sec);
ITEM.PrimarySounds		= Sound( "Weapon_Pistol.Single" );

ITEM.ViewKickMin		= Angle( 0.25, -0.6, 0 );					--Taken directly from modcode. The view kicks down and to the left/right when firing.
ITEM.ViewKickMax		= Angle( 0.5,   0.6, 0 );

--Overridden Base Ranged Weapon stuff
ITEM.Clips				= {};
ITEM.Clips[1]			= { Type = "ammo_pistol", Size = 18 };
ITEM.PrimaryClip		= 1;
ITEM.ReloadDelay		= 1.4333332777023;

--Overridden Base Firearm stuff
ITEM.BulletDamage		= 12;

--Pistol Weapon
--[[
The HL2 pistol does something irritating;
The bullet spread varies from 1 to 6 degrees depending on an "accuracy penalty".
This accuracy penalty increases when bullets are fired and degrades linearly over time.
]]--
ITEM.PenaltyPerShot		= 0.2;										--Add 0.2 seconds of accuracy penalty per shot
ITEM.PenaltyMax			= 1.5;										--The max accuracy penalty is 1.5 seconds

ITEM.ShotCounterMax	= 4;											--The shot counter stops counting after it exceeds this many shots (this is a network optimization).

--This table maps the # of shots fired to an appropriate primary attack activity
ITEM.ShotsFiredToActivity = {
	[0] = ACT_VM_PRIMARYATTACK,
	[1] = ACT_VM_RECOIL1,
	[2] = ACT_VM_RECOIL2,
	[3] = ACT_VM_RECOIL3,
}

--[[
* SHARED
* Event

Slightly different behavior than a normal firearm.
The pistol factors in and modifies an aim penalty, and resets view kick each time it fires.
The pistol also counts the # of consecutive shots that are within 0.5 seconds of each other (used by the function that determines the primary activity below).
]]--
function ITEM:OnPrimaryAttack()	
	local plOwner = self:GetWOwner();
	if plOwner then plOwner:ViewPunchReset() end

	self:BaseEvent( "OnPrimaryAttack" );

	self:AddPenalty( self.PenaltyPerShot );

	if CurTime() - self:GetNWFloat( "LastAttack" ) > 0.5		then	self:SetNWInt( "ShotsFired", 0 );
	else															self:SetNWInt( "ShotsFired", math.max( self:GetNWInt( "ShotsFired" ) + 1, self.ShotCounterMax ) );
	end
	self:SetNWFloat( "LastAttack", CurTime() );
end

--[[
* SHARED
* Event

The pistol loses it's accuracy penalty over time
]]--
function ITEM:OnThink()
	self:BaseEvent( "OnThink" );
	if self:CanPrimaryAttack() then self:AddPenalty( -FrameTime() ) end
end

--[[
* SHARED
* Event

The pistol loses it's accuracy penalty over time
]]--
function ITEM:OnSWEPThink()
	self:BaseEvent( "OnSWEPThink" );
	if self:CanPrimaryAttack() then self:AddPenalty( -FrameTime() ) end
end

--[[
* SHARED

Adds time to the accuracy penalty.

fAmt should be the amount of accuracy penalty time you want to add.
	If amt is negative, it subtracts accuracy penalty time instead.
]]--
function ITEM:AddPenalty( fAmt )
	self:SetNWFloat( "Penalty", math.Clamp( self:GetNWFloat( "Penalty" ) + fAmt, 0, self.PenaltyMax ) );
end

--[[
* SHARED
* Event

We use the ammo's bullets per shot
]]--
function ITEM:GetBulletsPerShot( itemAmmo )
	return itemAmmo.BulletsPerShot;
end

--[[
* SHARED
* Event

We use the ammo's bullet damage
]]--
function ITEM:GetBulletDamage( itemAmmo )
	return itemAmmo.BulletDamage;
end

--[[
* SHARED
* Event

We use the ammo's bullet impact force modifier
]]--
function ITEM:GetBulletForce( itemAmmo )
	return itemAmmo.BulletForceMul;
end

--[[
* SHARED
* Event

Bullet spread is related (linearly) to the current accuracy penalty.
]]--
function ITEM:GetBulletSpread( itemAmmo )
	local vMin = itemAmmo.BulletSpread;
	return vMin + ( ( itemAmmo.BulletSpreadMax - vMin ) * ( self:GetNWFloat( "Penalty" ) / self.PenaltyMax ) );
end

--[[
* SHARED
* Event

We use the ammo's bullet tracer
]]--
function ITEM:GetBulletTracer( itemAmmo )
	return itemAmmo.BulletTracer;
end

--[[
* SHARED
* Event

We use the ammo's bullet callback
]]--
function ITEM:GetBulletCallback( itemAmmo )
	return itemAmmo.BulletCallback;
end

--[[
* SHARED
* Event

The HL2 pistol uses a different viewmodel activity for each attack,
depending on how many bullets have been fired in recent time.

I cheated here; the number of bullets fired and the last attack time are set here instead of the PrimaryAttack function above;
In order for this function to work right, the last attack time and number of bullets fired must be set after firing a bullet but before playing the animation;
To do that I would have had to have rewritten the primary attack function; No use rewriting the whole function for something like this right?
]]--
function ITEM:GetPrimaryActivity()
	return self.ShotsFiredToActivity[self:GetNWInt( "ShotsFired" )];
end

IF.Items:CreateNWVar( ITEM, "Penalty",		"float",	0.0,	nil,	true, true );
IF.Items:CreateNWVar( ITEM, "LastAttack",	"float",	0.0,	nil,	true, true );
IF.Items:CreateNWVar( ITEM, "ShotsFired",	"int",		0,		nil,	true, true );