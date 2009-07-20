--[[
itemforge_item_held_1
SHARED

This SWEP is an 'avatar' of an item. When an item is held, this weapon represents that item.
]]--
include("makecopy.lua");

SWEP.Author			= "theJ89"
SWEP.Contact		= "theJ89@charter.net"
SWEP.Purpose		= "This SWEP is a part of Itemforge. When an item is held, this weapon turns into the item you're holding."
SWEP.Instructions	= "This will be spawned by the game when an item is held by a player. You can interact with the item by switching to this weapon then using left mouse, right mouse, etc."

SWEP.Spawnable = false;
SWEP.AdminSpawnable = false;

SWEP.ViewModel		= "models/weapons/v_pistol.mdl";
SWEP.WorldModel		= "models/weapons/w_pistol.mdl";

SWEP.Primary.ClipSize		= 0;
SWEP.Primary.DefaultClip	= 0;
SWEP.Primary.Automatic		= false;
SWEP.Primary.Ammo			= "none";

SWEP.Secondary.ClipSize		= 0;
SWEP.Secondary.DefaultClip	= 0;
SWEP.Secondary.Automatic	= false;
SWEP.Secondary.Ammo			= "none";

--May change
SWEP.ViewModelFOV	= 62;
SWEP.ViewModelFlip	= false;

SWEP.BeingRemoved=false;

--Set item this is associated with
function SWEP:SetItem(item)
	if self.BeingRemoved || !item then return false end
	self.Item=item;
	
	--Initialize the SWEP - take care of some basic things like setting the world+view models, whether or not the weapon is automatic, setting the display name, etc
	item:Event("OnSWEPInit",nil,self,self.Weapon);
	
	if SERVER then
		--Inform this entity what item ID to look for when pairing clientside
		self.Weapon:SetNWInt("i",item:GetID());
		
		--And finally, spawn it
		self.Weapon:Spawn();
	else
		item:Hold(self.Owner,nil,self.Weapon,false);
	end
	return true;
end

--Is the entity being removed right now?
function SWEP:IsBeingRemoved()
	return self.BeingRemoved;
end


--[[
Returns the item that is piloting this SWEP.
If the item has been removed, then nil is returned and self.Item is set to nil.
]]--
function SWEP:GetItem()
	if !self.Item then	
		if CLIENT && self:HasOwner() && !self:IsBeingRemoved() && !self:SetItem(IF.Items:Get(self.Weapon:GetNWInt("i"))) then
			return nil;
		end
	elseif !self.Item:IsValid() then
		self.Item=nil;
	end
	return self.Item;
end


--Returns true if the SWEP has a valid owner, false otherwise
--If the item hasn't been picked up yet this is nil
function SWEP:HasOwner()
	if self.Owner && self.Owner:IsValid() then return true; end
	return false;
end

function SWEP:Initialize()
end


--Do we need to precache anything?
function SWEP:Precache()
end


--Reroute to item's OnPrimaryAttack
function SWEP:PrimaryAttack()
	local item=self:GetItem();
	if !item then return false; end
	
	return item:Event("OnPrimaryAttack");
end

--Reroute to item's OnSecondaryAttack
function SWEP:SecondaryAttack()
	local item=self:GetItem();
	if !item then return false; end
	
	return item:Event("OnSecondaryAttack");
end

--?? Can reload?
function SWEP:CheckReload()
	
end

--Being reloaded
--TODO: This has no way to know if the weapon is done reloading since we don't do DefaultReload like most SWEPs do; need to figure out a solution for this
function SWEP:Reload()
	local item=self:GetItem();
	if !item then return false; end
	
	return item:Event("OnReload");
end

--May allow items to override later
function SWEP:ContextScreenClick( aimvec, mousecode, pressed, ply )
end

function SWEP:OwnerChanged()
	local item=self:GetItem();
	if !item then return false; end
	
	--DEBUG
	Msg("Itemforge Item SWEP: "..tostring(item).." changed owner to "..tostring(self.Owner).."\n");
	item:SetWOwner(self.Owner);
end

--This doesn't work for any weapon due to some bug related to the Orange Box I suspect; but if it did, we don't want the weapon to drop, we want to get rid of the weapon and send the item to world.
function SWEP:ShouldDropOnDie()
	return false;
end

--Is the entity being removed right now?
function ENT:IsBeingRemoved()
	return self.BeingRemoved;
end