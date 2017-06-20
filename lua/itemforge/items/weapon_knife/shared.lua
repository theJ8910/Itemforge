--[[
weapon_knife
SHARED

Kind of sharp.
When the combination stuff comes in the knife could be a useful tool for things like
cutting rope, slicing fruit, etc.
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name					= "Combat Knife";
ITEM.Description			= "A combat knife. It's blade may also prove useful for other purposes.";
ITEM.Base					= "base_melee";
ITEM.Size					= 10;
ITEM.Weight					= 238;		--Weight from http://www.crkt.com/Ultima-5in-Black-Blade-Veff-Combo-Edge

ITEM.SWEPHoldType			= "knife";
ITEM.WorldModel				= "models/weapons/w_knife_t.mdl";
ITEM.ViewModel				= "models/weapons/v_knife_t.mdl";

if SERVER then




ITEM.GibEffect				= "metal";




else




ITEM.Icon					= Material( "itemforge/items/weapon_knife" );




end

ITEM.Spawnable				= true;
ITEM.AdminSpawnable			= true;

--Overridden Base Weapon stuff
ITEM.HasPrimary				= true;
ITEM.PrimaryDelay			= 0.4;
ITEM.ViewKickMin			= Angle( 0.5, 1.0, 0 );
ITEM.ViewKickMax			= Angle( -0.5, -1.0, 0 );

--Overridden Base Melee stuff
ITEM.HitRange				= 75;
ITEM.HitForce				= 1;
ITEM.HitDamage				= 10;

ITEM.HitSounds				= Sound( "Weapon_Crowbar.Melee_Hit" );
ITEM.MissSounds				= Sound( "Weapon_Crowbar.Single" );

--Combat Knife
ITEM.DamageScaleSpeedFactor	= 0.05;										--5 / 100. Speed * this = damage multiplier
ITEM.RopeCutSound			= Sound( "TripwireGrenade.ShootRope" );		--This sound plays after a rope is cut
ITEM.RopeCutSoundLength		= 0.4;										--The sound I use is too long, so I only play it for this long.

--[[
* SHARED
* Event

If the player is moving fast when he hits the target,
the damage is scaled with respect to speed
]]--
function ITEM:GetHitDamage( traceRes )
	local pl = self:GetWOwner();
	return self.HitDamage + ( ( pl && self.DamageScaleSpeedFactor * pl:GetVelocity():Length() ) || 0 );
end

--[[
* SHARED
* Event

Basically same rules as base_melee but we also ignore rope ends
]]--
function ITEM:IsValidHit( traceRes, iHitType, vAimDir, fHitRange, fTolerance )
	local eHit = traceRes.Entity;
	if IsValid( eHit ) && eHit:GetClass() == IF.Util:GetRopeEndClass() then return false end
	return self:BaseEvent( "IsValidHit", nil, traceRes, iHitType, vAimDir, fHitRange, fTolerance );
end


if SERVER then




--[[
* SERVER

Tests cut ropes to see if the cut location is allowed, given the melee weapon's range of attack and the player's facing direction.

We know the cut position will be in a plane (the cut plane).
By testing if it's also in a spherical cone, whose center/apex and axis lie on that plane,
we are basically testing if the point lies in a sector of a circle on that plane.
]]--
local function IsValidCut( eLCRope, vCutPos, vShootPos, vAimDir, fHitRange )
	return IF.Util:IsPointInSphericalCone( vCutPos, vShootPos, vAimDir, fHitRange, 0.70721 );
end

--[[
* SERVER
* Event

Does everything that normally happens on swing, and also cuts ropes in the way
]]--
function ITEM:OnSwing( traceRes )
	self:BaseEvent( "OnSwing", nil, traceRes );
	--0.70721
	local pl = self:GetWOwner();
	if !pl then return end
	local angEye = pl:EyeAngles();

	if IF.Util:CutRopes( traceRes.StartPos, angEye:Up(), nil, IsPointInWedge, pl:GetShootPos(), angEye:Forward(), self:Event( "GetHitRange", 75 ) ) then
		self:LoopingSound( self.RopeCutSound, "WeaponKnife_RopeCutSound" );
		self:SimpleTimer( self.RopeCutSoundLength, self.StopLoopingSound, "WeaponKnife_RopeCutSound" );
	end
end




else




--[[
* CLIENT
* Event

The knife's weapon menu icon has some unconvential motion.
I designed it to look like it was being juggled, to fit with the idea that this is an agility / dexterity weapon.
]]--
function ITEM:OnSWEPDrawMenu( fX, fY, fW, fH, fA )
	
	--0.5235987756 = PI / 6
	--2.094395102 = 2PI / 3
	local t = 1 + math.sin( 3 * RealTime() );
	local a = 0.5235987756 - 2.094395102 * t;
	self:DrawIconRotated( fX + 0.5 * fW + 35 * math.cos( a ),
						  fY + 0.5 * fH + 40 * math.sin( a ),
						  64, 64,
						  900 * t,
						  fA );
end




end