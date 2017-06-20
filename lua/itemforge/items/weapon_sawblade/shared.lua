--[[
weapon_sawblade
SHARED

A sawblade. It sticks in things if it hits it fast enough.
The math for this was a little irritating but I think I've got it down now.

The sawblade is a throwable, stackable weapon.

View Model by NeoDement
TODO use ent:GetBloodType()
]]--

if SERVER then

AddCSLuaFile( "shared.lua" );
	
--We also need to send the viewmodel
resource.AddFile( "models/weapons/v_sawblade.mdl" );
resource.AddFile( "models/weapons/V_sawblade.dx80.vtx" );
resource.AddFile( "models/weapons/V_sawblade.dx90.vtx" );
resource.AddFile( "models/weapons/V_sawblade.sw.vtx" );
resource.AddFile( "models/weapons/v_sawblade.vvd" );

end

ITEM.Name			= "Sawblade";
ITEM.Description	= "A circular steel sawblade with razor-sharp teeth.\nThese types of blades are often a part of woodworking machinery.";
ITEM.Base			= "base_thrown";
ITEM.MaxAmount		= 10;
ITEM.Size			= 26;
ITEM.Weight			= 5000;				--Weighs approximately 36 kg or around 72 pounds (YEESH - the sawblade is about 2 feet in diameter though, and made out of steel. It's not that surprising is it?). Calculated using density of steel #1 (http://hypertextbook.com/facts/2004/KarenSutherland.shtml) multiplied by the volume in cubic centimeters (converted from game units) of an inner cylinder subtracted from an outer cylinder. The thickness and radii were calculated by getting the distance between trace .HitPos itions on the sawblade model.
ITEM.Spawnable		= true;
ITEM.AdminSpawnable	= true;
ITEM.SWEPHoldType	= "slam";
ITEM.WorldModel		= "models/props_junk/sawblade001a.mdl";
ITEM.ViewModel		= "models/weapons/v_sawblade.mdl";

--[[
These are different ways the sawblade's viewmodel can be oriented
(horizontal, vertical, or transitioning between the one or the other)
]]--
local ORIENT_HORIZ	= 1;
local ORIENT_VERT	= 2;
local ORIENT_HTOV	= 3;
local ORIENT_VTOH	= 4;

if CLIENT then




ITEM.Icon						= Material( "itemforge/items/item_sawblade" );
ITEM.WorldModelNudge			= Vector( 18, 0, 0 );
ITEM.WorldModelRotate			= Angle( 0, 45, 0 );

--[[
These variables relate to the orientation of the sawblade's viewmodel.
While transitioning from one state to another, InterpFromTime is when the
transition starts, and InterpToTime is when the transition ends. InterpDelay
is how much time that will between these two times.
Vertical shift is how much the viewmodel is shifted to the right when the sawblade
is oriented vertically. Vertical roll is how much the viewmodel is rotated when the
sawblade is oriented horizontally.
]]--
ITEM.ViewModelOrientation		= ORIENT_HORIZ;
ITEM.ViewModelInterpDelay		= 0.3;
ITEM.ViewModelInterpFromTime	= 0;
ITEM.ViewModelInterpToTime		= 0;
ITEM.ViewModelVerticalShift		= 20;
ITEM.ViewModelVerticalRoll		= 90;

else




ITEM.GibEffect = "metal";




end

--Overridden base weapon stuff
ITEM.HasPrimary					= true;
ITEM.PrimaryDelay				= 1.5;
ITEM.HasSecondary				= true;
ITEM.SecondaryDelay				= 1.5;

--Overridden base thrown stuff
ITEM.ThrowSounds				= Sound( "WeaponFrag.Throw" );
ITEM.ThrowDelay					= 0.2;
ITEM.ThrowAngleMin				= Angle( 0, 0, 0 );		--Left-clicking tosses the sawblade such that it's oriented horizontally
ITEM.ThrowAngleMax				= Angle( 0, 0, 0 );
ITEM.ThrowSpinMin				= Angle( 0, 0, -2000 );
ITEM.ThrowSpinMax				= Angle( 0, 0, -500 );


--Sawblade
ITEM.ThrowAngleVert				= Angle( 0, 0, 90 );	--Right-clicking tosses the sawblade such that it's oriented vertically
ITEM.StickSpeed					= 500;					--The sawblade has to be going at least this fast to stick into something
ITEM.StickBy					= 9;					--The sawblade will dig in this far (in units) when it hits something
ITEM.StickStrength				= 30000;				--When the sawblade welds to another prop it takes this much force to break the weld.
ITEM.StickDamage				= 10;					--This much damage is applied when the sawblade is stuck in something
ITEM.UnstickDamage				= 10;					--This much damage is applied when the sawblade is unstuck from something
ITEM.MinAngleCos				=  0.7071067812;		--This is the cosine of the minimum angle the sawblade must hit an object "head on" to stick into. By default, this is the cosine of 45 degrees in radians:		0.25 * PI =  PI / 4 = 45 degrees;	cos( PI  / 4 ) =  0.7071067812
ITEM.MaxAngleCos				= -0.7071067812;		--This is the cosine of the maximum angle the sawblade must hit an object "head on" to stick into. By default, this is the cosine of 135 degrees in radians:	0.75 * PI = 3PI / 4 = 135 degrees;	cos( 3PI / 4 ) = -0.7071067812

--A random sound here plays whenever the sawblade sticks in something
ITEM.StickSounds				= {
	Sound( "physics/metal/sawblade_stick1.wav" ),
	Sound( "physics/metal/sawblade_stick2.wav" ),
	Sound( "physics/metal/sawblade_stick3.wav" )
}

--Random sound from here plays when the sawblade has been pulled out of something
ITEM.UnstickSounds				= {
	Sound( "npc/roller/blade_out.wav" )
};

--Random sound from here plays when a cut has been made.
ITEM.FleshyImpactSounds			= {
	Sound( "ambient/machines/slicer1.wav" ),
	Sound( "ambient/machines/slicer2.wav" ),
	Sound( "ambient/machines/slicer3.wav" ),
	Sound( "ambient/machines/slicer4.wav" )
}

if SERVER then




ITEM.SawbladeRadius				= 17;									--Radius of the sawblade from it's center to it's edge. Used for rope cutting tests.
ITEM.RopeCutSound				= Sound( "TripwireGrenade.ShootRope" );	--This sound plays after a rope is cut
ITEM.RopeCutSoundLength			= 0.4;									--The sound I use is too long, so I only play it for this long.
ITEM.WeldRemoveEventName		= "IF_Unstuck";							--This is the unique ID given for the "CallOnRemove" event the sawblade assigns to stick-in welds.

--[[
These entities are considered bloody (they bleed when they are hit with the sawblade)
	If an entity is not listed here, it doesn't bleed. The sawblade will stick to these entities when it hits them.
	A value of 1 indicates the entity bleeds red blood.
	A value of 2 indicates the entity bleeds yellow blood.
	A value of 3 indicates the entity bleeds white blood.
]]--
ITEM.BloodyTypes				= {
	["player"]						= 1,
	["npc_monk"]					= 1,
	["npc_crow"]					= 1,
	["npc_pigeon"]					= 1,
	["npc_seagull"]					= 1,
	["npc_combine_s"]				= 1,
	["npc_hunter"]					= 3,
	["npc_alyx"]					= 1,
	["npc_barney"]					= 1,
	["npc_citizen"]					= 1,
	["npc_kleiner"]					= 1,
	["npc_magnusson"]				= 1,
	["npc_eli"]						= 1,
	["npc_gman"]					= 1,
	["npc_mossman"]					= 1,
	["npc_breen"]					= 1,
	["npc_vortigaunt"]				= 2,
	["npc_metropolice"]				= 1,
	["npc_antlion"]					= 2,
	["npc_antlion_worker"]			= 2,
	["npc_antlion_grub"]			= 2,
	["npc_antlionguard"]			= 2,
	["npc_barnacle"]				= 2,
	["npc_zombie_torso"]			= 2,
	["npc_fastzombie_torso"]		= 2,
	["npc_zombie"]					= 2,
	["npc_fastzombie"]				= 2,
	["npc_poisonzombie"]			= 2,
	["npc_zombine"]					= 2,
	["npc_headcrab"]				= 2,
	["npc_headcrab_fast"]			= 2,
	["npc_headcrab_black"]			= 2,
	["npc_headcrab_poison"]			= 2,
}

ITEM.PhysHoldPlayers			= nil;				--This is a list of players currently holding the sawblade with the physgun / gravgun




end

--Don't modify/override these; they're set automatically.
ITEM.StickingTo = nil;

--[[
* SHARED
* Event

Throws the item oriented horizontally.
This override is necessary because base_thrown only cooldowns the primary attack. This cooldowns the secondary too.
]]--
function ITEM:OnPrimaryAttack()
	self:BaseEvent( "OnPrimaryAttack" );
	if CLIENT then self:OrientHorizontal() end
	
	--We want it to delay both the primary AND secondary attacks (primary attack delay is already taken care of)
	self:DoSecondaryCooldown();

	return true;
end


--[[
* SHARED
* Event

Throws the item oriented vertically.
]]--
function ITEM:OnSecondaryAttack()
	self:BaseEvent( "OnSecondaryAttack" );
	if CLIENT then self:OrientVertical() end
	
	--We want it to delay both the secondary AND primary attacks (secondary attack delay is already taken care of)
	self:DoPrimaryCooldown();

	self:BeginThrow( self:GetWOwner(), nil, nil, self.ThrowAngleVert );
	
	return true;
end


if SERVER then




--[[
* SERVER
]]--
local function IsPointInWedge( eLCRope, vCutPos, self, vSawCenter, vProjectedVel )
	return ( vSawCenter:Distance( vCutPos ) <= self.SawbladeRadius && vProjectedVel:Dot( ( vCutPos - vSawCenter ):Normalize() ) > 0 );
end

--[[
* SERVER

Sawblades start thinking when they enter the world
]]--
function ITEM:OnEnterWorld( eEnt, vPos, aAng, bTeleport )
	self:BaseEvent( "OnEnterWorld" );
	self:StartThink();
end

--[[
* SERVER

Sawblades stop thinking when they exit the world
]]--
function ITEM:OnExitWorld( bForced )
	self:BaseEvent( "OnExitWorld" );
	self:StopThink();
end

--[[
* SERVER

If the sawblade is going fast enough it can cut ropes
]]--
function ITEM:OnThink()
	local eEntity = self:GetEntity();
	if !eEntity then return end

	local vVel = eEntity:GetVelocity();
	local vUp = eEntity:GetUp();
	local vProjectedVel = vVel - vUp * vVel:Dot( vUp );
	if vProjectedVel:LengthSqr() >= 250000 then		--500 * 500 = 250000
		local vSawCenter = eEntity:GetPos();
		if IF.Util:CutRopes( vSawCenter, vUp, nil, IsPointInWedge, self, vSawCenter, vProjectedVel ) then
			self:LoopingSound( self.RopeCutSound, "WeaponSawblade_RopeCutSound" );
			self:SimpleTimer( self.RopeCutSoundLength, self.StopLoopingSound, "WeaponSawblade_RopeCutSound" );
		end
	end
end

--[[
* SERVER
* Event

Sawblades in the world don't merge if they've recently been thrown.
This is so sawblades can stick to one another.
]]--
function ITEM:CanWorldMerge()
	--If a sawblade has been recently thrown, it will still have a player to give kill credits to.
	if self:GetKillCredit() then return false end
	return self:BaseEvent( "CanMerge", false );
end

--[[
* SERVER
* Event

When the sawblade is used we unstick it from anything it might be attached to.
]]--
function ITEM:OnUse( pl )
	if self:IsStuck() then
		self:UnstickSound();
		self:Unstick( pl );
		return true;
	end
	return self:BaseEvent( "OnUse", false, pl );
end

--[[
* SERVER
* Event

Unstick without sounds when we leave the world
]]--
function ITEM:OnExitWorld( bForced )
	self:Unstick();
	self:ClearPhysHoldPlayers();
	return self:BaseEvent( "OnExitWorld", nil, bForced );
end

--[[
* SERVER

Punting the sawblade with the gravity gun gives the player who punted it kill credits for a short amount of time.
]]--
function ITEM:OnGravGunPunt( pl, eEntity )
	--We only give kill credits if the sawblade wasn't being held (kill credits will be given by GravGunDrop if it was punted while being held)
	local plPhysHold = self:GetPhysHoldPlayer();
	if !plPhysHold then
		self:SetKillCredit( pl, self.KillCreditTime );
	end

	return self:BaseEvent( "OnGravGunPunt", nil, pl, eEntity );
end

--[[
* SERVER

Picking up the sawblade adds the player from the holding players list
]]--
function ITEM:OnGravGunPickup( pl, eEntity )
	self:AddPhysHoldPlayer( pl );
	return self:BaseEvent( "OnGravGunPickup", nil, pl, eEntity );
end

--[[
* SERVER
* Event

Dropping the sawblade removes the player from the holding players list
]]--
function ITEM:OnGravGunDrop( pl, eEntity )
	self:RemovePhysHoldPlayer( pl );
	return self:BaseEvent( "OnGravGunDrop", nil, pl, eEntity );
end

--[[
* SERVER
* Event

Picking up the sawblade adds the player from the holding players list
]]--
function ITEM:OnPhysgunPickup( pl, eEntity )
	self:AddPhysHoldPlayer( pl );
	return self:BaseEvent( "OnPhysgunPickup", nil, pl, eEntity );
end

--[[
* SERVER
* Event

Dropping the sawblade removes the player from the holding players list
]]--
function ITEM:OnPhysgunDrop( pl, eEntity )
	self:RemovePhysHoldPlayer( pl );
	return self:BaseEvent( "OnPhysgunDrop", nil, pl, eEntity );
end

--[[
* SERVER
* Event

We use this function for the sawblade's awesome stick-in stuff.
If the sawblade is going fast enough, and hits something head on, we can stick in it.

We can determine if it hit "head on" like so:
Lets say that...

A sawblade, broad side facing directly up...   ...Collides with a surface facing this way
 ^                                
 |                                             |
(o)              ~~~~WOOSH~~~~>             <--|
                                               |

Compare the sawblade facing angle and wall angle:
    ^
    |  90 degrees
 <--o

If angle falls between 45 degrees and 135 degrees it means the saw blade hit the surface "Head On", so it can stick/kill things/whatever.
]]--
function ITEM:OnPhysicsCollide( eEntity, CollisionData, HitPhysObj )
	if ( CollisionData.Speed < self.StickSpeed ) then return false end

	--TODO use v[2]:DispatchTraceAttack( CTakeDamageInfo Damage, Vector vStartPos, Vector vEndPos )

	--We only damage or stick in things we hit head on
	local vHitDir = CollisionData.HitNormal;
	local fDotMeasure = ( eEntity:GetUp() ):Dot( vHitDir );
	if fDotMeasure > self.MinAngleCos || fDotMeasure < self.MaxAngleCos then return false end
	
	local eEntity2 = CollisionData.HitEntity;
	local eKillCredit = self:GetKillCredit() or eEntity;

	local iBloodType = self.BloodyTypes[eEntity2:GetClass()];

	--Kill (or at least really mess up) players and NPCs
	if iBloodType then
		eEntity2:TakeDamage( 100, eKillCredit, eEntity );
		self:EmitSound( self.FleshyImpactSounds );
		
		local effectdata = EffectData();
		effectdata:SetOrigin( eEntity:GetPos() );
		effectdata:SetEntity( eEntity );
		effectdata:SetAngle( ( CollisionData.HitPos - eEntity:GetPos() ):Angle() );
		effectdata:SetAttachment( iBloodType );
		util.Effect( "BladeBlood", effectdata, true, true );
		
		--Sawblades have a habit of bouncing off stuff when they should pass through it
		local phys = eEntity:GetPhysicsObject();
		if phys:IsValid() then		phys:SetVelocity( CollisionData.OurOldVelocity );	end
		
	--Otherwise, stick in whatever we hit (TODO: We should both bloody w/sound and stick into ragdolls... getting blood color may be troublesome; perhaps use models rather than classnames in hash table; assume red if not available? )
	else
		eEntity:SetPos( CollisionData.HitPos + ( vHitDir * -self.StickBy ) );
		
		if eEntity2:IsWorld() then
			local phys = eEntity:GetPhysicsObject();
			if phys:IsValid() then	phys:EnableMotion( false );	end
			self:EmitSound( self:Event( "GetStickSound", nil, ent ) );
		else
			--Whatever we hit takes a little bit of damage. We /did/ just cut into it, right?
			eEntity2:TakeDamage( self:Event( "GetStickDamage", 10, eEntity2 ), eKillCredit, eEntity );
			if !eEntity2:IsValid() then return end


			--If we hit something with a physics object, we can weld to it
			local phys2 = CollisionData.HitObject;
			if phys2:IsValid() then
				
				--But first we have to determine which physics object we hit on the entity (in case of ragdolls)
				local iHitBone = 0;
				for i = 0, eEntity2:GetPhysicsObjectCount() - 1 do
					if eEntity2:GetPhysicsObjectNum( i ) == phys2 then iHitBone = i; break; end
				end
				
				--Have to use a timer because according to garry's error message initing a constraint in a physics hook can cause crashes?
				--TODO: WorldToLocalAngles could probably be improved upon somehow to work with individual physics objects
				self:SimpleTimer( 0, self.StickTo, eEntity2, iHitBone, self.StickStrength, phys2:WorldToLocal( eEntity:GetPos() ), eEntity2:WorldToLocalAngles( eEntity:GetAngles() ) );
			end
		end
	end
end

--[[
* SERVER

Adds the given player to the back of the PhysHoldPlayers list.
If the given player is already in the list, moves him to the back of the list.

If the list was empty, sets the sawblade's kill-credits to this player.

plNewHolder should be the player to add.
]]--
function ITEM:AddPhysHoldPlayer( plNewHolder )
	if !self.PhysHoldPlayers then self.PhysHoldPlayers = {} end
	self:RemovePhysHoldPlayer( plNewHolder );

	if self.PhysHoldPlayers[1] == nil then self:SetKillCredit( plNewHolder ) end
	table.insert( self.PhysHoldPlayers, plNewHolder );
end

--[[
* SERVER

Removes the given player from the PhysHoldPlayers list (if he is in there).

If the player at the front of the list was removed, transfers the kill-credits to the player beneath him.
However, if there more players remaining, sets an expiration timer on the kill-credits formerly held by that player.

plOldHolder should be the player to remove.

Returns false if the player was not in the list.
Returns true if the player was removed.
]]--
function ITEM:RemovePhysHoldPlayer( plOldHolder )
	if !self.PhysHoldPlayers then return false end

	for i = 1, #self.PhysHoldPlayers do
		if self.PhysHoldPlayers[i] == plOldHolder then
			table.remove( self.PhysHoldPlayers, i );

			if i == 1 then
				if self.PhysHoldPlayers[1] == nil then		self:SetKillCredit( plOldHolder, self.KillCreditTime );
				else										self:SetKillCredit( self.PhysHoldPlayers[1] );
				end
			end

			return true;
		end
	end

	return false;
end

--[[
* SERVER

Returns the first player in the PhysHoldPlayers list.
Returns nil if there are no PhysHoldPlayers.
]]--
function ITEM:GetPhysHoldPlayer()
	if !self.PhysHoldPlayers then return nil end
	return self.PhysHoldPlayers[1];
end

--[[
* SERVER

Clears the PhysHoldPlayers list.
]]--
function ITEM:ClearPhysHoldPlayers()
	self.PhysHoldPlayers = nil;
end

--[[
* SERVER
* Event

Should return true if the sawblade can stick to something, false otherwise.
By default, the sawblade ignores dangling rope ends.
]]--
function ITEM:CanStickTo( ent, bone, str, wpos, wang, lpos, lang )
	return ( ent:GetClass() != IF.Util:GetRopeEndClass() );
end

--[[
* SERVER

Welds the item to an entity and stores the weld in the item's "StickingTo" table.

ent is the entity to weld to.
bone is the physics bone number to weld to.
str is the strength of the weld (0 for unbreakable; except by Unstick() of course)
lpos is the position of the sawblade relative to the physics object.
lang is the rotation of the sawblade relative to the physics object.
]]--
function ITEM:StickTo( ent, bone, str, lpos, lang )
	local eEnt = self:GetEntity();
	if !eEnt || !ent || !ent:IsValid() then return false end
	
	local phys = ent:GetPhysicsObjectNum( bone );
	if !phys:IsValid() then return false end
	
	local wpos = phys:LocalToWorld( lpos );
	local wang = ent:LocalToWorldAngles( lang )

	if !self:Event( "CanStickTo", false, ent, bone, str, wpos, wang, lpos, lang ) then return false end

	--Create the "Sticking To" table if it hasn't been created yet
	if !self.StickingTo then self.StickingTo = {} end
	
	--Since the sawblade or what it was sticking to might have moved we set it's updated pos/ang here
	eEnt:SetPos( wpos );
	eEnt:SetAngles( wang );
	
	--Weld to what we want, fail if we couldn't
	local weld = constraint.Weld( eEnt, ent, 0, bone, str, true );
	if !weld || !weld:IsValid() then return false end
	
	--Add the weld
	local id = table.insert( self.StickingTo, { weld, ent } );
	weld:CallOnRemove( self.WeldRemoveEventName, self.Unstuck, self, id );
	
	--Stick sound
	self:EmitSound( self:Event( "GetStickSound", nil, ent ) );

	return true;
end

--[[
* SERVER
* Event

Called when the sawblade sticks into an entity.
Should return the damage to apply to the entity.

eEntityStuck is the entity the sawblade stuck into.
]]--
function ITEM:GetStickDamage( eEntityStuck )
	return self.StickDamage;
end

--[[
* SERVER

This event determines what sound should be played when the sawblade sticks into the given entity.
If it returns:
	nil or an empty table:				no sound is played
	a Sound( "filepath.wav" ):			that sound is played
	a table of Sound( "filepath.wav" ):	a random sound from that table is played
]]--
function ITEM:GetStickSound( eEntityStuck )
	return self.StickSounds;
end

--[[
* SERVER

Returns true if the sawblade has stuck to something with self:StickTo()
This doesn't count for things like toolgun welds.

eTo is an optional entity.
	If eTo is given, then we'll only return true if the sawblade is stuck to THAT entity.
Otherwise, true is returned as long as the sawblade is stuck to something.
false is returned in all other cases.
]]--
function ITEM:IsStuck( eTo )
	if !self.StickingTo then return false end
	if eTo == nil then
		for k, v in pairs( self.StickingTo ) do
			if v[1]:IsValid() then return true end
		end
	else
		for k, v in pairs( self.StickingTo ) do
			if v[1]:IsValid() && v[1] == eTo then return true end
		end
	end
	
	return false;
end

--[[
* SERVER

Unwelds the sawblade from something it was stuck to with StickTo.

plDamageCredit is an optional player.
	If plDamageCredit is given, any damage the sawblade does to an object from being unstuck will be credited to this player.
eFrom is an optional entity.
	If eFrom is given, the sawblade is only unstuck from that entity.
	Otherwise, the sawblade is unstuck from everything it is attached to.
]]--
function ITEM:Unstick( plDamageCredit, eFrom )
	if !self.StickingTo then return true end

	--TODO use v[2]:DispatchTraceAttack( CTakeDamageInfo Damage, Vector vStartPos, Vector vEndPos )

	local eEnt = self:GetEntity();
	if plDamageCredit == nil then plDamageCredit = eEnt end
	
	if eFrom == nil then
		for k, v in pairs( self.StickingTo ) do
			if v[1]:IsValid() then
				v[1]:RemoveCallOnRemove( self.WeldRemoveEventName );
				v[1]:Remove();
			end
			if v[2]:IsValid() then
				v[2]:TakeDamage( self:Event( "GetUnstickDamage", 10, v[2] ), plDamageCredit, eEnt );
			end
		end
		self.StickingTo = nil;
		return true;
	else
		for k, v in pairs( self.StickingTo ) do
			if v[2] == eFrom then
				if v[1]:IsValid() then
					v[1]:RemoveCallOnRemove( self.WeldRemoveEventName );
					v[1]:Remove();
				end
				if v[2]:IsValid() then
					v[2]:TakeDamage( self:Event( "GetUnstickDamage", 10, v[2] ), plDamageCredit, eEnt );
				end

				self.StickingTo[k] = nil;
				return true;
			end
		end
		return false;
	end
	
end

--[[
* SERVER
* Event

Called when the sawblade is unstuck from an entity.
Should return the damage to apply to the entity.

eEntityUnstuck is the entity the sawblade was unstuck from.
]]--
function ITEM:GetUnstickDamage( eEntityUnstuck )
	return self.UnstickDamage;
end

--[[
* SERVER

Play the unstick sound on this item
]]--
function ITEM:UnstickSound()
	self:EmitSound( self.UnstickSounds );
end

--[[
* SERVER

This function is called when the sawblade is pulled out of one of the things it's stuck in by force.
This function is written strangely for technical reasons.

weld is the weld entity that was broken (this was holding the sawblade and whatever it was stuck in together)
self is this item.
id is where the sawblade recorded weld in self.StickingTo.
]]--
function ITEM.Unstuck( weld, self, id )
	if !self:IsValid() then return end

	self:UnstickSound();
	local ent = self:GetEntity();
	self.StickingTo[id][2]:TakeDamage( 10, ent, ent );
	self.StickingTo[id] = nil;
end




else




--[[
* CLIENT
* Event

The sawblade icon moves in an elliptical way on the weapons menu
]]--
function ITEM:OnSWEPDrawMenu( fX, fY, fW, fH, fA )
	local t = 10 * RealTime();
	self:DrawIcon( fX + 0.5 * ( fW - 128 ) + 16 * math.cos( t ),
				   fY + 0.5 * ( fH - 128 ) + 8  * math.sin( t ),
				   128, 128,
				   fA );
end

--[[
* CLIENT

Begins orienting the model to horizontal
]]--
function ITEM:OrientHorizontal()
	if self.ViewModelOrientation == ORIENT_HORIZ || self.ViewModelOrientation == ORIENT_VTOH then return true end
	self.ViewModelOrientation = ORIENT_VTOH;
	self.ViewModelInterpFromTime = CurTime();
	self.ViewModelInterpToTime = self.ViewModelInterpFromTime + self.ViewModelInterpDelay;
end

--[[
* CLIENT

Begins orienting the model to vertical
]]--
function ITEM:OrientVertical()
	if self.ViewModelOrientation == ORIENT_VERT || self.ViewModelOrientation == ORIENT_HTOV then return true end
	self.ViewModelOrientation = ORIENT_HTOV;
	self.ViewModelInterpFromTime = CurTime();
	self.ViewModelInterpToTime = self.ViewModelInterpFromTime + self.ViewModelInterpDelay;
end

--[[
* CLIENT
* Event

The sawblade's viewmodel can be rotated horizontally or vertically,
and transitions smoothly between the two
]]--
function ITEM:GetSWEPViewModelPosition( oldPos, oldAng )
	--This is good but needs some smoothing and optimizing
	local pl = self:GetWOwner();
	local tr = {};
	tr.filter = pl;
	tr.start  = pl:GetShootPos();
	tr.endpos = tr.start + 30 * pl:GetAimVector();
	tr.mins	  = Vector( -8, -8, -8 );
	tr.maxs	  = Vector(  8,  8,  8 );
	local traceRes = util.TraceHull( tr );

	if traceRes.Hit then
		local fr = ( 1 - traceRes.Fraction );
		oldPos = oldPos + fr * ( 10 * oldAng:Forward() - 45 * oldAng:Up() );
		oldAng = Angle( oldAng.p - fr * 90, oldAng.y, oldAng.r );
	end

	local fInterp = 0;
	if self.ViewModelOrientation == ORIENT_HTOV then
		if CurTime() > self.ViewModelInterpToTime		then	self.ViewModelOrientation = ORIENT_VERT;
		else													fInterp = IF.Util:CosInterpolate( 0, 1, self.ViewModelInterpFromTime, self.ViewModelInterpToTime, CurTime() );
		end
	elseif self.ViewModelOrientation == ORIENT_VTOH		then
		if CurTime() > self.ViewModelInterpToTime		then	self.ViewModelOrientation = ORIENT_HORIZ;
		else													fInterp = IF.Util:CosInterpolate( 1, 0, self.ViewModelInterpFromTime, self.ViewModelInterpToTime, CurTime() );
		end
	end
	
	if		self.ViewModelOrientation == ORIENT_HORIZ	then	return oldPos, oldAng;
	elseif	self.ViewModelOrientation == ORIENT_VERT	then	return oldPos + self.ViewModelVerticalShift				  * oldAng:Right() , Angle( oldAng.p, oldAng.y, oldAng.r + self.ViewModelVerticalRoll );
	else														return oldPos + ( self.ViewModelVerticalShift * fInterp ) * oldAng:Right() , Angle( oldAng.p, oldAng.y, oldAng.r + self.ViewModelVerticalRoll * fInterp );
	end
end




end