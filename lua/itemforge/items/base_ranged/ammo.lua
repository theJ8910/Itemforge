--[[
base_ranged
SERVER

base_ranged is a base. That means that other items borrow code from this so they can be created easier.
Any item that inherits from this has everything this item has, and can override anything this item has.

This specific file contains functions related to ammo usage.
]]--

--[[
* SHARED

Returns the remaining ammo provided by the ammo source in the given clip.

Not always the same as the # of items in the ammo source
Example: A single battery (amount = 1) can have 45 charge (ammo = 45).

If an ammo source is available, calls and returns the result of it's GetAmmo event.
If an ammo source is not available, or there was an error calling it's GetAmmo event, returns 0.
]]--
function ITEM:GetAmmo( iClip )
	local itemCurAmmo = self:GetAmmoSource( iClip );
	if !itemCurAmmo then return 0 end

	return itemCurAmmo:Event( "GetAmmo", 0 );
end

--[[
* SHARED

Returns the max ammo provided by the current ammo source in the given clip.

Not always the same as the max # of items in the ammo source.
Example: A single battery (maxamount = 1) can have at most 50 charge (maxammo = 50).

If an ammo source is available, calls and returns the result of it's GetMaxAmmo event.
If an ammo source is not available, or there was an error calling it's GetMaxAmmo event, returns the size of the given clip.
]]--
function ITEM:GetMaxAmmo( iClip )
	local itemCurAmmo = self:GetAmmoSource( iClip );
	local iClipSize = self:GetClipSize( iClip );
	if !itemCurAmmo then return iClipSize end

	return itemCurAmmo:Event( "GetMaxAmmo", iClipSize );
end

--[[
* SHARED

Returns true if the ammo source in the given clip at least has the given amount of ammo available.

Not always the same as the # of items in the ammo source
Example: A single battery (amount = 1) can have 45 charge (ammo = 45).

If an ammo source is available, calls and returns the result of it's HaveAmmo event.
If an ammo source is not available, or there was an error calling it's HaveAmmo event, returns false.
]]--
function ITEM:HaveAmmo( iAmt, iClip )
	local itemCurAmmo = self:GetAmmoSource( iClip );
	if !itemCurAmmo then return false end
	return itemCurAmmo && itemCurAmmo:Event( "HaveAmmo", false, iAmt );	
end

--[[
* SHARED

Consumes the given amount of ammo from the ammo source in the given clip.

If an ammo source is available, calls it's TakeAmmo event and passes the amount of ammo to take.
If no ammo source is available, nothing happens.

iAmt is the amount of ammo you want to take.
]]--
function ITEM:TakeAmmo( iAmt, iClip )
	local itemCurAmmo = self:GetAmmoSource( iClip );
	if !itemCurAmmo then return end
	
	itemCurAmmo:Event( "TakeAmmo", nil, iAmt );
	if SERVER then self:UpdateWireAmmoCount() end
end