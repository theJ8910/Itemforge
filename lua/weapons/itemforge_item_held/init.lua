--[[
itemforge_item_held
SERVER

This SWEP is an 'avatar' of an item. When an item is held, this weapon represents that item.
]]--
AddCSLuaFile( "cl_init.lua" );
AddCSLuaFile( "shared.lua" );

include( "shared.lua" );

SWEP.Weight				= 5;		--Decides whether we should switch from/to this (higher weight than player's active weapon will cause a swap)

SWEP.AutoSwitchTo		= true;		--Auto switch to if we pick it up
SWEP.AutoSwitchFrom		= false;	--Auto switch from if you pick up a better weapon

SWEP.ExpectRemoval		= false;


--[[
* SERVER

Entity is about to be deleted
]]--
function SWEP:ExpectedRemoval()
	if !self.ExpectRemoval then
		self.ExpectRemoval = true;
		self.Weapon:Remove();
	end
end

--[[
* SERVER
* Event

Input run on SWEP
]]--
function SWEP:AcceptInput( strName, eActivator, eCaller, data )
	return self:GetItem():Event( "OnInput", false, true, self.Weapon, strName, eActivator, eCaller, data ) == true;
end

--[[
* SERVER
* Event

Keyvalue is set on our SWEP
]]--
function SWEP:KeyValue( strKey, strValue )
	local item = self:GetItem();
	if !item then return end

	return item:Event( "OnKeyValue", nil, true, self.Weapon, strKey, strValue );
end

--[[
* SERVER
* Event

For NPCs, returns what they should try to do with it.
]]--
function SWEP:GetCapabilities()	
	return self:GetItem():Event( "GetSWEPCapabilities", 0 );
end

--[[
* SERVER
* Event

We need to remove the item this SWEP is associated with if the removal wasn't expected (like if you die while holding it)
Or not remove the item this entity was associated with if the removal was expected (like if the item was just being taken out of the your hands and dropped as an entity)
]]--
function SWEP:OnRemove()
	--This weapon is being removed.
	self.BeingRemoved = true;
	
	--HACK
	self:Unregister();
	self:UnregisterFailedPickup();

	--Clear the weapon's connection to the item (this weapon "forgets" the item)
	local item = self:GetItem();
	if !item then return end		--We didn't have an item set anyway. We can stop here.
	self:SetItem( nil );
	
	--[[
	Then we need to clear the one-way connection between the item and the entity.
	This is only necessary if Itemforge didn't remove this weapon; 
	That means the weapon has been removed some other way (player was killed or the weapon was stripped, for example).
	We drop the item in the world so it doesn't float in the void.
	We could also remove it, like we do with entities, but it makes more sense to drop it if it's just being carried.
	May change if it causes issues.
	]]--
	if !self.ExpectRemoval then
		--If ToVoid returns false, that probably means we failed a double-check (or in other words, this item no longer uses this weapon, if it ever did)
		if !item:ToVoid( true, self.Weapon ) then return true end
		
		--DEBUG
		Msg( "Itemforge Item SWEP (Ent ID "..self.Weapon:EntIndex().."): Unexpected removal, dropping item as entity\n" );
		
		--After we send it to void successfully, we can drop it in the world. We do this because OnDrop doesn't work correctly.
		item:ToWorld( self.Weapon:GetPos() );
	end
end

--[[
* SERVER
* Event

Runs when the owner changes
]]--
function SWEP:OwnerChanged()
	--DEBUG
	Msg( "Itemforge Item SWEP: "..tostring( item ).." changed owner to "..tostring( self.Owner ).."\n" );
	
	self:GetItem():SetWOwner( self.Owner );
end

--[[
* SERVER
* Event

This doesn't work for any weapon due to some bug related to the Orange Box I suspect;
but if it did, we don't want the weapon to drop, we want to get rid of the weapon and send the item to world.
]]--
function SWEP:ShouldDropOnDie()
	return false;
end

--[[
* SERVER
* Event

Runs when the player picks up this weapon.
]]--
function SWEP:Equip( plNewOwner )
	
	--return self:GetItem():Event( "SWEPEquip", nil, plNewOwner );
	--DEBUG
	Msg( "Itemforge Item SWEP (Ent ID "..self.Weapon:EntIndex().."): "..tostring( plNewOwner ).." equips weapon\n" );
end

--[[
* SERVER

Runs when the player picks up this weapon and already has it.
Shouldn't happen, will report an error message if it does.
]]--
function SWEP:EquipAmmo( plNewOwner )
	ErrorNoHalt( "Itemforge Item SWEP (Ent ID "..self.Weapon:EntIndex().."): "..tostring( plNewOwner ).." was given an Itemforge weapon he already has. Shouldn't happen." );
end

--[[
* SERVER

May allow items to take advantage of this later
Use GetNetworked* functions (entity) to restore data from a save-game
]]--
function SWEP:OnRestore()
end

--[[
--We probably need to remove the SWEP and drop the item instead
--THIS EVENT IS NOT WORKING - DISABLED UNTIL FIXED (by garry)
function SWEP:OnDrop()
	Msg("ON DROP CALLED\n");
	if self.Item && self.Item:IsValid() then
		local pos=self.Weapon:GetPos();
		self.Item:Release();
		self.Item:ToWorld(pos,Angle(0,0,0));
	else
		self.Weapon:Remove();
	end
	return true;
end
]]--