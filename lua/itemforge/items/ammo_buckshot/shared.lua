--[[
ammo_buckshot
SHARED

This is ammunition for the HL2 shotgun. Or, I guess, any 12 gauge shotgun.
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name				= "Buckshot";
ITEM.Description		= "This is 12 gauge buckshot.\nThese lead-shot filled shotgun shells are used for hunting large game.\nThis is also the primary type of ammo for combat shotguns.";
ITEM.Base				= "base_ammo_firearm";
ITEM.StartAmount		= 20;
ITEM.Size				= 4;
ITEM.Weight				= 32;			--I have a box of buckshot at home and estimated this value based on the weight of the box and the # of shells it contained.

ITEM.SWEPHoldType		= "slam";

if CLIENT then




ITEM.Icon				= Material( "itemforge/items/ammo_buckshot" );
ITEM.WorldModelNudge	= Vector( -2, -3, -4 );
ITEM.WorldModelRotate	= Angle( 0, 0, 0 );




end

--Overridden Base Firearm Ammo stuff
ITEM.BulletSounds		= Sound( "Weapon_Shotgun.Single" );

--Buckshot

--[[
Just to demonstrate what you can do with this system, the shotgun ammo has two world models!
When we have less than "TurnsBoxAt" shells, we use the single shotgun shell model (you know, the shell-ejection model)
When we have "TurnsBoxAt" shells or more, we use the box of shotgun shells model (like the item_buckshot entity)
]]--
ITEM.TurnsBoxAt			= 20;
ITEM.WorldModelSingle	= "models/weapons/Shotgun_shell.mdl";
ITEM.WorldModelBox		= "models/Items/BoxBuckshot.mdl";
ITEM.WorldModel			= ITEM.WorldModelBox;

if SERVER then




--When buckshot is using it's single-shell model, it plays one of these sounds on impact
ITEM.SingleShellImpactSounds = {
	Sound( "weapons/fx/tink/shotgun_shell1.wav" ),
	Sound( "weapons/fx/tink/shotgun_shell2.wav" ),
	Sound( "weapons/fx/tink/shotgun_shell3.wav" ),
}

ITEM.vShellBoxMin		= Vector( -3, -1, 0 );
ITEM.vShellBoxMax		= Vector( 3, 1, 2 );

local vZero				= Vector( 0, 0, 0 );
local aZero				= Angle( 0, 0, 0 );




end


if SERVER then




--[[
* SERVER
* Event

If we're using the shell model, we use a custom physics box.
If we're using the box of ammo model, we use it's physics.
]]--
function ITEM:OnEntityInit( eEntity )
	local wm = self:GetWorldModel();
	eEntity:SetModel( wm );
	
	if wm == self.WorldModelSingle then	eEntity:PhysicsInitBox( self.vShellBoxMin, self.vShellBoxMax ) --self:PhysicsInitCylinder( eEntity, 1, 6, 5, Vector( 0, 0, 1 ), Angle( 0, 0, 0 ) )
	else								eEntity:PhysicsInit( SOLID_VPHYSICS ); end
	
	local phys = eEntity:GetPhysicsObject();
	if ( phys:IsValid() ) then
		if wm == self.WorldModelSingle then phys:SetMass(1) end
		phys:Wake();
	end
	
	eEntity:SetUseType( SIMPLE_USE );
	
	return true;
end

--[[
* SERVER
* Event

Play shell impact sounds on collide.
CollisionData is information about the collision passed on from the entity's event.
HitPhysObj is the physics object belonging to this entity which collided.
]]--
function ITEM:OnPhysicsCollide( eEntity, CollisionData, HitPhysObj )
	if self:GetAmount() >= self.TurnsBoxAt then return false end

	if ( CollisionData.Speed > 20 && CollisionData.DeltaTime > 0.2 ) then
		self:EmitSound( self.SingleShellImpactSounds );
	end
end

--[[
* SERVER
* Event


]]--
function ITEM:OnSetNWVar( strName, vVal )
	if strName == "Amount" then
		if vVal >= self.TurnsBoxAt then			self:SetWorldModel( self.WorldModelBox );
		else									self:SetWorldModel( self.WorldModelSingle );
		end
	end
	
	return self:BaseEvent( "OnSetNWVar", nil, strName, vVal );
end

--[[
* SERVER

DOESN'T WORK - Gives me vphysics crap about infinite origins/infinite angles;
For that matter, I tried giving it a Mesh cube physics model and it wouldn't move... so who knows what the hell is going on...
I know that I generated the cylinder itself correctly; I looked at a wireframe version of it and it's polygons are laid out correctly,
so I'm guessing this is some problem on garry's end with mesh physics?

Gives the given entity a cylinder for a physics model.

entity is the entity to give a cylinder physics model.
fRadius is the radius of the cylinder, in standard game units.
fHeight is the height of the cylinder, in standard game units.
iSides is the number of sides the cylinder has; the lower this number is, the "rougher" the cylinder is; however this is also FASTER to compute (less lag).
vOffset is an optional amount to shift the physics model from the center of the entity. This should be a vector.
aOffset is an optional amount to rotate the physics model. This should be an angle.

Details about the cylinder generated:
	Orientation: If aOffset is nil or <0,0,0>, then when the entity's angles are set to <0,0,0> the cap of the cylinder is facing up.
	Positioning: If vOffset is nil or <0,0,0>, then the center of the cylinder is the center of the entity.
]]--
function ITEM:PhysicsInitCylinder( eEntity, fRadius, fHeight, iSides, vOffset, aOffset )
	if !eEntity || !eEntity:IsValid() then return self:Error( "Couldn't give entity physics cylinder; no entity given!\n" )																end
	if !fRadius						  then return self:Error( "Couldn't give entity physics cylinder; radius wasn't given!\n" )															end
	if !fHeight						  then return self:Error( "Couldn't give entity physics cylinder; height wasn't given!\n" )															end
	if !iSides						  then return self:Error( "Couldn't give entity physics cylinder; number of sides wasn't given!\n" )												end
	if iSides<3						  then return self:Error( "Couldn't give entity physics cylinder; cylinders need at least 3 sides. You gave "..tostring( iSides ).." sides.\n" )	end
	
	vOffset		= vOffset or vZero;
	aOffset		= aOffset or aZero;
	fHeight		= 0.5 * fHeight;
	local frac	= (2*math.pi) / iSides;
	local Fwd	=			aOffset:Forward();
	local Left	= -1 *		aOffset:Right();
	local Up	= fHeight * aOffset:Up();
	local Down	= -1 *		Up;
	
	local verts = {};
	for i = 0, iSides - 1 do
		local theta = frac * i;
		local oxy = vOffset + Fwd * math.cos(theta) + Left * math.sin(theta);	--oxy stands for "Offset, X, and Y"
		
		table.insert( verts, Vertex( oxy + Up ) );
		if i > 0 then
			local n = table.getn(verts);
			table.insert( verts, verts[n] );
			table.insert( verts, verts[n-1] );
			table.insert( verts, Vertex(oxy+Down) );
			
			--Generate cap segments
			if i > 1 then

				--Top cap
				table.insert( verts, verts[1] );
				table.insert( verts, verts[n-2] );
				table.insert( verts, verts[n] );
				
				--Bottom cap
				table.insert( verts, verts[2] );
				table.insert( verts, verts[n-1] );
				table.insert( verts, verts[n+3] );

			end
			
			table.insert( verts, verts[n] );
			table.insert( verts, verts[n+3] );
			
			--Connect last side
			if i == iSides - 1 then
				table.insert( verts, verts[1] );
				table.insert( verts, verts[1] );
				table.insert( verts, verts[n+3] );
				table.insert( verts, verts[2] );
			end
		else
			table.insert( verts, Vertex( oxy + Down ) );
		end
	end
	
	--DEBUG; draw wireframe version of physics model at center of map
	--Three verts is one polygon
	local c = Color( 255, 128, 0, 255 );
	for i = 1, table.getn( verts ), 3 do
		debugoverlay.Line( verts[i].pos	,  verts[i+1].pos, 60, c );
		debugoverlay.Line( verts[i+1].pos, verts[i+2].pos, 60, c );
		debugoverlay.Line( verts[i+2].pos, verts[i].pos,   60, c );
	end
	
	--Finally, apply to the entity
	eEntity:PhysicsFromMesh( verts );
end




else




--[[
* CLIENT
* Event

We force the buckshot to be posed upright.
]]--
function ITEM:OnPose3D( eEntity, pnlModelPanel )
	self:PoseUprightRotate( eEntity );
end




end
