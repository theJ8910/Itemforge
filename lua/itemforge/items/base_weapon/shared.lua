--[[
base_weapon
SHARED

base_weapon is a base. That means that other items borrow code from this so they can be created easier.
Any item that inherits from this has everything this item has, and can override anything this item has.

The base_weapon has two purposes:
	You can tell if an item is a weapon by checking to see if it inherits from base_weapon.
	It's designed to help you create weapons easier. You just have to change/override some variables or replace some stuff with your own code.

TODO need to optimize the networking of Primary/SecondaryNext[Auto] vars
]]--

if SERVER then AddCSLuaFile( "shared.lua" ); end

ITEM.Name						= "Base Weapon";
ITEM.Description				= "This item is the base weapon.\nWeapons inherit from this.\n\nThis is not supposed to be spawned.";
ITEM.WorldModel					= "models/weapons/w_pistol.mdl";
ITEM.ViewModel					= "models/weapons/v_pistol.mdl";

--We don't want players spawning it.
ITEM.Spawnable					= false;
ITEM.AdminSpawnable				= false;


ITEM.SWEPHoldType				= "pistol";


--Base Weapon
--[[
Be aware of how delay works!
PrimaryDelay/SecondaryDelay:
	After attacking with primary or secondary, the weapon can't attack again until it cools down for this long.
PrimaryDelayAuto/SecondaryDelayAuto:
	Whenever a player is holding down his primary/secondary attack button, the weapon will try to attack this often.
	For example, the HL2 pistol can be fired up to 10 times a second if you click fast enough,
	but if you hold down attack, it only attacks twice per second.
	This should be greater than or equal to PrimaryDelay/SecondaryDelay.
	If this is -1, it will be the same as PrimaryDelay/SecondaryDelay.
]]--
ITEM.HasPrimary					= false;					--Does the weapon have a primary attack?
ITEM.PrimaryDelay				= 0.5;
ITEM.PrimaryDelayAuto			= -1;
ITEM.SWEPPrimaryAuto			= true;						--NOTE: This is actually a general property, all items have it (check the base item for a better description). However, auto-attacks are off by default for all other items, and on by default for weapons.
ITEM.PrimaryActivity			= ACT_VM_PRIMARYATTACK;		--What viewmodel animation (i.e. first person) does the primary play?
ITEM.PrimaryPlayerAnim			= PLAYER_ATTACK1;			--What player animation (i.e. third person) does the primary play?
ITEM.PrimarySounds				= nil;						--Plays this sound (or, if this is a table, a random sound from this table) when the primary fires. Plays nothing if this is nil.

ITEM.HasSecondary				= false;					--Does the weapon have a secondary attack?
ITEM.SecondaryDelay				= 0.5;
ITEM.SecondaryDelayAuto			= -1;
ITEM.SWEPSecondaryAuto			= true;						--NOTE: This is actually a general property, all items have it (check the base item for a better description). However, auto-attacks are off by default for all other items, and on by default for weapons.
ITEM.SecondaryActivity			= ACT_VM_SECONDARYATTACK;	--What viewmodel animation (i.e. first person) does the secondary play?
ITEM.SecondaryPlayerAnim		= PLAYER_ATTACK2;			--What player animation (i.e. third person) does the secondary play?
ITEM.SecondarySounds			= nil;						--Plays this sound (or, if this is a table, a random sound from this table) when the secondary fires. Plays nothing if this is nil.

ITEM.ViewKickMin				= Angle( 0, 0, 0 );			--These two values describe minimum and maximum amounts of pitch, yaw, and roll view kick (view rotation) to apply whenever a single shot / swing is fired. The pitch/yaw/roll values are randomized invidually.
ITEM.ViewKickMax				= Angle( 0, 0, 0 );

--Don't modify/override these. They're either set automatically or don't need to be changed.
ITEM.NextPrimary				= 0;
ITEM.NextSecondary				= 0;

--The base weapon doesn't do anything when you attack, except make you wait until you can attack again
--[[
* SHARED
* Event

Handles the primary attack.
Call this as an inherited event if you want the base weapon to handle the cooldowns for you.
]]--
function ITEM:OnSWEPPrimaryAttack()
	if !self.HasPrimary || !self:CanPrimaryAttack() || ( self:Event( "IsPrimaryAttacking", false ) && !self:CanPrimaryAttackAuto() ) then return false end
	
	self:Event( "OnPrimaryAttack" );

	self:DoPrimaryCooldown();
	self:PrimaryEffects();

	return true;
end

--[[
* SHARED
* Event

Handles the secondary attack.
Call this as an inherited event if you want the base weapon to handle the cooldowns for you.
]]--
function ITEM:OnSWEPSecondaryAttack()
	if !self.HasSecondary || !self:CanSecondaryAttack() || ( self:Event( "IsSecondaryAttacking", false ) && !self:CanSecondaryAttackAuto() ) then return false end
	
	self:Event( "OnSecondaryAttack" );

	self:DoSecondaryCooldown();
	self:SecondaryEffects();

	return true;
end




--[[
* SHARED
* Event

This code controls what happens when the weapon successfully primary attacks (the player tried to primary attack, and the primary wasn't cooling down).
]]--
function ITEM:OnPrimaryAttack()

end

--[[
* SHARED

Stop the weapon's primary from attacking until [fNext], which is usually CurTime() + some delay.
Does nothing if the weapon doesn't have a primary.
If this function is run serverside, it will also sync the next primary attack clientside.

fNext is the next time the weapon's primary can attack, period.
fNextAuto is optional (defaults to fNext). This is the next time the weapon's primary can auto-attack.
]]--
function ITEM:SetNextPrimary( fNext, fNextAuto )
	if !self.HasPrimary then return end
	self.NextPrimary = fNext;
	
	--If we have an SWEP available we use the built-in "NextPrimaryFire" fire stuff since it plays better with prediction
	local eWep = self:GetWeapon();
	if eWep then	eWep:SetNextPrimaryFire( fNext )
	else			self:SetNWFloat( "PrimaryNext", fNext );
	end
	
	self:SetNWFloat( "LastPrimaryDelay", fNext - CurTime() );
	
	if fNextAuto == nil || fNext == fNextAuto then	self:SetNWFloat( "PrimaryNextAuto", nil );
	else											self:SetNWFloat( "PrimaryNextAuto", fNextAuto );
	end
end

--[[
* SHARED

Shortcut for performing standard primary cooldown
Sets both delay and auto-delay to whatever is returned by GetPrimaryDelay / GetPrimaryDelayAuto.
]]--
function ITEM:DoPrimaryCooldown()
	self:SetNextPrimary( CurTime() + self:Event( "GetPrimaryDelay", 0.5 ),
						 CurTime() + self:Event( "GetPrimaryDelayAuto", 0.5 )
					   );
end

--[[
* SHARED

Returns the next time this item is allowed to primary-fire
]]--
function ITEM:GetNextPrimary()
	local eWep = self:GetWeapon();
	if eWep then	return eWep:GetNextPrimaryFire();
	else			return self:GetNWFloat( "PrimaryNext" );
	end
end

--[[
* SHARED

Returns the next time the item will primary attack if the primary attack button is being held down
]]--
function ITEM:GetNextPrimaryAuto()
	return self:GetNWFloat( "PrimaryNextAuto" );
end

--[[
* SHARED

Can we attack with primary, or is the weapon cooling down right now?
]]--
function ITEM:CanPrimaryAttack()
	return CurTime() >= self:GetNextPrimary();
end

--[[
* SHARED

Can we auto-attack with primary yet?
Returns false if we can't auto-attack with primary yet.
]]--
function ITEM:CanPrimaryAttackAuto()
	return CurTime() >= self:GetNextPrimaryAuto();
end

--[[
* SHARED
* Event

Returns the primary delay.
]]--
function ITEM:GetPrimaryDelay()
	return self.PrimaryDelay;
end

--[[
* SHARED
* Event

Returns the auto-primary delay.
]]--
function ITEM:GetPrimaryDelayAuto()
	return ( ( self.PrimaryDelayAuto != -1 && self.PrimaryDelayAuto ) || self:Event( "GetPrimaryDelay", 0.5 ) );
end

--[[
* SHARED
* Event

Returns true if the primary is being auto-fired.
	By default, this only occurs when a player has the weapon out and holds his primary attack button.
Returns false otherwise.
]]--
function ITEM:IsPrimaryAttacking()
	local plOwner = self:GetWOwner();
	if !plOwner then return false end

	return plOwner:KeyDownLast( IN_ATTACK );
end

--[[
* SHARED

Plays the primary's sound effect and plays the player / viewmodel animations associated with primary.
]]--
function ITEM:PrimaryEffects()
	self:EmitSound( self:Event( "GetPrimarySound" ), true );
	
	local eWep = self:GetWeapon();
	if !eWep then return false end
	
	self:SendWeaponAnim(			self:Event( "GetPrimaryActivity",		ACT_VM_PRIMARYATTACK	) );
	self:GetWOwner():SetAnimation(	self:Event( "GetPrimaryPlayerAnim",		PLAYER_ATTACK1			) );
end

--[[
* SHARED
* Event

This event determines what sound should be played when the weapon's primary is successfully activated.
If it returns:
	nil or an empty table:				no sound is played
	a Sound( "filepath.wav" ):			that sound is played
	a table of Sound( "filepath.wav" ):	a random sound from that table is played
]]--
function ITEM:GetPrimarySound()
	return self.PrimarySounds;
end

--[[
* SHARED
* Event

Returns the viewmodel activity to play when the primary is fired
]]--
function ITEM:GetPrimaryActivity()
	return self.PrimaryActivity;
end

--[[
* SHARED
* Event

Returns the animation played when the player uses the weapon's primary attack
]]--
function ITEM:GetPrimaryPlayerAnim()
	return self.PrimaryPlayerAnim;
end






--[[
* SHARED
* Event

This event controls what happens when the weapon successfully secondary attacks (the player tried to secondary attack, and the secondary wasn't cooling down).
]]--
function ITEM:OnSecondaryAttack()

end

--[[
* SHARED

Stop the weapon's secondary from attacking until [fNext], which is usually CurTime() + some delay.
Does nothing if the weapon doesn't have a secondary.
If this function is run serverside, it will also sync the next secondary attack clientside.

fNext is the next time the weapon's secondary can attack, period.
fNextAuto is optional (defaults to fNext). This is the next time the weapon's secondary can auto-attack.
]]--
function ITEM:SetNextSecondary( fNext, fNextAuto )
	if !self.HasSecondary then return end
	self.NextSecondary = fNext;
	
	--If we have an SWEP available we use the built-in "NextSecondaryFire" fire stuff since it plays better with prediction
	local eWep = self:GetWeapon();
	if eWep then	eWep:SetNextSecondaryFire( fNext );
	else			self:SetNWFloat( "SecondaryNext", fNext );
	end
	
	if fNextAuto == nil || fNext == fNextAuto then		self:SetNWFloat( "SecondaryNextAuto", nil );
	else												self:SetNWFloat( "SecondaryNextAuto", fNextAuto );
	end
end

--[[
* SHARED

Shortcut for performing standard secondary cooldown.
Sets both delay and auto-delay.
]]--
function ITEM:DoSecondaryCooldown()
	self:SetNextSecondary( CurTime() + self:Event( "GetSecondaryDelay", 0.5 ),
						   CurTime() + self:Event( "GetSecondaryDelayAuto", 0.5 )
						 );
end

--[[
* SHARED

Returns the next time this item is allowed to secondary-fire
]]--
function ITEM:GetNextSecondary()
	local eWep = self:GetWeapon();
	if eWep then	return eWep:GetNextSecondaryFire();
	else			return self:GetNWFloat( "SecondaryNext" );
	end
end

--[[
* SHARED

Returns the next time the item will secondary attack if the secondary attack button is being held down
]]--
function ITEM:GetNextSecondaryAuto()
	return self:GetNWInt( "SecondaryNextAuto" );
end

--[[
* SHARED

Can we attack with secondary, or is the weapon cooling down right now?
]]--
function ITEM:CanSecondaryAttack()
	return CurTime() >= self:GetNextSecondary();
end

--[[
* SHARED

Can we auto-attack with secondary yet?
Returns false if we can't auto-attack with secondary yet.
]]--
function ITEM:CanSecondaryAttackAuto()
	return CurTime() >= self:GetNextSecondaryAuto();
end

--[[
* SHARED
* Event

Returns the secondary delay.
]]--
function ITEM:GetSecondaryDelay()
	return self.SecondaryDelay;
end

--[[
* SHARED
* Event

Returns the auto-secondary delay.
]]--
function ITEM:GetSecondaryDelayAuto()
	return ( ( self.SecondaryDelayAuto != -1 && self.SecondaryDelayAuto ) || self:Event( "GetSecondaryDelay", 0.5 ) );
end

--[[
* SHARED
* Event

Returns true if the secondary is being auto-fired.
	By default, this only occurs when a player has the weapon out and holds his secondary attack button.
Returns false otherwise.
]]--
function ITEM:IsSecondaryAttacking()
	local plOwner = self:GetWOwner();
	if !plOwner then return false end

	return plOwner:KeyDownLast( IN_ATTACK2 );
end

--[[
* SHARED

Plays the secondary's sound effect and plays the player / viewmodel animations associated with secondary.
]]--
function ITEM:SecondaryEffects()
	self:EmitSound( self:Event( "GetSecondarySound" ), true );
	
	local eWep = self:GetWeapon();
	if !eWep then return false end

	self:SendWeaponAnim(			self:Event( "GetSecondaryActivity",		ACT_VM_SECONDARYATTACK	) );
	self:GetWOwner():SetAnimation(	self:Event( "GetSecondaryPlayerAnim",	PLAYER_ATTACK2			) );
end

--[[
* SHARED
* Event

This event determines what sound should be played when the weapon's secondary is successfully activated.
If it returns:
	nil or an empty table:				no sound is played
	a Sound( "filepath.wav" ):			that sound is played
	a table of Sound( "filepath.wav" ):	a random sound from that table is played
]]--
function ITEM:GetSecondarySound()
	return self.SecondarySounds;
end

--[[
* SHARED
* Event

Returns the viewmodel activity to play when the secondary is fired
]]--
function ITEM:GetSecondaryActivity()
	return self.SecondaryActivity;
end

--[[
* SHARED
* Event

Returns the animation played when the player uses the weapon's secondary attack
]]--
function ITEM:GetSecondaryPlayerAnim()
	return self.SecondaryPlayerAnim;
end





--[[
* SHARED

Shortcut for delaying the primary and secondary from attacking until [fNext].
Also stops the primary and secondary from auto attacking until [fNextAuto] or, if not given, [fNext]. 
]]--
function ITEM:SetNextBoth( fNext, fNextAuto )
	self:SetNextPrimary( fNext, fNextAuto );
	self:SetNextSecondary( fNext, fNextAuto );
end

--[[
* SHARED

Shortcut for performing standard primary weapon delay that stops both the primary and secondary.
Sets both delay and auto-delay to whatever is returned by GetPrimaryDelay / GetPrimaryDelayAuto.
]]--
function ITEM:DoPrimaryCooldownBoth()
	self:SetNextBoth( CurTime() + self:Event( "GetPrimaryDelay", 0.5 ),
					  CurTime() + self:Event( "GetPrimaryDelayAuto", 0.5 )
					);
end

--[[
* SHARED

Shortcut for performing standard secondary weapon delay that stops both the primary and secondary.
Sets both delay and auto-delay to whatever is returned by GetSecondaryDelay / GetSecondaryDelayAuto.
]]--
function ITEM:DoSecondaryCooldownBoth()
	self:SetNextBoth( CurTime() + self:Event( "GetSecondaryDelay", 0.5 ),
					  CurTime() + self:Event( "GetSecondaryDelayAuto", 0.5 )
					);
end

--[[
* SHARED

Kicks the holding player's view.
No effect if not currently being held as a weapon.

The angles that the player's view will be kicked is chosen by randomly selecting invidual pitch / yaw / roll values between angMin and angMax.

true is returned if the view kick was applied.
false is returned otherwise.
]]--
function ITEM:AddViewKick( angMin, angMax )
	local pl = self:GetWOwner();
	if !pl then return false end
	
	pl:ViewPunch( IF.Util:RandomAngle( angMin, angMax ) );
end

--[[
* SHARED
* Event

After the item is held it needs to apply the item's NextPrimaryFire / NextSecondaryFire to the SWEP (since weapons and items use different systems)
]]--
function ITEM:OnHold( pl, eWep )
	self:BaseEvent( "OnHold", nil, pl, eWep );
	
	eWep:SetNextPrimaryFire( self.NextPrimary );
	eWep:SetNextSecondaryFire( self.NextSecondary );
end

--[[
* SHARED
* Event

After the item is released it needs to reapply the NextPrimaryFire / NextSecondaryFire to the item (since weapons and items use different systems)
]]--
function ITEM:OnRelease( pl, bForced )
	self:BaseEvent( "OnRelease", nil, pl, bForced );
	
	self:SetNWFloat( "PrimaryNext", self.NextPrimary );
	self:SetNWFloat( "SecondaryNext", self.NextSecondary );
end

if CLIENT then




--[[
* CLIENT

Stranded 2 has this cool thing where after firing a weapon it shows the cooldown as
a red border around the item slot that slowly fades as the weapon cools down. Then the border
suddenly flashes green to indicate the cooldown has ended.

This function implements this feature on Itemforge weapons, although it only works for
the primary attack's cooldown. I haven't quite figured out how to account both for the primary
and secondary being displayed cooling down in a way that wasn't completely retarded.
]]--
function ITEM:OnDraw2D( iWidth, iHeight )
	self:BaseEvent( "OnDraw2D", nil, iWidth, iHeight );
	
	local fRemainingTime = self:GetNextPrimary() - CurTime();
	local fDelay = self:GetNWFloat( "LastPrimaryDelay" );
	
	if fRemainingTime <= -0.5 || fDelay == 0 then			return nil;																		--If we haven't recently cooled down, or if the cooldown is instant there's no need to draw a border
	elseif fRemainingTime > 0 then							surface.SetDrawColor( 255, 0, 0, 255 * ( fRemainingTime / fDelay ) );			--If we're cooling down we draw a red border that fades as cooldown finishes
	else													surface.SetDrawColor( 0, 255, 0, 255 * ( ( 0.5 + fRemainingTime ) / 0.5 ) );	--If we just finished a cooled down we draw a green border that lasts a half-second
	end
	
	--Vertical lines
	surface.DrawRect( 2,			2,	1, iHeight - 4 );
	surface.DrawRect( iWidth - 3,	2, 	1, iHeight - 4 );
	
	--Horizontal lines
	surface.DrawRect( 3, 2,				iWidth - 6, 1 );
	surface.DrawRect( 3, iHeight - 3	,	iWidth - 6, 1 );
end




end

IF.Items:CreateNWVar( ITEM, "PrimaryNext",			"float",	0,														nil,	true, true );
IF.Items:CreateNWVar( ITEM, "PrimaryNextAuto",		"float",	function( self ) return self:GetNextPrimary() end,		nil,	true, true );
IF.Items:CreateNWVar( ITEM, "SecondaryNext",		"float",	0,														nil,	true, true );
IF.Items:CreateNWVar( ITEM, "SecondaryNextAuto",	"float",	function( self ) return self:GetNextSecondary() end,	nil,	true, true );

IF.Items:CreateNWVar( ITEM, "LastPrimaryDelay",		"float",	0,														nil,	true, true );