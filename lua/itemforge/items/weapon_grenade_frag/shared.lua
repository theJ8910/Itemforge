--[[
weapon_grenade_frag
SHARED

Explosive fragmentation grenade.
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name				= "Frag Grenade";
ITEM.Description		= "This is an M26 fragmentation grenade, a variety of high-explosive hand grenades.\nPull the pin and throw. The pin can be pulled before being thrown.\nBe careful! Highly explosive!";
ITEM.Base				= "base_thrown";

ITEM.Weight				= 454;										--454 grams (taken from http://en.wikipedia.org/wiki/M26_grenade )
ITEM.MaxHealth			= 10;
ITEM.MaxAmount			= 15;

ITEM.WorldModel			= "models/weapons/w_eq_fraggrenade.mdl";
ITEM.ViewModel			= "models/weapons/v_eq_fraggrenade.mdl";
ITEM.SWEPViewModelFlip	= true;										--Some CS view models need to be flipped

ITEM.Spawnable			= true;
ITEM.AdminSpawnable		= true;

--Overridden base weapon stuff
ITEM.HasPrimary			= true;

--Overridden base thrown stuff
ITEM.ThrowSpeedMin		= 500;
ITEM.ThrowSpeedMax		= 1000;
ITEM.ThrowDelay			= 0.1;

--Frag Grenade
ITEM.ExplodeDamage		= 110;
ITEM.ExplodeDelay		= 5;
ITEM.PullPinSound		= Sound( "weapons/smg1/switch_burst.wav" );

--[[
* SHARED
* Event

If you intentionally use the grenade (i.e. you weren't trying to pick it up by pressing [E] on it while it's in the world),
then the grenade's pin is pulled. Hint - Hide them in containers, then pull the pin!
]]--
function ITEM:OnUse( pl )
	--[[
	Its in the world. We probably want to pick it up, so we can throw it back to the guy who threw it
	(or you know, maybe it's just lying around and we want to take it)
	]]--
	if self:InWorld() then
		return self:BaseEvent( "OnUse", false, pl );
	end
	
	--Definitely not intending to pick it up. Pull the pin and run!
	return self:PullPin( pl );
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
	self:PullPin( pl );
end

--[[
* SHARED

Pulls the pin on the grenade if it hasn't been pulled already.
The grenade becomes live, and the explosion timer is activated.

pl should be the player who is credited with pulling the pin.
]]--
function ITEM:PullPin( pl )
	if self:GetNWBool( "Live" ) then return false end
	self:SetNWBool( "Live", true );

	self:EmitSound( self.PullPinSound, true );

	if SERVER then
		self:SimpleTimer( self.ExplodeDelay, self.DoExplosion, pl );
	end
	
	return true;
end

--[[
* SHARED
* Event

Active grenades cannot be merged (you can still have a stack of active grenades, though).
]]--
function ITEM:CanMerge( otherItem, bToHere )
	return !self:GetNWBool( "Live" );
end

--[[
* SHARED
* Event

Active grenades cannot be split (you can still have a stack of active grenades, though).
]]--
function ITEM:CanSplit( iHowMany )
	return !self:GetNWBool( "Live" );
end

if SERVER then




--[[
* SERVER

Does a standard grenade explosion.

eWhoTriggered is an optional player / entity to credit the kill to.
]]--
function ITEM:DoExplosion( eWhoTriggered )
	self:Explode( self.ExplodeDamage * self:GetAmount(), 256, eWhoTriggered );
end

--[[
* SERVER
* Event

If a grenade gets destroyed, it explodes
]]--
function ITEM:OnBreak( iHowMany, bLastBroke, eWho )
	self:DoExplosion( eWho );
end

--[[
* SERVER
* Event

If a grenade is launched from a Rock-It launcher, it activates.

iRockitLauncher is the rock-it launcher the grenade was fired from.
pl is the player who fired it.
]]--
function ITEM:OnRockItLaunch( iRockitLauncher, pl )
	self:PullPin( pl );
end

--[[
* SERVER
* Event

This event tells Wiremod that our grenades can have their pins pulled or they can explode
]]--
function ITEM:GetWireInputs( eEntity )
	return Wire_CreateInputs( eEntity, { "Pull Pin", "Explode" } );
end

--[[
* SERVER
* Event

This event handles Wiremod's requests
]]--
function ITEM:OnWireInput( eEntity, strInputName, vValue )
	if		strInputName == "Pull Pin"	&&	vValue != 0 then	self:PullPin();
	elseif	strInputName == "Explode"	&&	vValue != 0 then	self:DoExplosion();
	end
end




else




--[[
* CLIENT
* Event

When grenades are active, the background flashes red
]]--
function ITEM:OnDraw2DBack( fWidth, fHeight )
	if self:GetNWBool( "Live" ) == true then
		surface.SetDrawColor( 255, 0, 0, 114.75 + 63.75 * math.sin( 30 * RealTime() ) );
		surface.DrawRect( 0, 0, fWidth, fHeight );
	end
	self:BaseEvent( "OnDraw2DBack", nil, fWidth, fHeight );
end




end

IF.Items:CreateNWVar( ITEM, "Live", "bool", false );