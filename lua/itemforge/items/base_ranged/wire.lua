--[[
base_ranged
SERVER

base_ranged is a base. That means that other items borrow code from this so they can be created easier.
Any item that inherits from this has everything this item has, and can override anything this item has.

This specific file contains functions related to the gun's Wiremod capabilities.
]]--

--[[
* SERVER
* Event

Auto-attack or try to find ammo if Wiremod has told us to
Also, if a reloads-singly weapon is in a reload loop, then we focus on the reload loop instead.
]]--
function ITEM:OnThink()
	if		self:GetNWBool( "InReload" )	== true										then
		self:Event( "ReloadThink" );

	elseif	self.PrimaryFiring				== true	&& self:CanPrimaryAttackAuto()		then
		self:Event( "OnSWEPPrimaryAttack" );

	elseif	self.SecondaryFiring			== true	&& self:CanSecondaryAttackAuto()	then
		self:Event( "OnSWEPSecondaryAttack" );

	elseif	self.TryingToReload				== true then
		self:Event( "OnReload" );

	end
end

--[[
* SERVER
* Event

The item think starts when the weapon is dropped in the world
]]--
function ITEM:OnEnterWorld( eEnt, vPos, aAng, bTeleport )
	self:StartThink();
end

--[[
* SERVER

The base_ranged weapons need to think when they enter an inventory
and stop thinking when they leave one.
]]--
function ITEM:OnMove( OldInv, OldSlot, NewInv, NewSlot, bForced )
	if		OldInv == nil	then	self:StartThink();
	elseif	NewInv == nil	then	self:StopThink();
	end
end

--[[
* SERVER
* Event

The item think stops when the weapon is taken out of the world

If the gun was firing on it's own or was trying to find some ammo to reload with (via Wiremod) it won't be any more.
This only works while the item is dropped in the world.
]]--
function ITEM:OnExitWorld( bForced )
	self.PrimaryFiring = false;
	self.SecondaryFiring = false;
	self.WasTryingToReload = false;
	self.TryingToReload	= false;

	self:StopThink();
end

--[[
* SERVER
* Event

Tells Wiremod that our gun can fire the primary / secondary attack and can reload with nearby ammo.
]]--
function ITEM:GetWireInputs( eEntity )
	return Wire_CreateInputs( eEntity, { "Fire Primary", "Fire Secondary", "Reload" } );
end

--[[
* SERVER
* Event

Tells Wiremod that our gun can report how much ammo is in it's clip(s)
]]--
function ITEM:GetWireOutputs( eEntity )
	local t = {};
	for i = 1, #self.Clips do
		table.insert( t, "Clip "..i );
	end
	return Wire_CreateOutputs( eEntity, t );
end

--[[
* SERVER
* Event

This function handles the wiremod requests to fire/reload the gun
]]--
function ITEM:OnWireInput( eEntity, strInputName, vValue )
	if strInputName == "Fire Primary" then
		if vValue == 0 then	self.PrimaryFiring = false;
		else				self.PrimaryFiring = true;
		end
	elseif strInputName == "Fire Secondary" then
		if vValue == 0 then	self.SecondaryFiring = false;
		else				self.SecondaryFiring = true;
		end
	elseif strInputName == "Reload" then
		if vValue == 0 then
			self.TryingToReload = false;
			if !self:GetNWBool( "InReload" ) then
				self.WasTryingToReload = false;
			end
		else
			self.TryingToReload = true;
			self.WasTryingToReload = true;
		end
	end
end

--[[
* SERVER

Triggers the ammo-in-clip wire outputs; updates them with the correct ammo counts
]]--
function ITEM:UpdateWireAmmoCount()
	for i = 1, #self.Clips do
		self:WireOutput( "Clip "..i, self:GetAmmo( i ) );
	end
end