--[[
base_melee
SHARED

base_melee is a base. That means that other items borrow code from this so they can be created easier.
Any item that inherits from this has everything this item has, and can override anything this item has.

The base_melee has two purposes:
	You can tell if an item is a melee weapon (like a knife or crowbar) by checking to see if it inherits from base_melee.
	It's designed to help you create melee weapons easier (like a knife, crowbar, pipe, etc). You just have to change/override some variables or replace some stuff with your own code.
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name				= "Base Melee Weapon";
ITEM.Description		= "This item is the base melee weapon.\nItems used as melee weapons, such as a crowbar or a pipe, can inherit from this\n to make their creation easier.\n\nThis is not supposed to be spawned.";
ITEM.Base				= "base_weapon";
ITEM.WorldModel			= "models/weapons/w_crowbar.mdl";
ITEM.ViewModel			= "models/weapons/v_crowbar.mdl";

--We don't want players spawning it.
ITEM.Spawnable			= false;
ITEM.AdminSpawnable		= false;

ITEM.SWEPHoldType		= "melee";

--Base Melee Weapon
ITEM.Tolerance			= 16;					--How far away from the line-of-attack can things be hit? If you think of melee attacks as "stabs", this would be the thickness of the sword / spear you're stabbing with.
ITEM.MaskType			= MASK_SHOT_HULL;		--The line/box traces the melee weapons use to detect targets will use this type of mask. MASK_* enums and OR'd combinations of MASK_* enums are valid.
ITEM.DamageType			= DMG_CLUB;				--This is the type of damage that a melee weapon delivers. DMG_* enums and OR'd combinations of DMG_* enums are valid.

ITEM.HitDamage			= 25;					--We do this much damage per hit
ITEM.HitRange			= 75;					--We must be this close to attack with this weapon
ITEM.HitForce			= 1;					--When a physics object is hit, it's hit with "x" times more power than it would if a bullet hit it.

ITEM.HitActivity		= ACT_VM_HITCENTER;		--What viewmodel animation (i.e. first person) is played if the weapon hits?
ITEM.HitPlayerAnim		= PLAYER_ATTACK1;		--What player animation (i.e. third person) is played if the weapon hits?
ITEM.HitSounds			= nil;					--Plays this sound (or, if this is a table, a random sound from this table) when the weapon hits. Plays nothing if this is nil.

ITEM.MissActivity		= ACT_VM_MISSCENTER;	--What viewmodel animation (i.e. first person) is played if the weapon misses? 
ITEM.MissPlayerAnim		= PLAYER_ATTACK1;		--What player animation (i.e. third person) is played if the weapon misses?
ITEM.MissSounds			= nil;					--Plays this sound (or, if this is a table, a random sound from this table) when the weapon hits. Plays nothing if this is nil.

--Don't modify/override these. They're either set automatically or don't need to be changed.
ITEM.LandedHit			= false;				--This is set to true if the last melee attack landed a hit, and false if the last melee attack was a miss.
ITEM.LastTraceResults	= nil;					--This is set to the results of the last melee trace.

local vZero		= Vector( 0, 0, 0 );
local vForward	= Vector( 1, 0, 0 );
local vLeft		= Vector( 0, 1, 0 );
local vUp		= Vector( 0, 0, 1 );

--[[
* SHARED
* Event

TODO: Garry needs to add the TraceAttackToTriggers binding so I can make melee weapon swings break glass
]]--
function ITEM:OnPrimaryAttack()
	local plOwner = self:GetWOwner();

	--We have to figure out if the player hit something before dealing damage.
	local traceRes = self:DoTrace();
	
	--This is used by events and need to be available to them
	self.LandedHit			= traceRes.Hit;
	self.LastTraceResults	= traceRes;

	self:Event( "OnSwing", nil, traceRes );
	if self.LandedHit then	self:Event( "OnHit",  nil, traceRes );
	else					self:Event( "OnMiss", nil, traceRes );
	end
	
	self:AddViewKick( self.ViewKickMin, self.ViewKickMax );
end

--[[
* SERVER
* Event

This event calls every time the weapon is swung, regardless of whether it hits or misses.

traceRes is a table of trace results from the melee trace.
]]--
function ITEM:OnSwing( traceRes )
	local dmgInfo = self:MakeDamageInfo( self:GetWOwner(),
										 traceRes.StartPos,
										 traceRes.vDirectTraceHit,
										 self:Event( "GetHitForce",		7500		),
										 self:Event( "GetHitDamage",	0			),
										 self:Event( "GetDamageType",	DMG_CLUB	)
									   );

	self:TraceAttackToTriggers( traceRes.StartPos, traceRes.vDirectTraceHit, dmgInfo );
end

--[[
* SHARED
* Event

If the melee weapon hits something, this is called.
The default OnHit action is to apply damage to the target.

You can override this event to give a special function to your weapon, like healing other
items or players, for example.

traceRes is a table of trace results from the melee trace.
]]--
function ITEM:OnHit( traceRes )
	--We'll create a DamageInfo for trace attacks here, or create a default DamageInfo without events if GetDamageInfo failed.
	local dmgInfo, bSuccess = self:Event( "GetDamageInfo", nil, self:GetWOwner(), traceRes );
	if !bSuccess then dmgInfo = self:MakeDamageInfo( self:GetWOwner(), traceRes.StartPos, traceRes.HitPos, 7500, 0, DMG_CLUB );	end

	self:TraceAttackToTriggers( traceRes.StartPos, traceRes.HitPos, dmgInfo );
	self:DispatchTraceAttack( traceRes.StartPos, traceRes.HitPos, traceRes.Entity, dmgInfo );
	
	self:Event( "HitEffect", nil, traceRes );
end

--[[
* SHARED
* Event

If the melee weapon fails to strike anything, this is called.

traceRes is a table of trace results from the melee trace.
]]--
function ITEM:OnMiss( traceRes )
	self:WaterSplash( traceRes.StartPos, traceRes.vDirectTraceLimit, self:GetWOwner() );
end

--[[
* SHARED
* Event

This event should determine if hitting an entity is valid, returning true if it is,
or false if it isn't.

If a hit is invalid, the weapon is forced to miss.

By default, it checks for the following things:
	If the player hit something indirectly, was the player looking in this direction? (must at least occur within a 90 degree cone from the direction the player is looking)

traceRes is a table of trace results from the melee trace.
iHitType describes how the weapon hit. See the MeleeTrace function for more information on this.
vAimDir is a normalized vector pointing the direction the player is aiming (the direction he's facing).
fHitRange is the furthest distance from the trace's start position that a hit can occur.
fTolerance is the "furthest" distance away from the player's aim direction that something can be hit.
]]--
function ITEM:IsValidHit( traceRes, iHitType, vAimDir, fHitRange, fTolerance )
	
	--[[
	As unbelievable as this may be, I am actually reproducing a BUG IN THE SOURCE ENGINE here on purpose.
	
	If you hit an entity on an indirect hit, the source engine makes sure you're "sort of" facing the entity
	you're hitting by getting the line between the center of the object you hit and the player's shoot position.
	It then finds the angle between the player's aim direction and that line (using dot product). If this is above
	45 degrees, the hit is considered invalid and the weapon misses on purpose.

	However, the source engine incorrectly considers the world to be a normal entity, and since the world's "position"
	is <0,0,0>, the weapon only hits if you're "sort of" facing the center of the world!

	Of course, the whole reason I bothered reproducing this bug is because leaving it out would cause the
	weapons to behave differently than the HL2 weapons.

	NOTE: Even though worldspawn is an entity, IsValid() returns false for it.
	]]--
	local eHit = traceRes.Entity;
	if iHitType == 2 && ( traceRes.HitWorld || IsValid( eHit ) ) then
		return vAimDir:Dot( ( eHit:GetPos() - traceRes.StartPos ):Normalize() ) > 0.70721		--0.70721 = cos( 45 )
	end

	return true;
	
	--local vCenter = eHit:LocalToWorld( eHit:OBBCenter() );
	--return traceRes.StartPos:Distance( vCenter ) <= fHitRange + eHit:BoundingRadius() && vAimDir:Dot( ( vCenter - traceRes.StartPos ):Normalize() ) > 0.70721;
end

--[[
* SHARED
* Event

Called whenever something has been hit, and allows the weapon to create a clientside
hit effect.

traceRes is a table of trace results from the melee trace.

The default effect creates water splashes if the weapon struck something underwater from above.
Otherwise, clientside bullets are used to causes sparks / impact sounds.
]]--
function ITEM:HitEffect( traceRes )
	local plOwner = self:GetWOwner();
	if !plOwner then return end

	if self:WaterSplash( traceRes.StartPos, traceRes.HitPos, plOwner ) then return false end

	--[[
	We have to use clientside bullets for impact effects since garry doesn't
	have UTIL_ImpactEffect either.
	
	The traceRes.bFoundIntersect check here exists because, in the case it's not a direct hit,
	a bullet will go flying off into the sunset (or at least into an obstacle outside the
	melee weapon's hit range).

	Unfortunately, even though ChooseIntersectionPoint is a near 1:1 reproduction, it's not always capable of getting 
	]]--
	if traceRes.bFoundIntersect == false then return end

	local hitbullet			= {};
	hitbullet.Num			= 1;
	hitbullet.Src			= traceRes.StartPos;
	hitbullet.Dir			= traceRes.Normal;
	hitbullet.Spread		= vZero;
	hitbullet.Tracer		= 255;
	hitbullet.TracerName	= "";
	hitbullet.Force			= 0;
	hitbullet.Damage		= 0;

	plOwner:FireBullets( hitbullet );
	return true;
end

--[[
* SHARED
* Event

This event should create and return a DamageInfo for trace attacks to use.
]]--
function ITEM:GetDamageInfo( plOwner, traceRes )
	return self:MakeDamageInfo( plOwner,
								traceRes.StartPos,
								traceRes.HitPos,
								self:Event( "GetHitForce",		7500	 ),
								self:Event( "GetHitDamage",		0		 ),
								self:Event( "GetDamageType",	DMG_CLUB )
							  );
end

--[[
* SHARED
* Event

This event should return the tolerance distance (see ITEM.Tolerance above for a better description).
]]--
function ITEM:GetTolerance()
	return self.Tolerance;
end

--[[
* SHARED
* Event

This event should return the the type of mask used for the melee trace.
]]--
function ITEM:GetMaskType()
	return self.MaskType;
end

--[[
* SHARED
* Event

This event should return the type of damage done by the weapon (a DMG_* enum).
]]--
function ITEM:GetDamageType()
	return self.DamageType;
end

--[[
* SHARED
* Event

This event should return the amount of damage that is applied to the target.
You could potentially use it for damaging things differently depending on what was hit.
]]--
function ITEM:GetHitDamage()
	return self.HitDamage;
end

--[[
* SHARED
* Event

This event should return how far your melee attack with this weapon reaches. Maybe a breakable
sword would swing longer when whole, and shorter when broken?
]]--
function ITEM:GetHitRange()
	return self.HitRange;
end

--[[
* SHARED
* Event

This event should return the amount of force that is applied to the target.
The default is based off of Source's model, where enough force to propel a
75 kg man at 4 in / sec ( 75 * 4 = 300 ) per point of damage (and scaled by the hit force scalar)
is applied.
]]--
function ITEM:GetHitForce()
	return 300 * self:Event( "GetHitDamage", 0, traceRes ) * self.HitForce;
end

--[[
* SHARED
* Event

This event determines what sound should be played when the weapon lands a strike.
If it returns:
	nil or an empty table:				no sound is played
	a Sound( "filepath.wav" ):			that sound is played
	a table of Sound( "filepath.wav" ):	a random sound from that table is played
]]--
function ITEM:GetHitSound()
	return self.HitSounds;
end

--[[
* SHARED
* Event

Returns the viewmodel activity to play when the weapon lands a strike
]]--
function ITEM:GetHitActivity()
	return self.HitActivity;
end

--[[
* SHARED
* Event

Returns the animation played when the player lands a strike
]]--
function ITEM:GetHitPlayerAnim()
	return self.HitPlayerAnim;
end

--[[
* SHARED
* Event

This event determines what sound should be played when the weapon misses.
If it returns:
	nil or an empty table:				no sound is played
	a Sound( "filepath.wav" ):			that sound is played
	a table of Sound( "filepath.wav" ):	a random sound from that table is played
]]--
function ITEM:GetMissSound()
	return self.MissSounds;
end

--[[
* SHARED
* Event

Returns the viewmodel activity to play when the weapon misses.
]]--
function ITEM:GetMissActivity()
	return self.MissActivity;
end

--[[
* SHARED
* Event

Returns the animation played when the player misses
]]--
function ITEM:GetMissPlayerAnim()
	return self.MissPlayerAnim;
end

--[[
* SHARED
* Event

Returns the hit / miss sound depending on whether or not a hit was successful
]]--
function ITEM:GetPrimarySound()
	if self.LandedHit then	return self:Event( "GetHitSound",	self.HitSounds  );
	else					return self:Event( "GetMissSound",	self.MissSounds );
	end
end

--[[
* SHARED
* Event

Returns the hit / miss viewmodel activity depending on whether or not a hit was successful
]]--
function ITEM:GetPrimaryActivity()
	if self.LandedHit then	return self:Event( "GetHitActivity",  ACT_VM_HITCENTER  );
	else					return self:Event( "GetMissActivity", ACT_VM_MISSCENTER );
	end
end

--[[
* SHARED
* Event

Returns the hit / miss player animation depending on whether or not a hit was successful
]]--
function ITEM:GetPrimaryPlayerAnim()
	if self.LandedHit then	return self:Event( "GetHitPlayerAnim",  PLAYER_ATTACK1 );
	else					return self:Event( "GetMissPlayerAnim", PLAYER_ATTACK1 );
	end
end

--[[
* SHARED

Returns the results of the last melee trace.
]]--
function ITEM:GetLastTraceResults()
	return self.LastTraceResults;
end

if SERVER then




--[[
* SERVER
* Event

Since this is a melee weapon we return that he's allowed to use attack 1.
]]--
function ITEM:GetSWEPCapabilities()
	return CAP_WEAPON_MELEE_ATTACK1;
end




end

--[[
* SHARED

Shortcut for performing a standard melee trace.
]]--
function ITEM:DoTrace()
	local plOwner = self:GetWOwner();
	return self:MeleeTrace( plOwner:GetShootPos(),
							plOwner:GetAimVector(),
							self:Event( "GetHitRange", 75 ),
							self:Event( "GetTolerance", 16 ),
							plOwner,
							self:Event( "GetMaskType", MASK_SHOT )
						  );
end

--[[
* SHARED

Performs a melee-weapon trace.
This performs a normal traceline first. If the traceline does not hit anything,
performs a hull trace (box trace) in the same direction.

vFrom should be a vector in the world where the trace begins.
vDir should be a vector pointing in the direction of the trace.
fRange is the furthest distance away from vFrom that the trace can hit something.
fTolerance is half the width/length/height of the hull trace box (e.g. if fTolerance is 16, the box is 32 x 32 x 32, centered on the traceline).
	This can (roughly) be thought of as the furthest distance away from the traceline that something can be hit.
	The larger this is, the easier it is for targets nearby the traceline to be hit indirectly.
vFilter is an optional value. If vFilter is:
	an entity, then the trace ignores the entity.
	a table, then the trace ignores all the entities in the table.
	nil / not given, then the trace will hit any entities (as long as eMask allows it to).
eMask is an optional value. If eMask is:
	a MASK_* enum or OR'd combination of MASK_* enums, the trace will / will not collide with things (see MASK_* enums for more info)
	nil / not given, the trace behaves normally.

This function returns a melee trace results table.
	This is the same as a normal trace results table, but has additional members:

	traceRes is the results of the trace (whether that's a normal trace or a box trace).
	traceRes.iHitType is a number indicating how and if the melee trace hit something.
		iHitType is a number indicating how (or if) an object was hit. If iHitType is:
		0, then the weapon missed
		1, then the weapon scored a direct hit.					This means the player was looking directly at the target; the line trace hit it.
		2, then the weapon hit, but only glanced the target.	This means the player was looking at something near the target; the hull trace hit it instead.
	traceRes.vDirectTraceHit is the position the direct linetrace actually hit.
	traceRes.vDirectTraceLimit is the furthest possible location the direct linetrace can hit something. Will be the same as vDirectTraceHit if the direct trace didn't hit.
	traceRes.bFoundIntersect is a true/false. It will only be true if:
		The melee trace hit directly.
		The melee trace glanced, but managed to find an intersect location with ChooseIntersectionPoint.
]]--
function ITEM:MeleeTrace( vFrom, vDir, fRange, fTolerance, vFilter, eMask )
	local vMin = Vector( -fTolerance, -fTolerance, -fTolerance );
	local vMax = Vector(  fTolerance,  fTolerance,  fTolerance );

	--First we'll see if the player is looking directly at something, using a normal trace.
	local tr		= {};
	tr.start		= vFrom;
	tr.endpos		= vFrom + fRange * vDir;
	tr.filter		= vFilter;
	tr.mask			= eMask;
	local traceRes	= util.TraceLine( tr );
	
	local iHitType			= 0;
	local bFoundIntersect	= false;
	local vDirectTraceHit	= traceRes.HitPos;
	local vDirectTraceLimit	= tr.endpos;

	--[[
	If he wasn't looking directly at something we'll try a hull trace instead.
	This is a box trace basically. We'll run a 32x32 AABB along the same line and see if it
	hits anything. It's interesting to note that box-traces offer a wider hit range when
	swinging diagonally to the world axes. NOTE: the 1.732 * self.SwingHullDims is me pulling the
	box back by it's bounding radius, like the modcode does. If I didn't do this the hits would
	reach further than they're supposed to. 1.732 is the square root of 3 (the modcode incorrectly
	says that 1.732 is the cuberoot of 2).
	]]--
	if traceRes.Hit then
		iHitType = 1;
		bFoundIntersect = true;
	else
		tr.endpos	= vFrom + ( fRange - 1.732 * fTolerance ) * vDir;
		tr.mins		= vMin;
		tr.maxs		= vMax;

		traceRes	= util.TraceHull( tr );
		if traceRes.Hit then iHitType = 2 end
	end
	
	--Force a miss if we hit something invalid
	if !self:Event( "IsValidHit", false, traceRes, iHitType, vDir, fRange, fTolerance ) then
		traceRes.Hit = false;
		iHitType = 0;
		bFoundIntersect = false;

	--If we hit a valid entity on an indirect trace, we need to retrace with line traces and find the closest spot to us on that entity.
	elseif iHitType == 2 then
		traceRes, bFoundIntersect = self:ChooseIntersectionPoint( traceRes, vMin, vMax, vFilter, eMask );
	end

	traceRes.iHitType		   = iHitType;
	traceRes.bFoundIntersect   = bFoundIntersect;
	traceRes.vDirectTraceHit   = vDirectTraceHit;
	traceRes.vDirectTraceLimit = vDirectTraceLimit;

	return traceRes;
end

--[[
* SHARED
* Internal

Reproduced from the modcode.
There should be no need for a scripter to call this directly.

When a non-direct melee trace hit occurs (i.e. the hulltrace hits), sometimes the hit position can be
a significant distance away from the hit object. Because of this, melee weapons need to (qualitatively)
find the nearest valid hit location on the hit entity via regular line traces. A direct hit in the aim-direction is preferred,
but if it can't be hit the 8 corners of the hull trace box are tested with line traces, and the results of the shortest trace is returned.

traceRes is a trace results table from a hull trace.
vMin and vMax are the mins / maxs of the hull trace.
vFilter is an optional value. To work best, this should be the same value as vFilter from MeleeTrace. If vFilter is:
	an entity, then the trace ignores the entity.
	a table, then the trace ignores all the entities in the table.
	nil / not given, then the trace will hit any entities (as long as eMask allows it to).
eMask is an optional value. If eMask is:
	a MASK_* enum or OR'd combination of MASK_* enums, the trace will / will not collide with things (see MASK_* enums for more info)
	nil / not given, the trace behaves normally.

Returns two things: newTraceRes, bFoundIntersect
	If bFoundIntersect was:
		true, this means one of the line traces hit something,
		and newTraceRes will be the trace results from that line.
		
		false, this means none of the line traces hit anything,
		and newTraceRes will be the same as traceRes.
]]--
function ITEM:ChooseIntersectionPoint( traceRes, vMin, vMax, vFilter, eMask )
	
	--We make the trace segment 2x as long here so the line traces are more likely to hit something
	local vSrc		= traceRes.StartPos;
	local vHullEnd	= vSrc + 2 * ( traceRes.HitPos - vSrc );	

	--We do up to 9 traces in this function (1 is guaranteed), but all of them have this stuff in common so we reuse the table
	local tr		= {};
	tr.start		= vSrc;
	tr.filter		= vFilter;
	tr.mask			= eMask;
	
	
	tr.endpos		= vHullEnd;
	local tTempTrace = util.TraceLine( tr );

	--The center trace hit
	if tTempTrace.Hit then
		return tTempTrace, true;

	--The center trace missed, lets try to find the shortest trace to bounding box corners that a trace hits
	else
		--This allows me to do tMinMax[1] to get vMin, and tMinMax[2] to get vMax (used in for loops below)
		local tMinMax = { vMin, vMax };
		local vTempEnd = Vector( 0, 0, 0 );

		--The modcode initializes the shortest distance to a really large number ( 1e6f = 1.0f x 10^6 = 1000000 ).
		--This is okay since this function only gets called if a melee trace indirectly hits, and 1000000 is far, far outside of a normal melee weapon's hit range (Maybe Shinso would have trouble with this?)
		local fShortestDistance = 1000000;
		local tShortestTrace	= nil;
		
		for i = 1, 2 do
			for j = 1, 2 do
				for k = 1, 2 do
					
					--[[
					NOTE: I may have found another Source engine bug here.
					vHullEnd is never reset to it's original length, so the traces are actually not going through the corners of the AABB at the end of the hull trace.
					Instead, they're going through an AABB the same size, twice the distance away. This causes the traces to "cluster" closer to the middle of the original
					AABB.

					Again, I will not be changing this, because it would change the behavior of the weapons.
					]]--
					vTempEnd.x = vHullEnd.x + tMinMax[i].x;
					vTempEnd.y = vHullEnd.y + tMinMax[j].y;
					vTempEnd.z = vHullEnd.z + tMinMax[k].z;
					
					tr.endpos = vTempEnd;
					tTempTrace = util.TraceLine( tr );

					if tTempTrace.Hit then
						local fThisDist = vSrc:Distance( tTempTrace.HitPos );
						if fThisDist < fShortestDistance then
							fShortestDistance = fThisDist;
							tShortestTrace	  = tTempTrace;
						end
					end

				end
			end
		end

		if tShortestTrace != nil then return tShortestTrace, true end
	end

	--None of the traces hit
	return traceRes, false;
end

--[[
* SHARED

Creates a DamageInfo for a trace attack using the given params.

plOwner should be the player who attacked with the weapon.
vStart should be the location the attack began (usually the player's shoot position / eyes )
vHit should be the location the attack ended (usually whereever the trace ended)
fHitForce should be the amount of force (in pounds * feet / sec^2; this is usually whatever GetHitForce returns)
iHitDamage should be the amount of damage to apply to whatever was hit.
eDamageType should be a DMG_* enum or an OR'd combination of DMG_* enums.
]]--
function ITEM:MakeDamageInfo( plOwner, vStart, vHit, fHitForce, iHitDamage, eDamageType )
	local dmg = DamageInfo();

	dmg:SetDamagePosition(	vStart 											);
	dmg:SetInflictor(		plOwner											);
	dmg:SetAttacker(		plOwner											);
	dmg:SetDamageForce(		fHitForce * ( ( vHit - vStart ):Normalize() )	);
	dmg:SetDamage(			iHitDamage										);
	dmg:SetDamageType(		eDamageType										);

	return dmg;
end

--[[
* SHARED

This function applies damage to the hit entity.
Melee weapons apply damage with trace attack dispatches, as opposed to weapons like firearms that use bullets.

vStart should be the location the attack began (usually the player's shoot position / eyes )
vHit should be the location the attack ended (usually whereever the trace ended)
eHitEntity should be the entity that was hit by the weapon.
dmg should be the damageinfo to apply to the hit entity.
]]--
function ITEM:DispatchTraceAttack( vStart, vHit, eHitEntity, dmg )
	eHitEntity:DispatchTraceAttack( dmg, vStart, vHit );
end

--[[
* SHARED

"Attacks" any func_breakable_surf between vStart and vEnd with trace dispatches, using the given dmginfo.
In other words, it breaks away bits of shattered windows across the weapon's path of attack.

This function is designed to (somewhat) imitate the TraceAttackToTriggers function from the modcode.
It's not an acccessible function in Garry's Mod, and my ability to reproduce it is limited
because of non-existent bindings, and a lack of source code related to the original function.

vStart should be where the attack begins.
vEnd should be where the attack ends.
dmg should be a dmginfo to apply to any func_breakable_surf along the path of attack.
]]--
function ITEM:TraceAttackToTriggers( vStart, vEnd, dmgInfo )
	if vStart == vEnd then return end

	local vMin, vMax, vCenter, vNormal, vIntersect;
	
	for k, v in ipairs( ents.FindByClass( "func_breakable_surf" ) ) do
		vMin, vMax = v:WorldSpaceAABB();

		--Possible that this window was hit?
		if IF.Util:DoesLineSegIntersectAABB( vStart, vEnd, vMin, vMax ) then
			
			--Needs to have a cached glass plane
			vCenter, vNormal = IF.Util:GetCachedGlassPlane( v );
			if vCenter then

				--Find the intersect and at least make sure it's in the window's AABB
				vIntersect = IF.Util:LinePlaneIntersect( vCenter, vNormal, vStart, vEnd );
				if IF.Util:IsPointInAABB( vIntersect, vMin, vMax ) then
					v:DispatchTraceAttack( dmgInfo, vStart, vIntersect );
				end
			end
		end
	end
end

--[[
* SHARED

If there is water between vStart and vEnd, creates a splash effect on the surface of the water.
Returns true if a splash effect was created, and false otherwise.
]]--
function ITEM:WaterSplash( vStart, vEnd, plOwner )
	local eFluidContents = ( CONTENTS_WATER | CONTENTS_SLIME );
	local eEndContents = util.PointContents( vEnd );

	--If we start inside of water, or end outside of water, we don't bother doing a splash
	if ( util.PointContents( vStart ) & eFluidContents ) != 0 ||
	   ( eEndContents				  & eFluidContents ) == 0 then return false end

	--Find the surface of the water with a trace from start to end.
	local tr		= {};
	tr.start		= vStart;
	tr.endpos		= vEnd;
	tr.filter		= plOwner;
	tr.mask			= eFluidContents;			--Apparantly I can use eFluidContents as a mask even though they're CONTENTS_* enums and not MASK_* enums (I suspect MASK_* enums are just commonly OR'd CONTENTS_* enums)
	local traceRes	= util.TraceLine( tr );

	if traceRes.Hit then
		local effectdata = EffectData();
		effectdata:SetOrigin( traceRes.HitPos );
		effectdata:SetNormal( traceRes.HitNormal );
		effectdata:SetScale( 8 );
		if eEndContents & CONTENTS_SLIME != 0 then	effectdata:SetFlags( 1 );	end			--Setting flags to 1 makes it a slime splash in the case that we splashed slime

		util.Effect( "watersplash", effectdata );
	end

	return true;
end