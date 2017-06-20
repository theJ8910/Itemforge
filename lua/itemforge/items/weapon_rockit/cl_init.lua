--[[
weapon_rockit
CLIENT

A gun that fires random crap from it's inventory.
]]--

include( "shared.lua" );

ITEM.BlinkMat			= Material( "sprites/gmdm_pickups/light" );
ITEM.BlinkColor			= Color( 255, 0, 0, 255 );
ITEM.BlinkOffset		= Vector( 3.1624, 4.3433, 1.5108 );

ITEM.DrawAmmoNextMat	= Material( "sprites/yellowflare" )
ITEM.DrawAmmoCount		= 4;
ITEM.DrawAmmoSize		= 1 / ITEM.DrawAmmoCount;

--[[
* CLIENT
* Event

This overrides base_ranged's OnDragDropHere event.
Since we don't use clips, any item the player can interact with can be drag-dropped here.
]]--
function ITEM:OnDragDropHere( otherItem )
	if !self:Event( "CanPlayerInteract", false, LocalPlayer() ) || !otherItem:Event( "CanPlayerInteract", false, LocalPlayer() ) then return false end
	return self:SendNWCommand( "PlayerLoadAmmo", otherItem );
end

--[[
* CLIENT
* Event

Overridden from base_ranged;
Like the base_ranged, we have everything the base weapon has.
Unlike the base_ranged:
	We only have one mode of fire
	We have an option to open the rock-it's inventory,
	If we have anything loaded it says how many items to unload (or if only one item, the option to unload it)
]]--
function ITEM:OnPopulateMenu( pnlMenu )
	--We've got everything the base weapon has and more!
	self:InheritedEvent( "OnPopulateMenu", "base_weapon", nil, pnlMenu );
	
	--Options to fire gun
			pnlMenu:AddOption( "Fire Primary",		function( pnl )	self:SendNWCommand( "PlayerFirePrimary" )		end );
	
	--Options to unload ammo
	local inv = self:GetInventory();
	if inv then
		local iAmmoCount = inv:GetCount();
		if iAmmoCount > 0 then
			local strAmmo;
			if iAmmoCount > 1 then strAmmo = iAmmoCount.." items";
			else
				local firstItem = inv:GetFirst();
				strAmmo = firstItem:Event( "GetName", "Unknown Item" );
				if firstItem:IsStack() then strAmmo = strAmmo.." x "..firstItem:GetAmount() end
			end
			
			pnlMenu:AddOption( "Unload "..strAmmo,	function( pnl )	self:SendNWCommand( "PlayerUnloadAmmo", 1 )		end );
		end
	end
	
	--Option to load ammo
			pnlMenu:AddOption( "Reload",			function( pnl )	self:SendNWCommand( "PlayerReload" )			end );
	
	--Option to check inventory
			pnlMenu:AddOption( "Check Inventory",	function( pnl )	self:ShowInventory()							end );
end

--[[
* CLIENT
* Event

If someone uses it clientside, show the inventory to them
]]--
function ITEM:OnUse( pl )
	self:ShowInventory();
	return false;
end

--[[
* CLIENT
* Event

Wait for our inventory to arrive clientside; when it does, record that it's our inventory
]]--
function ITEM:OnConnectInventory( inv, iConSlot )
	if !self.Inventory then
		self.Inventory = inv;
		return true;
	end
	return false;
end

--[[
* CLIENT
* Event

If for some reason the inventory unlinks from us, we'll forget about it
]]--
function ITEM:OnSeverInventory( inv )
	if self.Inventory == inv then self.Inventory = nil; return true end
	return false;
end

--[[
* CLIENT
* Event

Normal OnDraw3D, but also draws an unload blink if we're unloading.
]]--
function ITEM:OnDraw3D( eEntity, bTranslucent )
	self:BaseEvent( "OnDraw3D", nil, eEntity, bTranslucent );
	if self:GetNWBool( "Unloading" ) then self:DrawUnloadBlink( eEntity ) end
end

--[[
* CLIENT
* Event

Draws icons of upcoming ammo.
]]--
function ITEM:OnDraw2D( iWidth, iHeight )
	local inv = self:GetInventory();
	if !inv then return false end
	
	local items = inv:GetItems();
	local iIconSize = ( iHeight - 4 ) * self.DrawAmmoSize;
	local iX, iY;
	local iAmmoCount = 1;
	for i = 1, table.maxn( items ) do
		if items[i] then
			iX = iWidth  - 2 -				iIconSize;
			iY = iHeight - 2 - iAmmoCount * iIconSize;
			if iAmmoCount == 1 then
				surface.SetMaterial( self.DrawAmmoNextMat );
				surface.DrawTexturedRect( iX, iY, iIconSize, iIconSize );
			end
			
			items[i]:DrawIcon( iX, iY, iIconSize, iIconSize );
			
			iAmmoCount = iAmmoCount + 1;
			if iAmmoCount > self.DrawAmmoCount then break end
		end
	end
	
	self:InheritedEvent( "OnDraw2D", "base_weapon", nil, iWidth, iHeight );
end

--[[
* CLIENT

Shows the gun's inventory to the local player
]]--
function ITEM:ShowInventory()
	local inv = self:GetInventory();
	if !inv || ( self.InventoryPanel && self.InventoryPanel:IsValid() ) then return false end	
	self.InventoryPanel = vgui.Create( "ItemforgeInventory" );
	self.InventoryPanel:SetInventory( inv );
end

--[[
* CLIENT

Draws a blinking sprite.
The entity varies depending on what is drawing.
]]--
function ITEM:DrawUnloadBlink( eEntity )
	if math.sin( 30 * CurTime() ) < 0 then return end
	
	render.SetMaterial( self.BlinkMat );
	render.DrawSprite( eEntity:LocalToWorld( self.BlinkOffset ), 8, 8, self.BlinkColor );
end