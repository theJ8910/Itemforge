--[[
base_thrown
SHARED

base_thrown is a base. That means that other items borrow code from this so they can be created easier.
Any item that inherits from this has everything this item has, and can override anything this item has.

The base_thrown has two purposes:
	You can tell if an item is a thrown weapon by checking to see if it inherits from base_thrown.
	It's designed to help you create weapons easier. You just have to change/override some variables or replace some stuff with your own code.
]]--
if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name				= "Base Thrown Weapon";
ITEM.Description		= "This item is the base thrown weapon.\nThrown weapons inherit from this.\n\nThis is not supposed to be spawned.";
ITEM.Base				= "base_weapon";
ITEM.WorldModel			= "models/props_junk/Rock001a.mdl";
ITEM.ViewModel			= "models/weapons/v_hands.mdl";
ITEM.MaxAmount			= 0;								--Thrown weapons are usually stacks of items

--We don't want players spawning it.
ITEM.Spawnable			= false;
ITEM.AdminSpawnable		= false;


ITEM.SWEPHoldType		= "grenade";




--Base Thrown
ITEM.ThrowActivity		= ACT_VM_THROW;				--What viewmodel animation (i.e. first person) is played if the item is thrown?
ITEM.ThrowPlayerAnim	= PLAYER_ATTACK1;			--What player animation (i.e. third person) is played if the item is thrown?
ITEM.ThrowSounds		= nil;						--Plays this sound (or, if this is a table, a random sound from this table) when the item is thrown. Plays nothing if this is nil.

ITEM.ThrowSpeedMin		= 1300;						--How fast is the given object going to be thrown? The speed will be a random number between the given numbers.
ITEM.ThrowSpeedMax		= 1400;

ITEM.ThrowAngleMin		= Angle( 0, 0, 0 );			--When the item is thrown, what will it's initial angle be? For instance, you don't throw a frisbee rotated vertically do you? Pitch/yaw/roll angle will be random numbers between the given numbers.
ITEM.ThrowAngleMax		= Angle( 360, 360, 360 );

ITEM.ThrowSpread		= Vector( 0, 0, 0 );		--How much do thrown items deviate from their path?

ITEM.ThrowSpinMin		= Angle( -50, -50, -50 );	--How much does the thrown object spin? These angles represent the rotation speed (in degrees/sec?) of pitch, yaw, roll respectively. Pitch/yaw/roll rotation will be random numbers between the given numbers.
ITEM.ThrowSpinMax		= Angle( 50, 50, 50 )

ITEM.ThrowDelay			= 0;						--This is how long it takes to actually throw the weapon after an attack is issued

ITEM.KillCreditTime		= 5;						--After a player throws an item, kills from this item are credited towards this player for this many seconds

local RemoveKillCreditsTimerName = "BaseThrown_RemoveKillCredit";


if SERVER then




ITEM.KillCredit		= nil;




end

local vZero				= Vector( 0, 0, 0 );
local vDefaultOffset	= Vector( 20, 0, 0 );
local angZero			= Angle( 0, 0, 0 );
local fDefaultSpeed		= 1000;

--[[
* SHARED
* Event

Throws the item.
]]--
function ITEM:OnPrimaryAttack()
	self:BeginThrow( self:GetWOwner() );
end

--[[
* SHARED

Begins a throw (throw effects, throw timer if there is a delay).
Any arguments that should be passed to Throw should be given to this function.
]]--
function ITEM:BeginThrow( ... )
	if self.ThrowDelay > 0 then		self:CreateTimer( "ThrowTimer", self.ThrowDelay, 1, self.Throw, ... );
	else							self:Throw( ... );
	end
end

--[[
* SHARED
* Event

Immediately after an item is thrown, this event is called on the thrown item.

To clarify, if you called Throw() on a stack of items, it splits off 1 item,
and then this event runs on the 1 item that was split off - NOT the stack it was originally from.

pl should be the player who threw the item.
]]--
function ITEM:OnThrow( pl )
	
end

--[[
* SHARED
* Event

This event is called by Throw() to determine how fast to throw the item.
]]--
function ITEM:GetThrowSpeed()
	return math.Rand( self.ThrowSpeedMin, self.ThrowSpeedMax );
end

--[[
* SHARED
* Event

This event is called by Throw() to determine the initial angle the thrown item is at.
]]--
function ITEM:GetThrowAngle()	
	return IF.Util:RandomAngle( self.ThrowAngleMin, self.ThrowAngleMax );
end

--[[
* SHARED
* Event

This event is called by Throw() to determine the direction the object is thrown.

vDir is the direction the player is looking.
	Returning vDir means the object will always be thrown in the direction the player is looking.

This event should return a vector pointing in the direction you want the object to be thrown.
	It will be normalized automatically; there's no need to normalize it here.
]]--
function ITEM:GetThrowDirection( vDir )
	return vDir;
end

--[[
* SHARED
* Event

This event is called by Throw() to determine how fast the thrown item's pitch/yaw/roll spins.
]]--
function ITEM:GetThrowSpin()
	return IF.Util:RandomAngle( self.ThrowSpinMin, self.ThrowSpinMax );
end

--[[
* SHARED
* Event

This event is called by Throw() to determine the how far away from the player's shoot position the thrown item appears.
]]--
function ITEM:GetThrowOffset()
	return vDefaultOffset;
end

--[[
* SHARED

Throws an item from this stack.

iCount items are split off from this stack, sent to the world nearby the player, and then thrown.
If there are not that many items in the stack, the rest of the stack is thrown instead.

pl should be the player who threw the item.
iCount is the optional number of items to use in the thrown stack.
	If this is nil/not given it defaults to 1.
fSpeed is an optional speed to throw the items at.
	If this is nil/not given it defaults to whatever the GetThrowSpeed event returns.
aThrowAng is an optional angle the thrown item is at when first thrown.
	If this is nil/not given it defaults to whatever the GetThrowAngle event returns.
aSpin is an optional angle that describes the spin of the thrown object (pitch, yaw, roll).
	If this is nil/not given it defaults to whatever the GetThrowSpin event returns.
vOffset is an optional vector that describes how much to offset the initial position of the object relative to the player's shoot position.
	This is relative to the direction the player is looking.
	If this is nil/not given it defaults to whatever the GetThrowOffset event returns.
	
Serverside, we actually try to throw the item. If this was successful, the item that was thrown is returned.
Clientside, we just predict whether or not the item can be thrown. A temporary item is returned if the item can be thrown.

nil is returned otherwise.
]]--
function ITEM:Throw( pl, iCount, fSpeed, angThrowAng, angSpin, vOffset )
	if !IF.Util:IsPlayer( pl ) then return nil end
	
	--[[
	If this is being held, we can't throw it unless the player has it out.
	In any case, if the player isn't able to interact with it, it can't be thrown.
	]]--
	local eWep = self:GetWeapon();
	if ( eWep && pl:GetActiveWeapon() != eWep ) || !self:Event( "CanPlayerInteract", false, pl ) then return nil end
	
	if iCount == nil then iCount = 1 end
	
	local itemToThrow;
	if iCount < self:GetAmount() then
		itemToThrow = self:Split( iCount, false );
		if !itemToThrow then itemToThrow = self end
	else
		itemToThrow = self;
	end
	
	local angEye	= pl:EyeAngles();
	local vForward	= angEye:Forward();
	local vRight	= angEye:Right();
	local vUp		= angEye:Up();

	if angThrowAng == nil then angThrowAng = self:Event( "GetThrowAngle", angZero ) end
	
	angEye:RotateAroundAxis( angEye:Right(),   -angThrowAng.p );
	angEye:RotateAroundAxis( angEye:Up(),		angThrowAng.y );
	angEye:RotateAroundAxis( angEye:Forward(),	angThrowAng.r );
	
	if vOffset == nil then vOffset = self:Event( "GetThrowOffset" ); end
	local eEnt = itemToThrow:ToWorld( pl:EyePos() + ( vOffset.x * vForward ) - ( vOffset.y * vRight ) + ( vOffset.z * vUp ), angEye );
	if !eEnt then return nil end
	
	if SERVER then
		
		local phys = eEnt:GetPhysicsObject();
		if !IsValid( phys ) then return nil end
		
		vForward = self:Event( "GetThrowDirection", vForward, vForward ):Normalize();
		if fSpeed == nil then fSpeed = self:Event( "GetThrowSpeed", fDefaultSpeed ); end
		
		phys:SetVelocity( ( fSpeed * vForward ) + pl:GetVelocity() );
		
		if angSpin == nil then angSpin = self:Event( "GetThrowSpin", angZero ) end
		phys:AddAngleVelocity( angSpin );
		
		itemToThrow:SetKillCredit( pl, self.KillCreditTime );

	end
	
	itemToThrow:Event( "OnThrow", nil, pl );
	return itemToThrow;
end

--[[
* SHARED
* Event

Primary sound defaults to throw sound
]]--
function ITEM:GetPrimarySound()
	return self:Event( "GetThrowSound", self.ThrowSounds );
end

--[[
* SHARED
* Event

Primary activity defaults to throw activity
]]--
function ITEM:GetPrimaryActivity()
	return self:Event( "GetThrowActivity", self.ThrowActivity );
end

--[[
* SHARED
* Event

Primary activity anim defaults to throw anim
]]--
function ITEM:GetPrimaryPlayerAnim()
	return self:Event( "GetThrowPlayerAnim", self.ThrowPlayerAnim );
end

--[[
* SHARED
* Event

Secondary sound defaults to throw sound
]]--
function ITEM:GetSecondarySound()
	return self:Event( "GetThrowSound", self.ThrowSounds );
end

--[[
* SHARED
* Event

Secondary activity defaults to throw activity
]]--
function ITEM:GetSecondaryActivity()
	return self:Event( "GetThrowActivity", self.ThrowActivity );
end

--[[
* SHARED
* Event

Secondary player anim defaults to throw anim
]]--
function ITEM:GetSecondaryPlayerAnim()
	return self:Event( "GetThrowPlayerAnim", self.ThrowPlayerAnim );
end

--[[
* SHARED
* Event

This event determines what sound should be played when the item is thrown.
If it returns:
	nil or an empty table:				no sound is played
	a Sound( "filepath.wav" ):			that sound is played
	a table of Sound( "filepath.wav" ):	a random sound from that table is played
]]--
function ITEM:GetThrowSound()
	return self.ThrowSounds;
end

--[[
* SHARED
* Event

Returns the viewmodel activity to play when the item is thrown.
]]--
function ITEM:GetThrowActivity()
	return self.ThrowActivity;
end

--[[
* SHARED
* Event

Returns the animation played when the item is thrown
]]--
function ITEM:GetThrowPlayerAnim()
	return self.ThrowPlayerAnim;
end

if SERVER then




--[[
* SERVER

This function credits kills the item is responsible for to the given player for
"fTime" seconds.

NOTE: If the Remove Kill Credits timer is already running, calling this function will cancel or restart it.

pl is an optional value. If pl is:
	a player, credits this player with kills performed by this object.
	nil / not given, then the kill credits are cleared.
fTime is an optional value. If fTime is:
	a number, this will be the # of seconds until the kill credits expire.
	nil / not given, then we just set the kill credits. They won't expire until
]]--
function ITEM:SetKillCredit( pl, fTime )
	self.KillCredit = pl;
	if pl == nil || fTime == nil then self:DestroyTimer( RemoveKillCreditsTimerName ); return end

	self:CreateTimer( RemoveKillCreditsTimerName, fTime, 1, self.SetKillCredit, nil );
end

--[[
* SERVER

Returns the player who should be credited with kills this item is responsible for.
This can be a player or nil.
]]--
function ITEM:GetKillCredit()
	if self.KillCredit && !self.KillCredit:IsValid() then
		self.KillCredit = nil;
	end
	return self.KillCredit;
end

--[[
* SERVER
* Event

The sawblade loses it's kill credits when it leaves the world
]]--
function ITEM:OnExitWorld( bForced )
	self:SetKillCredit( nil );
	return self:BaseEvent( "OnExitWorld", nil, bForced );
end


end