--[[
base_ammo
SHARED

base_ammo is a base. That means that other items borrow code from this so they can be created easier.
Any item that inherits from this has everything this item has, and can override anything this item has.

The base_ammo item's purpose is to create some basic stuff that all ammo has in common.
Additionally, you can tell if something is ammunition by seeing if it's based off of this item.
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name			= "Base Ammunition";
ITEM.Description	= "This item is the base ammunition.\nAll ammunition inherits from this.\n\nThis is not supposed to be spawned.";
ITEM.MaxHealth		= 5;					--I feel this is appropriate since individual shells/bullets/whatever are small.
											--Keep in mind the total health of the stack is amt * maxhealth, so if you had 45 bullets * 5 hp each thats 225 health total.
											--Destroying all of those bullets would mean inflicting 225 points of damage upon the stack.

ITEM.MaxAmount		= 0;					-- ./~ Stack that ammo to the ska-aay ./~

--We don't want players spawning it.
ITEM.Spawnable		= false;
ITEM.AdminSpawnable	= false;

if SERVER then




ITEM.GibEffect				= "none";		--Ammo does not gib when broken




end

local vZero = Vector( 0, 0, 0 );

--[[
* SHARED
* Event

I noticed players will press [USE] on ammo when they want to load their guns with it.
If a player uses this ammo while holding an item based off of base_ranged, we'll try to load his gun with it.
If the ammo is used clientside, we won't actually load the gun, we'll just return true to indiciate we want the server to load the gun.
]]--
function ITEM:OnUse( pl )
	local item = IF.Items:GetWeaponItem( pl:GetActiveWeapon() );
	if item && item:InheritsFrom( "base_ranged" ) && item:PlayerLoadAmmo( pl, item, 1 ) then
		return SERVER;
	end
	
	--We couldn't load whatever the player was carrying, so just do the default OnUse
	return self:BaseEvent( "OnUse", false, pl );
end

--[[
* SHARED
* Event

Returns the total amount of ammo provided by this item.
By default, this returns the # of items in the ammo stack.

Your ammo items can override this if you want the ammo items to present how much "ammo" they contain differently. For example:
	You could make containers (like clips/magazines) that returned the total # of bullets in their inventory
	You could make batteries that returned charge instead of amount.
]]--
function ITEM:GetAmmo()
	return self:GetAmount();
end

--[[
* SHARED
* Event

Returns the max amount of ammo this item can provide.
By default, this returns the max amount of the ammo stack.

Your ammo items can override this if you want the ammo items to present how much "ammo" they contain differently. For example:
	You could make containers (like clips/magazines) that returned the total # of bullets that can be put in them
	You could make batteries that returned max charge instead of max amount.
]]--
function ITEM:GetMaxAmmo()
	return self:GetMaxAmount();
end

--[[
* SHARED
* Event

This event is called when a weapon wants to consume a certain amount of ammo from this stack.
By default, this subtracts the # of items in the ammo stack.

Your ammo items can override this if you want to handle depletion differently. For example:
	You could make containers (like clips/magazines) that subtract bullets from their inventory
	You could make batteries that lose charge when a weapon takes ammo
	You could make this function do nothing for an unlimited ammo source

iAmt is the amount of ammo that needs to be taken.
]]--
function ITEM:TakeAmmo( iAmt )
	self:SubAmount( iAmt );
end

--[[
* SHARED
* Event

This event is called by weapons to check if (at least) a certain amount of ammo is available.
By default, this checks the # of items in the ammo stack.

Your ammo items can override this if you want to handle depletion differently. For example:
	You could make containers (like clips/magazines) that look at how many bullets total are stored in their inventory
	You could make batteries that check the charge instead of the # of batteries in the stack.
	You could make the function always return true if the ammo item provides an unlimited amount of ammo.

iAmt is the amount of ammo to check for.

Return true if the ammo is available,
or false otherwise.
]]--
function ITEM:HaveAmmo( iAmt )
	return self:GetAmount() >= iAmt;
end

if CLIENT then




--[[
* CLIENT
* Event

If the player has a base_ranged weapon out, we'll give him the option to load his weapon with this ammo
]]--
function ITEM:OnPopulateMenu( pnlMenu )
	self:BaseEvent( "OnPopulateMenu", nil, pnlMenu );
	
	--TODO more than one clip
	local item = IF.Items:GetWeaponItem( LocalPlayer():GetActiveWeapon() );
	if item && item:InheritsFrom( "base_ranged" ) && item:CanLoadClipWith( 1, self ) then
		pnlMenu:AddOption( "Load into "..IF.Util:LabelSanitize( item:Event( "GetName", "Unknown Weapon" ) ), function( pnl ) item:PlayerLoadAmmo( LocalPlayer(), self, 1 ) end );
	end
end




end