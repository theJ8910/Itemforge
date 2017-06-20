--[[
base_ammo_explosive
SHARED

base_ammo_explosive is a base. That means that other items borrow code from this so they can be created easier.
Any item that inherits from this has everything this item has, and can override anything this item has.

The base_ammo_explosive item's purpose is to create some basic stuff that all explosive ammo has in common.
Additionally, you can tell if something is explosive ammunition by seeing if it's based off of this item.
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name				= "Base Explosive Ammunition";
ITEM.Description		= "This item is the base explosive ammunition.\nAll explosive ammunition inherits from this.\n\nThis is not supposed to be spawned.";
ITEM.Base				= "base_ammo";

--We don't want players spawning it.
ITEM.Spawnable			= false;
ITEM.AdminSpawnable		= false;

--Base Explosive Ammo
ITEM.ExplodeDamage		= 10;			--It's explosion does this much damage
ITEM.ExplodeRadius		= nil;			--It's explosion will not damage things further than this distance; leave nil if you want the radius to be based on damage


if SERVER then




--[[
* SERVER

Does a standard explosive-ammo explosion.

eWhoTriggered is an optional player / entity to credit the kill to.
]]--
function ITEM:DoExplosion( eWhoTriggered )
	self:Explode( self:Event( "GetExplodeDamage" ) * self:GetAmount(), self:Event( "GetExplodeRadius" ), eWhoTriggered );
end

--[[
* SERVER
* Event

Determines how much damage an explosion will do.
]]--
function ITEM:GetExplodeDamage()
	return self.ExplodeDamage;
end

--[[
* SERVER
* Event

Determines how close to the explosion things must be to be damaged by the explosion.
]]--
function ITEM:GetExplodeRadius()
	return self.ExplodeRadius;
end

--[[
* SERVER
* Event

When explosive ammo is destroyed it explodes
]]--
function ITEM:OnBreak( iHowMany, bLastBroke, eWho )
	self:DoExplosion( eWho );
end

--[[
* SERVER
* Event

This event tells Wiremod that explosive ammo can be triggered to explode
]]--
function ITEM:GetWireInputs( eEntity )
	return Wire_CreateInputs( eEntity, { "Explode" } );
end

--[[
* SERVER
* Event

This event handles Wiremod's requests
]]--
function ITEM:OnWireInput( eEntity, strInputName, vValue )
	if strInputName == "Explode"	&&	vValue != 0 then	self:DoExplosion() end
end




end