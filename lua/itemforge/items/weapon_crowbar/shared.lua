--[[
weapon_crowbar
SHARED

Bashes people. Opens doors.
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name			= "Crowbar";
ITEM.Description	= "A long, fairly heavy steel rod with teeth.\nGood for prying open doors or pulverising skulls.";
ITEM.Base			= "base_melee";
ITEM.Size			= 19;
ITEM.Weight			= 1500;

ITEM.Spawnable		= true;
ITEM.AdminSpawnable	= true;

if SERVER then

ITEM.GibEffect		= "metal";

end

--Overridden Base Weapon stuff
ITEM.HasPrimary		= true;
ITEM.PrimaryDelay	= 0.4;
ITEM.ViewKickMin	= Angle( 1.0, -2.0, 0 );
ITEM.ViewKickMax	= Angle( 2.0, -1.0, 0 );

--Overridden Base Melee stuff
ITEM.HitRange		= 75;
ITEM.HitForce		= 1;
ITEM.HitDamage		= 25;
ITEM.HitSounds		= {
	Sound( "Weapon_Crowbar.Melee_Hit" )
};
ITEM.MissSounds		= {
	Sound( "Weapon_Crowbar.Single" )
};

--Crowbar
ITEM.ForceOpenSound	= Sound( "doors/vent_open2.wav" );
ITEM.ImpactSounds	= {
	Sound( "Weapon_Crowbar.Melee_HitWorld" )
};

--[[
* SHARED
* Event

If the crowbar's in the world, it gets picked up like any normal item.
But in any other case, we find the entity the player is looking at
and try to open it up.
]]--
function ITEM:OnUse( pl )
	if self:BaseEvent( "OnUse", false, pl ) then return true end
	
	--If this is the active weapon we'll take a swing with it
	local eWep = self:GetWeapon();
	if eWep && pl:GetActiveWeapon() == eWep then return self:Event( "OnSWEPPrimaryAttack", false ) end
	
	--Otherwise (if it was used in an inventory for example) We'll try to find a door to open
	local traceRes = self:MeleeTrace( pl:GetShootPos(), pl:GetAimVector(), self:Event( "GetHitRange", 75 ), self:Event( "GetTolerance", 16 ), pl, self:Event( "GetMaskType", MASK_SHOT ) );
	
	return self:OpenDoor( traceRes.Entity );
end

--[[
* SHARED
* Event

If a door is hit, opens the door.
Otherwise just does the same thing as any other melee weapon.
]]--
function ITEM:OnHit( traceRes )
	if self:OpenDoor( traceRes.Entity ) then return end
	return self:BaseEvent( "OnHit", nil, traceRes );
end

--[[
* SHARED

Serverside this will open the given door.
Clientside it just returns whether or not this is possible.

eDoor is the door entity you want to open.

Returns false if the given entity isn't a door / was invalid / otherwise couldn't be opened.
Returns true otherwise.
]]--
function ITEM:OpenDoor( eDoor )
	if !IsValid( eDoor ) || eDoor:GetClass() != "prop_door_rotating" then return false end
	
	--Clientside we can't actually open doors, so we just return true if they can be opened
	if CLIENT then return true end
	
	eDoor:Fire( "unlock", "", "0" );
	eDoor:Fire( "open", "", "0" );
	eDoor:EmitSound( self.ForceOpenSound );
	return true;
end

if SERVER then




--[[
* SERVER
* Event

Impact sounds.
]]--
function ITEM:OnPhysicsCollide( eEntity, CollisionData, HitPhysObj )
	if ( CollisionData.Speed > 50 && CollisionData.DeltaTime > 0.05 ) then
		self:EmitSound( self.ImpactSounds, CollisionData.Speed, 100 + math.Rand( -20, 20 ) );
	end
end




end