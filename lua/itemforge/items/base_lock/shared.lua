--[[
base_lock
SHARED

base_lock is a base. That means that other items borrow code from this so they can be created easier.
Any item that inherits from this has everything this item has, and can override anything this item has.

The base_lock's purpose is to provide a variety of functions that all locks use, including (but not limited to):
	Attaching to and detaching from items and entities
	Locking and unlocking attached items and entities
	
Attention! Locks can be attached to other items, but the items the locks attach to must have these functions serverside:
	ITEM:OnAttachLock(item) - Having this function in your item allows locks to be attached. Runs when after a lock has been attached (this will be item).
	ITEM:OnDetachLock(item) - This function runs when the lock is removed
	ITEM:Lock() - This should lock your item.
	ITEM:Unlock() - This should unlock your item.
	ITEM:IsLocked() - Returns true if the item is locked, false if it isn't (I personally recommend making this a shared function if you can)
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name				= "Base Lock";
ITEM.Description		= "This item is the base lock.\nThis item contains common functionality used by all locks.\n\nThis is not supposed to be spawned.";
ITEM.WorldModel			= "models/props_combine/combine_lock01.mdl";
ITEM.ViewModel			= "models/Weapons/v_crossbow.mdl";
ITEM.SWEPHoldType		= "slam";

ITEM.MaxHealth			= 300;

--We don't want players spawning it.
ITEM.Spawnable			= false;
ITEM.AdminSpawnable		= false;

--Base Lock
ITEM.AttachRange		= 128;
ITEM.CanAttachSound		= Sound("ambient/energy/weld1.wav");
ITEM.CantAttachSound	= Sound("weapons/physcannon/physcannon_charge.wav");
ITEM.AttachSound		= Sound("weapons/physcannon/superphys_small_zap3.wav");

if SERVER then
	ITEM.InitWithoutPhysics = false;
	ITEM.CollisionBoundsMin = Vector( 0, -3, -5.5 );
	ITEM.CollisionBoundsMax = Vector( 3,  3,  5.5 );
end

local DoorTypes = {
	["prop_door_rotating"]	= true,
	["func_door"]			= true,
	["func_door_rotating"]	= true,
};

--[[
* SHARED

Returns the attached entity, or nil if the lock is not attached to an entity.
]]--
function ITEM:GetAttachedEnt()
	return self:GetNWEntity( "AttachedEnt" );
end

--[[
* SHARED

Returns the attached item, or nil if the lock is not attached to an item.
]]--
function ITEM:GetAttachedItem()
	return self:GetNWItem( "AttachedItem" );
end

--[[
* SHARED

Returns true if the lock is attached to something or false otherwise.
]]--
function ITEM:IsAttached()
	return ( self:GetAttachedEnt() or self:GetAttachedItem() ) != nil;
end

--[[
* SHARED

Returns true depending on if the ent/item this lock is attached to is locked.

Technically, the way the lock items are set up, they are simply mechanisms for controlling
existing locks in doors/items; in other words, locks do not lock individually.
]]--
function ITEM:IsAttachmentLocked()
	local ent	= self:GetAttachedEnt();
	local item	= self:GetAttachedItem();
	if ent then			return ( ent.ItemforgeLocked == true );
	elseif item then	return item:Event( "IsLocked", false );
	end
end
	
--[[
* SHARED

Runs when the player attempts to detach this from whatever it's attached to.

If this is run serverside, the item is detached from whatever it's attached from.
If this is run clientside, the client requests the server to run this function.

Nothing happens in either case if the given player can't interact with the item.

TODO needs to be able to detach from other things, not just doors
]]--
function ITEM:PlayerDetach( pl )
	if !self:Event( "CanPlayerInteract", false, pl ) then return false end
	
	if SERVER then	self:DetachFromEnt(); self:DetachFromItem();
	else			self:SendNWCommand( "PlayerDetach" );
	end
end

--[[
* SHARED
* Event

Returns the position of the item this lock is attached to.
(while the lock is attached to another item it is in the void)
]]--
function ITEM:GetVoidPos()
	local i = self:GetAttachedItem();
	if i then return i:GetPos() end
end

--[[
* SHARED
* Event

The item can't exit the world while it's attached to an entity,
in addition to any other case that it can't exit.
]]--
function ITEM:CanExitWorld( ent )
	return ( self:GetAttachedEnt() == nil && self:BaseEvent( "CanExitWorld", false, ent ) );
end

--[[
* SHARED
* Event

The lock can't be held if it's currently attached to something.
]]--
function ITEM:CanHold( pl )
	return !self:IsAttached() && self:BaseEvent( "CanHold", false, pl );
end

--[[
* SHARED
* Event

The lock can't be placed somewhere in the world if it's currently attached to something.
]]--
function ITEM:CanEnterWorld( vPos, aAng, bTeleport )
	return !self:IsAttached() && self:BaseEvent( "CanEnterWorld", false, vPos, aAng, bTeleport );
end

--[[
* SHARED
* Event

Returns true if the lock can attach to the given entity
]]--
function ITEM:CanAttachToEnt( ent )
	return DoorTypes[ent:GetClass()] == true;
end




if SERVER then




--[[
* SERVER
* Event

This is the entity init function with some simple adjustments.
No physics are initialized if the item says they shouldn't be (in the case that we are in the process of attaching)
]]--
function ITEM:OnEntityInit( entity )
	entity:SetModel( self:Event( "GetWorldModel" ) );
	
	if !self.InitWithoutPhysics then
		entity:PhysicsInit( SOLID_VPHYSICS );
		local phys = entity:GetPhysicsObject();
		if ( phys:IsValid() ) then
			phys:Wake();
		end
	else
		--We don't have a physics model so we need to set collision bounds
		entity:SetCollisionBounds( self.CollisionBoundsMin, self.CollisionBoundsMax );
		
		--Interestingly enough, we can use SOLID_VPHYSICS for an OBB even if we don't have physics!
		entity:SetSolid( SOLID_VPHYSICS );
		entity:SetCollisionGroup( COLLISION_GROUP_NONE );
		
		--We don't want to draw shadows while we're on the wall
		entity:DrawShadow( false );
	end
	
	--We'll do some other stuff like set it to simple use here
	entity:SetUseType( SIMPLE_USE );
	
	return true;
end

--[[
* SHARED
* Event

The player cannot pick up the lock with the physgun if it's attached to something.
]]--
function ITEM:CanPhysgunPickup( pl, eEntity )
	return !self:IsAttached();
end

--[[
* SERVER
* Event

When the item exits the world it detaches from whatever it was attached to.
This takes care of any lingering relationships between the lock and it's attached object.
]]--
function ITEM:OnExitWorld( bForced )
	if self:GetAttachedEnt() then self:Detach(); end
end

--[[
* SERVER
* Event

When the lock is used it tries to attach to a nearby object.
If it's already attached then it just tries to lock/unlock the attachment.
]]--
function ITEM:OnUse( pl )
	if self:GetAttachedEnt() || self:GetAttachedItem() then
		if self:IsAttachmentLocked() then	self:Event( "UnlockAttachment" );
		else								self:Event( "LockAttachment" );
		end
	else
		self:WorldAttach();
	end
	return true;
end

--[[
* SERVER

In-world attachment behavior. The item tries to find something to attach itself to.
]]--
function ITEM:WorldAttach()
	if !self:InWorld() || self.InitWithoutPhysics then return false end
	
	local ent = self:GetEntity();
	
	--Lets find something to attach to
	local tr  = {};
	tr.start  = ent:GetPos();
	tr.endpos = tr.start + ( self.AttachRange * ( -1 * ent:GetForward() ) );
	tr.filter = ent;
	local traceRes = util.TraceLine( tr );
	
	if traceRes.Hit && IsValid( traceRes.Entity ) then
		local item = IF.Items:GetEntItem( traceRes.Entity );
		if item && IF.Util:IsFunction( item.OnAttachLock ) && item:Event( "OnAttachLock", false, self ) then
			self:SetNWItem( "AttachedItem", item );
			self:EmitSound( self.CanAttachSound );
			return true;
		elseif self:Event( "CanAttachToEnt", false, traceRes.Entity ) then
			local vPos, aAng = ent:GetPos(), ent:GetAngles();
			
			--We remove the item's current world entity, and then send it back to the world without physics
			if !self:ToVoid() then return false end
			self.InitWithoutPhysics = true;
			ent = self:ToWorld( vPos, aAng );
			
			--[[
			This plays the Lock Weld effect, which lasts about half a second.
			This effect animates the lock into position clientside.
			Once it finishes playing, the lock item's position, angles, parent entity, etc are finalized in a seperate function (hence the half-second timer beneath the effect)
			]]--
			local effectdata = EffectData();
			effectdata:SetOrigin( traceRes.HitPos );
			effectdata:SetAngle( traceRes.HitNormal:Angle() );
			effectdata:SetEntity( ent );
			util.Effect( "LockWeld", effectdata, true, true );
			self:SimpleTimer( 0.5, self.AttachTo, traceRes.Entity, traceRes.Entity:WorldToLocal( traceRes.HitPos ), traceRes.Entity:WorldToLocalAngles( traceRes.HitNormal:Angle() ) );
			
			self:EmitSound( self.CanAttachSound );
			return true;
		end
	end
	
	self:EmitSound( self.CantAttachSound );
end

--[[
* SERVER

Instantly teleports the item and parents it to the given ent.
The given ent is recorded as our attached ent.

entAttach is the entity to attach the lock to.
vLocalPos is the position relative to the attach entity that the lock will be positioned at.
angLocalAng are the angles relative to the attach entity that the lock will be rotated by.
]]--
function ITEM:AttachTo( entAttach, vLocalPos, angLocalAng )
	--Teleport the ent to the correct position
	local ent = self:ToWorld( entAttach:LocalToWorld( vLocalPos ), entAttach:LocalToWorldAngles( angLocalAng ) );
	ent:SetParent( entAttach );
	ent:SetOwner( entAttach );
	
	self:EmitSound( self.AttachSound );
	self:SetNWEntity( "AttachedEnt", entAttach );
end

--[[
* SERVER

Clears any attachments
]]--
function ITEM:Detach()
	self:Event( "UnlockAttachment" );
	
	self:SetNWEntity( "AttachedEnt", nil );
	self:SetNWItem( "AttachedItem", nil );
end

--[[
* SERVER

If attached to an entity, causes it to fall off
]]--
function ITEM:DetachFromEnt()
	if self:IsAttachmentLocked() || !self:GetAttachedEnt() then return false end
	
	local ent = self:GetEntity();
	local pos, ang = ent:GetPos(), ent:GetAngles();
	
	--First, the connection is cleared. Then we respawn the entity at it's old position/angles, but with physics this time
	self:Detach();
	self:ToVoid();
	self.InitWithoutPhysics = false;
	self:ToWorld( pos, ang );
	
	return true;
end

--[[
* SERVER

If attached to an item, causes it to fall off.
]]--
function ITEM:DetachFromItem()
	local item = self:GetAttachedItem();
	if !item || self:IsAttachmentLocked() then return false end
	
	item:Event( "OnDetachLock", nil, self );
	self:Detach();
	self.InitWithoutPhysics = false;
	self:ToSameLocationAs( item );
	
	return true;
end

--[[
* SERVER
* Event

Locks the attached entity/item
]]--
function ITEM:LockAttachment()
	local ent = self:GetAttachedEnt();
	local item = self:GetAttachedItem();
	if ent then
		ent:Fire( "Lock", "", 0 );
		ent.ItemforgeLocked = true;
	elseif item then
		item:Event( "Lock", nil, self );
	else
		return false;
	end
	return true;
end

--[[
* SERVER
* Event

Unlocks the attached entity/item
]]--
function ITEM:UnlockAttachment()
	local ent = self:GetAttachedEnt();
	local item = self:GetAttachedItem();
	
	--TODO: If multiple locks are attached, we need to make sure it's unlocked only when removing the final lock
	if ent then
		ent:Fire( "Unlock", "", 0 );
		ent.ItemforgeLocked = false;
	elseif item then
		item:Event( "Unlock", nil, self );
	else
		return false;
	end
	return true;
end

--[[
* SERVER
* Event

When the lock is removed it is detached from whatever it was attached to
]]--
function ITEM:OnRemove()
	self:Detach();
end

IF.Items:CreateNWCommand( ITEM, "PlayerDetach", function(self,...) self:PlayerDetach(...) end );




else




--[[
* CLIENT
* Event

Locks have a lock/unlock and detach option when they're attached to something
]]--
function ITEM:OnPopulateMenu( pnlMenu )
	self:BaseEvent( "OnPopulateMenu", nil, pnlMenu );
	if self:GetAttachedEnt() || self:GetAttachedItem() then
		if self:IsAttachmentLocked() then	pnlMenu:AddOption( "Unlock",	function(pnl) self:PlayerUnlock( LocalPlayer() ) end )
		else								pnlMenu:AddOption( "Lock",		function(pnl) self:PlayerLock( LocalPlayer() ) end )
		end

		pnlMenu:AddOption( "Detach", function(pnl) self:PlayerDetach( LocalPlayer() ) end );
	end
end

IF.Items:CreateNWCommand( ITEM, "PlayerDetach" );




end

IF.Items:CreateNWVar( ITEM, "AttachedEnt", "entity" );
IF.Items:CreateNWVar( ITEM, "AttachedItem", "item" );