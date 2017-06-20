--[[
base_ranged
SHARED

This specific file contains functions used to locate ammo for weapons.
Whenever a gun needs to be reloaded, it needs to be loaded with an ammo item. But where does this ammo item come from? Nearby the weapon? From the holding player's inventory? Where?
Functions in the "Itemforge_BaseRanged_FindAmmo" list are called to solve this problem.
You could make a function to search the holding player's inventory for a type of ammo, for example.
Or maybe you could make a function that converts HL2 ammo the player is holding into an ammo item, then return the item. Sky's the limit!

FindAmmo functions have two arguments:
	self is the weapon that is trying to find ammo.
	fnCallback is the function given to :FindAmmo(). It's arguments are fnCallback( self, itemFound ).
A FindAmmo function should return nil if ammo couldn't be found with that function for some reason, or the found item if true if fnCallback returns true. 
See the example FindAmmo function below for more information:
]]--

ITEM.AmmoMaxRange = 64;

--[[
I made an example FindAmmo function for you.
This searches a holding player's inventory for ammo (lets pretend that plOwner.Inventory is his inventory).
Copy/paste this to make your own ammo-finding functions; this should go in a shared script that autoruns


list.Add( "Itemforge_BaseRanged_FindAmmo", function( self, fnCallback )
	local plOwner = self:GetWOwner();
	if !plOwner then return false end		--We can't find any ammo this way if the weapon isn't being held!
	
	--Lets look at all the items in the player's inventory... (v is an item in his inventory)
	for k, v in pairs( plOwner.Inventory:GetItems() ) do
		
		--Is this item what you were looking for?
		if fnCallback( self, v ) then
		
			--SWEET! It was! Let's return the item that was approved!
			return v;
		end
	end
	
	--Crap!! None of the items in the player's inventory worked! Lets see if we can't find ammo some other way...
	return nil;
end )
]]--

--[[
* SHARED

Uses the functions in the Itemforge_BaseRanged_FindAmmo list to find ammo for the weapon.

fnCallback should be a function( self, itemFound ).
	self will be the item you're finding ammo for.
	itemFound will be the item the ammo-finding functions found
		NOTE: itemFound can be any kind of item! Make sure fnCallback checks that the ammo is usable.
	fnCallback should return false if you want to keep searching for ammo, or true to stop searching.

This returns the approved item (that fnCallback returned true for) if usable ammo was located 
This returns nil if usable ammo wasn't located (fnCallback never returned true)
]]--
function ITEM:FindAmmo( fnCallback )
	local l = list.Get( "Itemforge_BaseRanged_FindAmmo" );
	for k, v in pairs( l ) do
		local s, r = pcall( v, self, fnCallback );
		
		if !s		then self:Error( "While finding ammo, A function in the \"Itemforge_BaseRanged_FindAmmo\" list encountered a problem: "..r );
		elseif r	then return r;
		end
	end
	return nil;
end






--[[
* SHARED

If the weapon is in an inventory, this function returns any ammo in the same inventory as it
]]--
list.Add( "Itemforge_BaseRanged_FindAmmo", function( self, fnCallback )
	local inv = self:GetContainer();
	if !inv then return false end
	
	for k, v in pairs( inv:GetItems() ) do
		if fnCallback( self, v ) then return v end
	end
	
	return nil;
end );

--[[
* SHARED

This function finds ammo when the item is being held by a player (as a weapon).

This particular function looks for potential ammo from 3 different sources, prioritizing like so:
	1. An item in the world the player is looking at directly
	2. Other items held by the player (in his weapon menu), we'll try to load that.
	3. Items in the world, in the player's immediate vicinity
TODO: THIS IS CRAP, REDO IT
]]--
list.Add( "Itemforge_BaseRanged_FindAmmo", function( self, fnCallback )
	local plOwner = self:GetWOwner();
	if !plOwner then return nil end
	
	--Is the player looking directly at an item?
	local vShoot	= plOwner:GetShootPos();
	local tr		= {};
	tr.start		= vShoot;
	tr.endpos		= vShoot + ( 64 * plOwner:GetAimVector() );
	tr.filter		= plOwner;
	local traceRes	= util.TraceLine( tr );

	local i = IF.Items:GetEntItem( traceRes.Entity );
	if i && fnCallback( self, i ) then return i end
	
	if SERVER then
		for k, v in pairs( plOwner:GetWeapons() ) do
			local item = IF.Items:GetWeaponItem( v );
			if item && fnCallback( self, item ) then
				return item;
			end
		end
	end
	
	for k, v in pairs( IF.Items:GetWorld() ) do
		local e			= v:GetEntity();

		local tr		= {};
		tr.start		= vShoot;
		tr.endpos		= vShoot + self.AmmoMaxRange * ( e:LocalToWorld( e:OBBCenter() ) - vShoot ):Normalize();
		tr.filter		= plOwner;
		local traceRes	= util.TraceLine( tr );

		if traceRes.Entity == e && fnCallback( self, v ) then return v end
	end
	
	return nil;
end );

--[[
* SHARED
* Event

This function searches the area around the weapon for nearby ammo.
TODO: THIS IS CRAP, REDO IT
]]--
list.Add( "Itemforge_BaseRanged_FindAmmo", function( self, fnCallback )
	local eEntity = self:GetEntity();
	if !eEntity then return false end

	for k, v in pairs( IF.Items:GetWorld() ) do
		local e = v:GetEntity();
		local tr = {};
		
		tr.start			= eEntity:LocalToWorld( eEntity:OBBCenter() );
		tr.endpos			= tr.start + self.AmmoMaxRange * ( e:LocalToWorld( e:OBBCenter() ) - tr.start ):Normalize();
		tr.filter			= eEntity;
		local traceRes		= util.TraceLine( tr );
		if traceRes.Entity == e && fnCallback( self, v ) then return v end
	end
	
	return nil;
end );