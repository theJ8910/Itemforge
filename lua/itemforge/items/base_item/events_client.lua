--[[
events_client
CLIENT

base_item is the default item. All items except base_item inherit from this item-type.
NOTE: The item type is the name of the folder it is in (this is base_item/events_client.lua, so this item's type is "base_item")

This specific file deals with events that are present on the client.
]]--

local vZero		= Vector( 0, 0, 0 );
local cOutline	= Color( 255, 179, 0 );		--This is the color of the outline displayed when the mouse hovers over the item in the world

--[[
ENTITY SPECIFIC EVENTS
]]--

--[[
* CLIENT
* Event

Whenever an item is dropped into the world, an entity is created to represent it.
This event runs when the entity sets it's item to us clientside.

NOTE: It is impossible for me to run this event when the entity is initialized clientside.
	Serverside, a networked int with this Item's ID is set on the entity.
	This function runs when the entity "acquires" this item's ID clientside and sets it's item to this item.
	It may take a short period of time (usually a fraction of a second) after the entity is created serverside and then arrives clientside for the item it is supposed to use to be set.
	However, this is assuming the player can see this entity. Due to PVS optimization, the entity may not exist until the player sees it clientside.
	When that occurs, this function will run; keep this in mind.

eEntity is the SENT that is created to hold the object. It's "ENT.Entity".
]]--
function ITEM:OnEntityInit( eEntity )
	eEntity.PrintName = self:Event( "GetName", "Itemforge Item" );
	return true;
end

--[[
SWEP SPECIFIC EVENTS
]]--

--[[
* CLIENT
* Event

This event is called when this item needs it's weapon menu graphics drawn.

The weapon menu graphics are drawn inside of a black box.
fX and fY describe where the top-left corner of the black box is in pixels.
fW and fH describe how wide and tall (respectively) the black box is in pixels.
fA is a number between 0 and 255 that describes how opaque the weapon menu graphics should be.
	This is 255 when the menu is open.
	The weapons menu slowly fades out if it is left open for too long;
	While this is happening, "fA" will slowly change from 255 to 0.
]]--
function ITEM:OnSWEPDrawMenu( fX, fY, fW, fH, fA )
	self:DrawIcon( fX + 0.5 * ( fW - 64 ),
				   fY + 0.5 * ( fH - 64 ) + 16 * math.sin( 5 * RealTime() ),
				   64, 64,
				   fA );
end

--[[
* CLIENT
* Event

This event is run when it comes time to draw a viewmodel.
This will only be called if the item is a player's active weapon.
]]--
function ITEM:OnSWEPDrawViewmodel()
end

--[[
* CLIENT
* Event

This function is run when it comes time to draw something on the player's HUD.
This will only be called if the item is a player's active weapon.
]]--
function ITEM:OnSWEPDrawHUD()
end

--[[
* CLIENT
* Event

This event can be used to hide or show elements on the HUD.
This will only be called if the item is a player's active weapon.

It runs once before each HUD element draws. So this hook is potentially called several times
in a single draw frame.

The game basically asks the item if a HUD element (whose name is given) is allowed to draw.
You can return false if you don't want it to draw or true if you do.
]]--
function ITEM:OnSWEPHUDShouldDraw( strName )
	return true;
end

--[[
* CLIENT
* Event

This hook allows you to change the camera's FOV. This is useful for items with scopes.
This will only be called if the item is a player's active weapon.

The camera's current FOV is passed into the function, in degrees.
the returned FOV should be between 0 and 180 degrees, but negative values do work and
have the effect of flipping the screen upside down.

NOTE: the closer FOV gets to 0 the more "zoomed in" the view appears. The closer FOV
gets to 180 the more "zoomed out" the view appears.
]]--
function ITEM:OnSWEPTranslateFOV( fCurrentFOV )
	return fCurrentFOV;
end

--[[
* CLIENT
* Event

This event determines if we should freeze the view of the holding player (freeze meaning stop
the player from rotating his view).
This will only be called if the item is a player's active weapon.

Returning true prevents the player from rotating his view.
Returning anything else (or nothing at all) allows him to rotate his view.
]]--
function ITEM:OnSWEPFreezeMovement()
	return false;
end

--[[
* CLIENT
* Event

This event can be used to adjust the mouse sensitivity.
This will only be called if the item is a player's active weapon.

This hook is particularly useful for sniper rifles, since the player's view often needs to rotate slower as he zooms in.

You may return a multiplier to change how sensitive the mouse is (such as 2 for double
the mouse sensitivity, 3 for triple the sensitivity, 0 for no mouse movement at all).

You may also return nil or 1 for no change in mouse sensitivity.
]]--
function ITEM:OnSWEPAdjustMouseSensitivity()
	return nil;
end

--[[
* CLIENT
* Event

This event can be used to modify the ammo counter in the lower-right hand corner.
This will only be called if the item is a player's active weapon.

If you want to modify the ammo counter, this event should return a table (preferably an existing
table that is modified in this function; creating tables every frame is expensive!).

The table's members should be:
	t.Draw:				true if you want the ammo display to draw, false if you don't
	
	Set these both to nil if you don't want primary ammo info to show up
	t.PrimaryClip:		# of bullets/fuel/whatever in the primary clip
	t.PrimaryAmmo:		# of bullets/fuel/whatever that the player has in reserve
	
	Set these both to nil if you don't want secondary ammo info to show up
	t.SecondaryClip:	# of bullets/fuel/whatever in the secondary clip
	t.SecondaryAmmo:	# of bullets/fuel/whatever that the player has in reserve

You can also return nil if you don't want to use a custom ammo display.
]]--
function ITEM:OnSWEPCustomAmmoDisplay()
	return nil;
end

--[[
* CLIENT
* Event

This event can be used to modify the SWEP's view model position/angles on screen.
vOldPos is the old position of the viewmodel.
aOldAng is the old angles the viewmodel is using.

You should return two values in this hook, the new position and the new angles like so:
return vNewPos, aNewAng;
]]--
function ITEM:GetSWEPViewModelPosition( vOldPos, aOldAng )
	return vOldPos, aOldAng;
end








--[[
ITEM EVENTS
]]--

--[[
* CLIENT
* Event

Returns a Material() representing the icon this item displays.
This is called every time the icon needs to be drawn, so one thing that can be done is animating the icon by returning a different icon depending on the CurTime().
]]--
function ITEM:GetIcon()
	return self.Icon;
end

--[[
* CLIENT
* Event

This runs after a right click menu has been created.
pnlMenu is the created menu. You can add menu entries here.
These methods might be of some use:
	pnlMenu:AddOption( strText, fnFunction );
	pnlMenu:AddSpacer();
	pnlMenu:AddSubMenu( strText, fnFunction );
	pnlMenu:AddPanel( pnlToAdd );
]]--
function ITEM:OnPopulateMenu( pnlMenu )
	--Add basic "Use" and "Hold" options
						   pnlMenu:AddOption( "Use",		function( pnl ) self:Use( LocalPlayer() )			end );
	
	if !self:IsHeld() then pnlMenu:AddOption( "Hold",		function( pnl ) self:PlayerHold( LocalPlayer() )	end );			end
	
						   pnlMenu:AddOption( "Examine",	function( pnl ) self:PlayerExamine( LocalPlayer() ) end );

	--Add "Split" option; as long as there are enough items to split (at least 2); also, the CanPlayerSplit event must indicate it's possible
	if self:IsStack() && self:GetAmount() > 1 && self:Event( "CanPlayerSplit", true, LocalPlayer() ) then

						   pnlMenu:AddOption( "Split",		function( pnl ) self:PlayerSplit( LocalPlayer() )	end );

	end
end

--[[
* CLIENT
* Event

While an inventory is opened, this item can be dragged somewhere on screen.
If this item is drag-dropped to an empty slot in an inventory this function runs.
]]--
function ITEM:OnDragDropToInventory( inv, iSlot )
	self:PlayerSendToInventory( LocalPlayer(), inv, iSlot );
end

--[[
* CLIENT
* Event

While an inventory is opened, this item can be dragged somewhere on screen.
If this item is drag-dropped onto another item, this function runs.
This function will not run if the other item's OnDragDropHere function returns false.
]]--
function ITEM:OnDragDropToItem( item )
	if !self:Event( "CanPlayerInteract", false, LocalPlayer() ) then return false end
end

--[[
* CLIENT

While an inventory is opened, an item can be dragged somewhere on screen.
If an item is drag-dropped on top of this item (either dropped on a panel this item is being displayed on, or dropped onto this item in the world) this function runs.
A few examples of what this could be used for... You could:
	Merge a pile of items
	Transfer the item to this item's inventory
	Load a gun with ammo

Return true if you want otherItem's OnDragDropToItem to run.
TODO if client determines merge is impossible return false
]]--
function ITEM:OnDragDropHere( otherItem )
	--Don't even bother telling the server to merge if we know we can't interact with the two
	if !self:Event( "CanPlayerInteract", false, LocalPlayer() ) || !otherItem:Event( "CanPlayerInteract", false, LocalPlayer() ) then return true end
	
	--Predict if we can merge, fail if prediction says we can't
	if !self:Merge( otherItem ) then return true end
	
	self:SendNWCommand( "PlayerMerge", otherItem );
	return false;
end

--[[
* CLIENT
* Event

While an inventory is opened, an item can be dragged somewhere on screen.
If an item is drag-dropped to somewhere in the world, this function will run.
traceRes is a full trace results table.
]]--
function ITEM:OnDragDropToWorld( traceRes )
	if !self:Event( "CanPlayerInteract", false, LocalPlayer() ) then return false end
	self:SendNWCommand( "PlayerSendToWorld", traceRes.StartPos, traceRes.HitPos );
end

--[[
* CLIENT
* Event

If this function returns true, a model panel is displayed in an ItemforgeItemSlot control, with this item's world model.
]]--
function ITEM:ShouldUseModelFor2D()
	return self.UseModelFor2D;
end

--[[
* CLIENT
* Event

This function is run when an item slot (most likely the ItemforgeItemSlot VGUI control) is
displaying this item and needs to pose this model before drawing.

When this happens, this event is called to pose the model (rotate, position, animate, whatever).
Since some models are orientated strangely (for example, the pickaxe faces straight up,
the keypad faces backwards, etc), I have tried to automatically orientate it so that most
models are facing acceptable angles.
	By default the model is posed so that:
		A. It rotates.
		B. The end with the most surface area is facing upwards
		C. The center of the model's bounding box is at 0, 0, 0
eEntity is a ClientsideModel() belonging to the model panel using this item's world model.
pnlModelPanel is the DModelPanel on the slot displaying eEntity.
]]--
function ITEM:OnPose3D( eEntity, pnlModelPanel )
	local vMin, vMax = eEntity:GetRenderBounds();
	local vRelative = vMax - vMin;							--relative position, where vMin is at 0, 0, 0 and vMax is v
	local vCenter = 0.5 * ( vMin + vMax );					--Center, used to position 
	
	--Orientation depends on which side of the bounding box has the most surface area
	local m = math.min( vRelative.x, vRelative.y, vRelative.z );	--mINOR axe, or the axe of the bounding box that's smallest, used to determine side with most surface area
	if	   m == vRelative.z then
		eEntity:SetAngles( Angle( 0,  20 * ( RealTime() + self:GetRand() ), 0 )  );

	elseif m == vRelative.y then
		eEntity:SetAngles( Angle( 0,  20 * ( RealTime() + self:GetRand() ), 90 ) );

	elseif m == vRelative.x then
		eEntity:SetAngles( Angle( 90, 20 * ( RealTime() + self:GetRand() ), 0 )  );

	end
	
	eEntity:SetPos(     vZero - (   eEntity:LocalToWorld( vCenter ) - eEntity:GetPos()   )        );
end

--[[
* CLIENT
* Event

This function is called when a model associated with this item needs to be drawn. This usually happens in three cases:
	The item is in the world and it's world entity needs to draw.
	The item is being held as a weapon and it's world model attachment needs to draw
	An item slot (most likely the ItemforgeItemSlot VGUI control) is displaying this item and needs to draw this item's model.
eEntity is the entity that needs to draw.
	If this item is in the world, eEntity will be an itemforge_item entity (a SENT).
	If this item is held or is drawing in an item slot, eEntity will be a ClientsideModel().
If bTranslucent is true, this means that the entity is in the Translucent rendergroup.
	Or in other words, the entity is most likely partially see-through (has an alpha of less than 255).
]]--
function ITEM:OnDraw3D( eEntity, bTranslucent )
	--Draw an outline around the entity if we're hovering over it
	if IF.UI:GetDropObject() == eEntity then
		self:DrawOutline( eEntity, 1 + 0.1 * math.abs( -1 + 2 * math.fmod( 5 * CurTime(), 1 ) ), cOutline );
	end
	
	self:Draw( eEntity );
end

--[[
* CLIENT
* Event

This function is run when an item slot (most likely the ItemforgeItemSlot VGUI control) is displaying this item and needs to draw.
This function runs BEFORE OnDraw3D, so anything taking place in the background of the item can be carried out here (for instance, you could make the background for a stolen item red)

fWidth is the width of the slot the item is being drawn in.
fHeight is the height of the slot the item is being drawn in.
]]--
function ITEM:OnDraw2DBack( fWidth, fHeight )
	
end

--[[
* CLIENT
* Event

This function is run when an item slot (most likely the ItemforgeItemSlot VGUI control) is displaying this item and needs to draw.
This function runs AFTER OnDraw3D, so any 2D overlays can be carried out here (ammo meters, item amounts, etc)

fWidth is the width of the slot the item is being drawn in.
fHeight is the height of the slot the item is being drawn in.
]]--
function ITEM:OnDraw2D( fWidth, fHeight )
	--If you would rather use the icon instead of a spinning 3D model,
	--Use this code to draw the item's icon in 2D:
	--self:DrawIcon( 0, 0, fWidth, fHeight )
	
	--Stackable items have amount drawn
	if self:IsStack() then
		surface.SetFont( "ItemforgeInventoryFontBold" );
		surface.SetTextColor( 255, 255, 0, 255 );			--255, 255, 0 is bright yellow
		surface.SetTextPos( 2, fHeight - 16 );
		surface.DrawText( tostring( self:GetAmount() ) );
	end
end