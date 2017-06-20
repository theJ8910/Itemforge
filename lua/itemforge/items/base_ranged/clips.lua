--[[
base_ranged
SERVER

base_ranged is a base. That means that other items borrow code from this so they can be created easier.
Any item that inherits from this has everything this item has, and can override anything this item has.

This specific file contains functions related to clips (they hold ammo items / stacks of ammo items).
]]--

local cDefaultBack				= Color( 200, 150, 0, 255 );
local cDefaultBar				= Color( 255, 204, 0, 255 );
local cDefaultLow				= Color( 255, 0,   0, 255 );

--[[
* SHARED

Assumes the given item is valid.

Returns false if:
	The given clip doesn't exist.
	The weapon was being used as it's own ammo
	The item given is not the right type of ammo for this clip (for example, if we use "base_ammo", that means that "base_ammo" or anything that inherits from "base_ammo" works)
Returns true otherwise.
]]--
function ITEM:CanLoadClipWith( iClip, itemAmmo )
	local tClipInfo = self.Clips[iClip];
	
	return tClipInfo && self != itemAmmo && itemAmmo:InheritsFrom( tClipInfo.Type );
end

--[[
* SHARED

Returns the # of clips in the weapon.
]]--
function ITEM:GetNumberOfClips()
	return #self.Clips;
end

--[[
* SHARED

Returns true if the given clip is full (the ammosource stack's amount = the clip size).
Returns false if there is no ammo source, or if the ammo source isn't filling the clip to capacity.
]]--
function ITEM:IsClipFull( iClip )
	local itemAmmoSource = self:GetAmmoSource( iClip );
	if !itemAmmoSource then return false end

	return itemAmmoSource:GetAmount() == self:GetClipSize( iClip );
end

--[[
* SHARED
* Internal

Sets the item / stack of items in the given clip.
If item is nil, clears the item in the given clip.
]]--
function ITEM:SetAmmoSource( iClip, item )
	self.Clip[iClip] = item;
	
	if SERVER then
		item.OldMax = item:GetMaxAmount();
		item:SetMaxAmount( self:GetClipSize( iClip ) );
		self:SendNWCommand( "SetAmmoSource", nil, iClip, item )
	end
end

--[[
* SHARED

Returns the item currently loaded in the given clip.
If that clip doesn't exist, or if nothing is loaded in it, returns nil.
]]--
function ITEM:GetAmmoSource( iClip )
	local itemCurAmmo = self.Clip[iClip];
	if itemCurAmmo && !itemCurAmmo:IsValid() then
		self.Clip[iClip] = nil;
		return nil;
	end
	return itemCurAmmo;
end

--[[
* SHARED

If a stack of items is loaded into the given clip, returns the # of items in that stack.
If no item is loaded, returns 0.
]]--
function ITEM:GetAmmoSourceAmount( iClip )
	local item = self:GetAmmoSource( iClip );
	if !item then return 0 end

	return item:GetAmount();
end

--[[
* SHARED

Returns the size of the given clip.
The clip size controls the max amount of an ammo source stack loaded into that clip (e.g. max # of bullets, max # of flares, etc that can fit in this clip).

Returns 0 if the clip can hold an unlimited amount.
Returns nil if the clip doesn't exist.
]]--
function ITEM:GetClipSize( iClip )
	local tClip = self.Clips[iClip];
	if !tClip then return nil end
	
	return tClip.Size;
end

--[[
* SHARED

Returns the ammo bar background color for the given clip,
or the default color if the clip doesn't exist or doesn't have a custom color.
]]--
function ITEM:GetClipBackgroundColor( iClip )
	local tClip = self.Clips[iClip];
	return ( tClip && tClip.BackColor ) || cDefaultBack;
end

--[[
* SHARED

Returns the ammo bar color for the given clip,
or the default color if the clip doesn't exist or doesn't have a custom color.
]]--
function ITEM:GetClipBarColor( iClip )
	local tClip = self.Clips[iClip];
	return ( tClip && tClip.BarColor ) || cDefaultBar;
end

--[[
* SHARED

Returns the ammo bar "low on ammo" color for the given clip,
or the default "low on ammo" color if the clip doesn't exist or doesn't have a custom color.
]]--
function ITEM:GetClipLowColor( iClip )
	local tClip = self.Clips[iClip];
	return ( tClip && tClip.LowColor ) || cDefaultLow;
end