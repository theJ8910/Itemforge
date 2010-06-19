--[[
rope_end
SHARED

Two of these entities are created when a rope is cut in half.
They're invisible weights the ropes are attached to that allow the rope ends to dangle.

Using a rope end lets you pick up the rope.
]]--
ENT.Type 			= "anim";
ENT.Base 			= "base_anim";

ENT.PrintName		= "Loose Rope";
ENT.Author			= "theJ89";
ENT.Contact			= "theJ89@charter.net";
ENT.Purpose			= "This entity allows rope ends to dangle loosely after they have been cut.";
ENT.Instructions	= "These will be spawned by the game automatically after a rope is cut.";

ENT.Spawnable			= false;
ENT.AdminSpawnable		= false;

if SERVER then

ENT.AssociatedRope	= nil;

else

language.Add("rope_end","Loose Rope");

end

if SERVER then

--[[
* SERVER
* Event

Initializes the rope-end as a basic 4x4x4 cube
]]--
function ENT:Initialize()
	self.Entity:SetModel("models/props_junk/cardboard_box004a.mdl");
	self.Entity:PhysicsInitBox(Vector(-2,-2,-2),Vector(2,2,2));
	self.Entity:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE);
	self.Entity:DrawShadow(false);
	
	if SERVER then self.Entity:SetUseType(SIMPLE_USE); end
	
	local phys = self.Entity:GetPhysicsObject();
	if (phys:IsValid()) then
		phys:SetMass(3);
		phys:Wake();
	end
end

--[[
* SERVER
* Event

Sets the rope (phys_lengthconstraint) that the rope-end is attached to.
If that phys_lengthconstraint gets removed then the rope end gets removed too.
]]--
function ENT:SetAssociatedRope(r)
	--If we're swapping to a different rope then we no longer want to be deleted automatically by the old rope
	if IsValid(self.AssociatedRope) then self.AssociatedRope:DontDeleteOnRemove(self.Entity) end
	
	self.AssociatedRope = r;
	r:DeleteOnRemove(self.Entity);
end

--[[
* SERVER
* Event

Returns the rope end's associated rope or clears it if it's no longer valid
]]--
function ENT:GetAssociatedRope()
	if self.AssociatedRope && !self.AssociatedRope:IsValid() then
		self.AssociatedRope=nil;
		return nil;
	end
	return self.AssociatedRope;
end

--[[
* SERVER
* Event

When this takes damage it gets knocked around like a normal physical object
]]--
function ENT:OnTakeDamage(dmg)
	self.Entity:TakePhysicsDamage(dmg);
end

--[[
* SERVER
* Event

When the rope ends are used, we try to pick up the rope as an item
]]--
function ENT:Use(activator,caller)
	--Have to be used by a player
	if !activator:IsPlayer() then return false end

	--Have to have a rope
	local rope=self:GetAssociatedRope();
	if !rope then return false end
	
	--Has to be a loose rope
	if !IsValid(rope.Ent1) || !IsValid(rope.Ent2) || rope.Ent1:GetClass() != "rope_end" || rope.Ent2:GetClass() != "rope_end" then return false end	
	
	--Create and initialize a rope item
	local item = IF.Items:CreateHeld("item_rope",activator);
	if !item then return false end
	item:SetRopeProperties(rope.length, rope.width, rope.material, rope.forcelimit, rope.rigid);
	
	--Remove the rope (which removes the rope ends as well)
	rope:Remove();
end


else


--[[
* CLIENT
* Event

Don't draw anything
]]--
function ENT:Draw()
	return true;
end


end