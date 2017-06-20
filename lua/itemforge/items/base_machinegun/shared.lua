--[[
base_machinegun
SHARED

base_machinegun is a base. That means that other items borrow code from this so they can be created easier.
Any item that inherits from this has everything this item has, and can override anything this item has.

The base_machinegun is designed to imitate the modcode's weapon_hl2mpbase_machinegun, which the HL2 SMG and AR2 are based off of.
Machine guns are basically firearms with unusual view kick behavior.
	To produce the view kick, I need to keep track of how long the weapon has been fired continuously. This involves constantly updating a networked variable.
	Because of this, machine guns tend to be slightly less efficient network-wise than other firearms such as pistols, so it seems appropriate to migrate this
	code to it's own class so only weapons that NEED to keep track of the weapon fire time actually do.
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name					= "Base Machinegun";
ITEM.Description			= "This item is the base machine gun.\nMachine guns inherit from this.\n\nThis is not supposed to be spawned.";
ITEM.Base					= "base_firearm";

ITEM.WorldModel				= "models/weapons/w_smg1.mdl";
ITEM.ViewModel				= "models/weapons/v_smg1.mdl";

--Base Machine Gun
ITEM.ViewPunchClimax		= 2;							--View punch becomes and stays this intense after this many seconds of continuous firing
ITEM.ViewPunchClip			= Angle( 24.0, 3.0, 1.0 );		--View punch pitch/yaw/roll angles will be forcibly clamped at +- the pitch/yaw/roll defined by ViewPunchClip
--[[
We keep track of how long the weapon has been firing. If the weapon fires longer than this, we stop keeping track.
This is here for network-optimization purposes and doesn't stop the weapon from firing.
However, if your code does something with fire duration (like making bullets spread out more as firing continues) make sure to set
this high enough to account for whatever you're doing (ex: the SMG's view punch reaches it's max intensity at 2 seconds)
]]--
ITEM.MaxFireDuration		= 2;

local vZero = Vector( 0, 0, 0 );

--[[
* SHARED
* Event

More or less the same primary attack as a firearm, but with different view kick.
]]--
function ITEM:OnPrimaryAttack()
	self:DoBullets();
	self:MuzzleFlash();
	self:DoMachineGunKick( self:GetFireDuration() );
	
	return true;
end

--[[
* SHARED

Mimics the machine gun kick the HL2 SMG from the modcode uses.
The viewkick is more intense the longer the machine gun remains firing.
It reaches it's max intensity after 2 seconds of continuous firing.
]]--
function ITEM:DoMachineGunKick( fDuration )
	local pl = self:GetWOwner();
	if !pl then return end

	if fDuration > self.ViewPunchClimax then fDuration = self.ViewPunchClimax end
	local fKickPerc = fDuration / self.ViewPunchClimax;

	--The way they generate this angle is so weird. I think the second parameter being set might be accidental, but I'm not changing it.
	angScratch = Angle( - ( 0.2 + fKickPerc		),
						- ( 0.2 + fKickPerc		) / 3,
						  ( 0.1 + fKickPerc / 8 )
					  );
	
	--Wobble left and right ( 2 / 3 chance of wobbling to left )
	if math.random( -1, 1 ) >= 0 then
		angScratch.y = -angScratch.yaw;
	end
	--Wobble "up and down" ( another case where the comments may be out-of-date; roll spins the view. 2 / 3 chance of wobbling clockwise )
	if math.random( -1, 1 ) >= 0 then
		angScratch.r = -angScratch.roll;
	end

	--Do this to get a hard discontinuity, clear out anything under 10 degrees punch (the gmwiki doesn't mention :ViewPunchReset taking a number, although the function it calls DOES accept a number; I hope that is actually implemented)
	pl:ViewPunchReset( 10 );

	angScratch = self:ClipPunchAngleOffset( angScratch, pl:GetPunchAngle(), self.ViewPunchClip );

	--Add it to the view punch
	--NOTE: 0.5 is just tuned to match the old effect before the punch became simulated (these are modcode comments, not mine)
	pl:ViewPunch( 0.5 * angScratch );
end

--[[
* SHARED
* Event

Converted from the modcode's UTIL_ClipPunchAngleOffset.
Clips angAddedPunch by finding the punch angles that will result from the viewpunch,
then clamping that angle's components between angClip and -angClip's components,
and returning a (possibly) modified angAddedPunch that when applied to the angCurrentPunchAngle results in the clamped punch angle.
]]--
function ITEM:ClipPunchAngleOffset( angAddedPunch, angCurrentPunchAngle, angClip )
	local angPunchResult = angCurrentPunchAngle + angAddedPunch;
	
	return Angle( math.Clamp( angPunchResult.p, -angClip.p, angClip.p ) - angCurrentPunchAngle.p,
				  math.Clamp( angPunchResult.y, -angClip.y, angClip.y ) - angCurrentPunchAngle.y,
				  math.Clamp( angPunchResult.r, -angClip.r, angClip.r ) - angCurrentPunchAngle.r
				);
	
end

--[[
* SHARED
* Event
]]--
function ITEM:OnSWEPThink()
	self:BaseEvent( "OnSWEPThink" );

	if self:Event( "IsPrimaryAttacking" ) then		self:AddFireDuration( FrameTime() );
	else											self:SetFireDuration( 0 );
	end
end

--[[
* SHARED

Sets the fire duration to the given number of seconds
]]--
function ITEM:SetFireDuration( fFireDuration )
	--Don't send unnecessary networking updates.
	if fFireDuration > self.MaxFireDuration then fFireDuration = self.MaxFireDuration end
	
	self:SetNWFloat( "FireDuration", fFireDuration );
end

--[[
* SHARED

Adds time onto the fire duration.
fTime should be the amount of time (in seconds) you want to add onto the fire duration.
	Can be negative to subtract time.
]]--
function ITEM:AddFireDuration( fTime )
	self:SetFireDuration( self:GetFireDuration() + fTime );
end

--[[
* SHARED

Returns the fire duration.
]]--
function ITEM:GetFireDuration()
	return self:GetNWFloat( "FireDuration" );
end

IF.Items:CreateNWVar( ITEM, "FireDuration",		"float",	0.0,	nil,	true, true );