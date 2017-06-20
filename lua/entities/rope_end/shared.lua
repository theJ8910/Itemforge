--[[
rope_end
SHARED

Two of these entities are created when a rope is cut in half.
They're invisible weights the ropes are attached to that allow the rope ends to dangle.

Using a rope end lets you pick up the rope.
]]--

if CLIENT then language.Add( "rope_end", "Loose Rope" ) end

ENT.Type 				= "anim";
ENT.Base 				= "base_anim";

ENT.PrintName			= "Loose Rope";
ENT.Author				= "theJ89";
ENT.Contact				= "theJ89@charter.net";
ENT.Purpose				= "This entity allows rope ends to dangle loosely after they have been cut.";
ENT.Instructions		= "These will be spawned by the game automatically after a rope is cut.";

ENT.Spawnable			= false;
ENT.AdminSpawnable		= false;

if SERVER then




ENT.AssociatedRope		= nil;
ENT.ItemtypeToGive		= "item_rope";




end
local vBoxMins = Vector( -2, -2, -2 );
local vBoxMaxs = Vector(  2,  2,  2 );

if SERVER then

--[[
* SERVER
* Event

Initializes the rope-end as a basic 4x4x4 cube
]]--
function ENT:Initialize()
	self.Entity:SetModel( "models/props_junk/cardboard_box004a.mdl" );
	self.Entity:PhysicsInitBox( vBoxMins, vBoxMaxs );
	self.Entity:SetCollisionGroup( COLLISION_GROUP_WEAPON );
	self.Entity:DrawShadow( false );
	
	if SERVER then self.Entity:SetUseType( SIMPLE_USE ) end
	
	local phys = self.Entity:GetPhysicsObject();
	if ( phys:IsValid() ) then
		phys:SetMass( 3 );
		phys:Wake();
	end
end

--[[
* SERVER
* Event

Sets the rope (phys_lengthconstraint) that the rope-end is attached to.
If that phys_lengthconstraint gets removed then the rope end gets removed too.
]]--
function ENT:SetAssociatedRope( eLCRope )
	--If we're swapping to a different rope then we no longer want to be deleted automatically by the old rope
	if IsValid( self.AssociatedRope ) then self.AssociatedRope:DontDeleteOnRemove( self ) end
	
	self.AssociatedRope = eLCRope;
	eLCRope:DeleteOnRemove( self );
end

--[[
* SERVER
* Event

Returns the rope end's associated rope or clears it if it's no longer valid
]]--
function ENT:GetAssociatedRope()
	if self.AssociatedRope && !self.AssociatedRope:IsValid() then
		self.AssociatedRope = nil;
	end
	return self.AssociatedRope;
end

--[[
* SERVER
* Event

When this takes damage it gets knocked around like a normal physical object
]]--
function ENT:OnTakeDamage( dmg )
	self:TakePhysicsDamage( dmg );
end

--[[
* SERVER
* Event

When the rope ends are used, we try to pick up the rope as an item
]]--
function ENT:Use( eActivator, eCaller )
	--Have to be used by a player
	if !eActivator:IsPlayer() then return false end

	--Have to have a rope
	local eRope = self:GetAssociatedRope();
	if !eRope then return false end
	
	--Has to be a loose rope
	if !IsValid( eRope.Ent1 ) || !IsValid( eRope.Ent2 ) || eRope.Ent1:GetClass() != "rope_end" || eRope.Ent2:GetClass() != "rope_end" then return false end	
	
	--Create and initialize a rope item
	local item = IF.Items:CreateHeld( self.ItemtypeToGive, eActivator );
	if !item then return false end
	item:SetRopeProperties( eRope.length, eRope.width, eRope.material, eRope.forcelimit, eRope.rigid );
	
	--Remove the rope (which removes the rope ends as well)
	eRope:Remove();
end




else




--[[
* CLIENT
* Event

Don't draw anything
]]--
function ENT:Draw()
end




end