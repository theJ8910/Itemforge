--[[
weapon_357
SHARED

The Itemforge version of the Half-Life 2 .357 revolver.
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name					= "Colt Python";
ITEM.Description			= "This is a Colt Python, a .357 revolver.\nThis weapon is designed for use with .357 rounds.";
ITEM.Base					= "base_firearm";
ITEM.Weight					= 1360;								--48 oz from http://half-life.wikia.com/wiki/.357_Magnum and http://en.wikipedia.org/wiki/Colt_Python
ITEM.Size					= 13;

ITEM.Spawnable				= true;
ITEM.AdminSpawnable			= true;

ITEM.WorldModel				= "models/weapons/W_357.mdl";
ITEM.ViewModel				= "models/weapons/v_357.mdl";

if SERVER then




ITEM.GibEffect				= "metal";




end

--Overridden Base Weapon stuff
ITEM.HasPrimary				= true;
ITEM.PrimaryDelay			= 0.75;								--Taken directly from the modcode.
ITEM.PrimarySounds			= Sound( "Weapon_357.Single" );

--Overridden Base Ranged Weapon stuff
ITEM.Clips					= {};
ITEM.Clips[1]				= { Type = "ammo_357", Size = 6 };

ITEM.PrimaryClip			= 1;
ITEM.PrimaryFiresUnderwater	= false;

ITEM.ReloadDelay			= 3.6666667461395;
ITEM.ReloadSounds			= nil;

--Overridden Base Firearm stuff
ITEM.BulletDamage			= 75;
ITEM.BulletSpread			= Vector( 0, 0, 0 );		--Taken directly from modcode; this is 0 degrees. The .357 is perfectly accurate.
ITEM.ViewKickMin			= Angle( -8, -2, 0 );		--Taken directly from modcode. The view kicks up.
ITEM.ViewKickMax			= Angle( -8, 2, 0 );

--.357 Revolver
ITEM.DelayedReloadSounds	= {							--When a viewmodel is not available, we have to play the reload sounds manually...
	Sound( "Weapon_357.OpenLoader" ),
	Sound( "Weapon_357.RemoveLoader" ),
	Sound( "Weapon_357.ReplaceLoader" ),
	Sound( "Weapon_357.Spin" )
}

local angDown = Angle( 90, 0, 0 );

--[[
* SHARED
* Event

Same as normal firearm primary attack, but also bumps the player's view.
]]--
function ITEM:OnSWEPPrimaryAttack()
	if !self:BaseEvent( "OnSWEPPrimaryAttack", false ) then return false end
	
	--[[
	We need to snap the holding player's eyes on the server;
	if we can't do that for some reason just return true to indicate everything else went as planned
	]]--
	if CLIENT || !self:IsHeld() then return true end
	local pl = self:GetWOwner();
	
	--This is not a mistake. The modcode calls RandomInt, which corresponds to math.random in Lua.
	ang = pl:GetLocalAngles();
	ang.p = ang.p + math.random( -1, 1 );
	ang.y = ang.y + math.random( -1, 1 );
	ang.r = 0;
	
	pl:SnapEyeAngles( ang );
end

--[[
* SHARED
* Event

Secondary attack does NOTHING
]]--
function ITEM:OnSWEPSecondaryAttack()
end

--[[
* SHARED
* Event

Does the same reload as normal firearms, plus plays empty shell ejection effects.
If the weapon wasn't being held, delayed reload sounds play (the viewmodel takes care of reload sounds in other cases).
]]--
function ITEM:OnSWEPReload()
	if !self:BaseEvent( "OnSWEPReload", false ) then return false end
	
	self:SimpleTimer( 1.5, self.EmptyShells );

	if self:IsHeld() then return true end
	self:PlayDelayedReloadSounds();

	return true;
end

--[[
* SHARED

Mimics the viewmodel's reload sounds by playing the same reload sounds at appropriate times
]]--
function ITEM:PlayDelayedReloadSounds()
	self:SimpleTimer( 0.9,	self.EmitSound, self.DelayedReloadSounds[1] );
	self:SimpleTimer( 1.2,	self.EmitSound, self.DelayedReloadSounds[2] );
	self:SimpleTimer( 2.2,	self.EmitSound, self.DelayedReloadSounds[3] );
	self:SimpleTimer( 3,	self.EmitSound, self.DelayedReloadSounds[4] );
end


--[[
* SHARED

Plays shell emptying effects for the given player.

Unlike automatic weapons, revolvers do not automatically eject their shells when fired.
During a reload, the shells are emptied manually, all 6 at once.
The original HL2 revolver neglects to do shell ejections visible to other players, so I do some here.

This function should be called at an appropriate time during reload.
]]--
function ITEM:EmptyShells()
	if SERVER then
		self:SendNWCommand( "EmptyShells" );
	else
		for i = 1, 6 do
			if !self:ShellEject() then return false end
		end
	end
	
	return true;
end

if SERVER then




IF.Items:CreateNWCommand( ITEM, "EmptyShells" );




else




--[[
* CLIENT

Ejects a single pistol shell from the revolver.
Shells are always ejected downwards, regardless of the weapon's orientation.
This is based on the emptying animation from the viewmodel.

Returns true if a shell was ejected, false otherwise.
]]--
function ITEM:ShellEject()
	local eEnt = self:GetEntity();
	if !eEnt then return false end

	local effectdata = EffectData();
	effectdata:SetOrigin( eEnt:GetPos() );
	effectdata:SetAngle( angDown );
    util.Effect( "ShellEject", effectdata );

	return true;
end

IF.Items:CreateNWCommand( ITEM, "EmptyShells", function( self, ... ) self:EmptyShells( ... ) end );




end

