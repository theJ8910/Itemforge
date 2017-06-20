--[[
ItemforgeInventory
CLIENT

Creates the ItemforgeInventory VGUI control.
This control is used to display and provide interaction between a player and the contents of an inventory.
]]--

local PANEL = {};

PANEL.Inventory				= nil;							--What inventory is this window displaying?
PANEL.TitleBarWidth			= 0;							--Width of the title bar's solid portion. Is set automatically
PANEL.TitleText				= "";							--What does the title bar have written on it? Is set automatically.
PANEL.BackgroundTilesX		= 0;							--How many tiles wide/tall is the background? Is set automatically.
PANEL.BackgroundTilesY		= 0;
PANEL.WeightText			= "";							--Set automatically. Cached weight text (so strings don't have to be generated every frame)
PANEL.CloseOnUnregister		= true;							--Set automatically. If the inventory being displayed is suddenly unregistered, should the inventory panel close?

--Subpanels
PANEL.CloseButton			= nil;
PANEL.DragButton			= nil;
PANEL.SizeLimIcon			= nil;
PANEL.WeightBar				= nil;
PANEL.Slots					= nil;
PANEL.ActionButtons			= nil;

--Dragging / Resizing variables
PANEL.MouseDownX			= 0;
PANEL.MouseDownY			= 0;
PANEL.Dragging				= false;
PANEL.Resizing				= false;

--Drag margins (the top-left corner of the inventory window must stay within the area defined by the margins)
local DragLeftMargin		= -391;							--The inventory window can't be dragged to the left of the vertical line 391 pixels to the left of the screen's left edge
local DragRightMargin		= 87;							--The inventory window can't be dragged to the right of the vertical line 87 pixels to the left of the screen's right edge
local DragTopMargin			= -36;							--The inventory window can't be dragged above the horizontal line 36 pixels above the screen's top edge
local DragBottomMargin		= 72;							--The inventory window can't be dragged beneath the horizontal line 72 pixels above the screen's bottom edge

--Minimum window width / height in pixels (for resizing). This is enough to display one row of six slots.
local MinWidth				= 437;
local MinHeight				= 287;

--Default window width / height in terms of # of slots displayed.
local DefaultColumns		= 6;
local DefaultRows			= 2;

--Background
local BackgroundMat			= Material( "itemforge/inventory/bgpattern" );
local BackgroundX			= 17;							--Where does the background begin drawing?
local BackgroundY			= 17;
local BackgroundTileWidth	= 32;							--Width/height of an individual background tile
local BackgroundTileHeight	= 32;

--Title Bar materials
local TitleMats				= {
	Material( "itemforge/inventory/title_startcap" ),
	Material( "itemforge/inventory/title_bar" ),
	Material( "itemforge/inventory/title_endcap" ),
}

local TitleX				= 63;							--The title bar starts drawing at this location
local TitleY				= 21;
local TitleHeight			= 32;							--Height of the title bar (texture size)
local TitleDisplayHeight	= 24;							--Height of the title bar (as it appears on the inventory)
local TitleStartCapWidth	= 8;							--Width of the title bar's starting cap
local TitleEndCapWidth		= 8;							--Width of the title bar's end cap
local TitleTextColor		= Color( 255, 255, 255, 255 );	--What color is the title bar text?
local TitleTextX			= 69;							--Where does the text start drawing?
local TitleTextY			= 17;
local TitleX2				= TitleX + TitleStartCapWidth;	--The portion of the title bar between the start and end caps starts drawing here

--Borders and corners
local BorderMats			= {
	Material( "itemforge/inventory/border_right" ),
	Material( "itemforge/inventory/border_top" ),
	Material( "itemforge/inventory/border_left" ),
	Material( "itemforge/inventory/border_bottom" ),
}
--Border width/height - these are for vertical borders, swap width/height for horizontal borders.
local BorderWidth			= 8;
local BorderHeight			= 32;

--There are only three corners because one is hidden by the circle
local CornerMats			= {
	Material( "itemforge/inventory/corner_sw" ),
	Material( "itemforge/inventory/corner_se" ),
	Material( "itemforge/inventory/corner_ne" ),
}
local CornerWidth			= 8;
local CornerHeight			= 8;

--Circle
local CircleMats			= {
	Material( "itemforge/inventory/circle" ),
	Material( "itemforge/inventory/circle_border" )
}
local CircleX				= 0;							--Position on the inventory that the circle is drawn.
local CircleY				= 0;
local CircleWidth			= 64;							--Width / height of the circle (texture size, in pixels).
local CircleHeight			= 64;
local CircleVerts			= {};							--An unchanging verts table. This is used to draw an icon inside of the circle.
local CircleRadius			= 29.5;							--The radius of the circle; starting at the center of the circle, the radius should land you in the middle of the border.
local CircleCenterX			= CircleX + 0.5 * CircleWidth;
local CircleCenterY			= CircleY + 0.5 * CircleHeight;

if true then
	local CircleVertDetail	= 32;							--How many verts total on the circle? Increasing this number makes the circle with the icon in it smoother but makes the inventory draw a little slower.
	
	--[[
	The radius is half the length of the diameter, so radius/diameter = 0.5.
	Except for one problem - the "diameter" is the width of the circle texture. The border actually makes the texture's width larger than the diameter of the circle!
	So unfortunately, the UV radius is not 0.5. We do have the circle radius and circle width at our disposal here though, so we can get the UV radius here.
	UV coordinates are between 0 and 1, which is why we're converting here.
	We need both pixel coordinates (for drawing at a given location) and UV coordinates (used to "cut out" part of a texture; we're drawing a rough circle, right? So we need to "cut out" a circle from whatever texture we're using.)
	]]--
	local uvRadius = CircleRadius / CircleWidth;
	local slice = 2 * math.pi / CircleVertDetail;
	
	--Precompute circle vertices
	for i = 1, CircleVertDetail do
		local ang = slice * i;
		--x and y are coordinates describing the position of a point in the direction of ang from 0,0.
		--x and y are between [-1,1].
		local x = math.cos( ang );
		local y = math.sin( ang );
		
		local v = {};
		v.u = 0.5 + ( x * uvRadius );
		v.v = 0.5 + ( y * uvRadius );
		v.x = CircleCenterX + ( x * CircleRadius);
		v.y = CircleCenterY + ( y * CircleRadius);
		
		CircleVerts[i] = v;
	end
end

--Close Button
local CloseButtonPadding	= 8;		--How many pixels between the right side of the close button and the inventory panel's right edge?
local CloseButtonY			= 25;
local CloseButtonWidth		= 16;
local CloseButtonHeight		= 16;

--Size limit icon
local SizeLimIconX			= 63;
local SizeLimIconY			= 48;

--Weight bar/label related
local WeightBarX			= 81;
local WeightBarY			= 48;
local WeightLabelX			= 340;
local WeightLabelY			= 49;
local WeightLabelTextColor	= Color( 255, 128, 0, 255 );

--Selected Item Name/Description label related
local NameLabelX			= 22;
local NameLabelPadding		= 121;							--How many pixels above the bottom of the panel and the top of the description text?
local NameLabelColor		= Color( 255, 128, 0, 255 );

--Slots panel... Where do the slots start at? What's the margin between the slots and the inventory's right / bottom side (respectively)?
local SlotsX				= 22;
local SlotsY				= 66;
local SlotsXMargin			= 5;
local SlotsYMargin			= 157;

--Inventory fonts
surface.CreateFont( "Verdana", 28, 400, true, false, "ItemforgeInventoryTitle" );	--font size 18pts
surface.CreateFont( "Verdana", 15, 400, true, false, "ItemforgeInventoryFont" );
surface.CreateFont( "Verdana", 15, 700, true, false, "ItemforgeInventoryFontBold" );

--Action buttons
local ActionButtonX			= 22;		--Where do action buttons start
local ActionButtonYPadding	= 155;
local ActionButtonWidth		= 32;		--How big are they?
local ActionButtonHeight	= 32;
local ActionButtonPadding	= 2;		--How much padding between them?
local ActionButtonIcons		= {
	Material( "itemforge/inventory/useicon" ),
	Material( "itemforge/inventory/consumeicon" ),
	Material( "itemforge/inventory/holdicon" ),
	Material( "itemforge/inventory/combineicon" ),
	Material( "itemforge/inventory/dropicon" ),
	Material( "itemforge/inventory/releaseicon" )
}




--Creation, removal




--[[
* CLIENT
* Event

Sets the initial size of the inventory and creates the inventory's subpanels / controls.
]]--
function PANEL:Init()
	--Create close button
	self.CloseButton = vgui.Create( "DSysButton", self );
	self.CloseButton:SetType( "close" );
	self.CloseButton:SetSize( CloseButtonWidth, CloseButtonHeight );
	self.CloseButton.DoClick = function( self ) self:GetParent():Close() end
	
	--Create size limit icon
	self.SizeLimIcon = vgui.Create( "ItemforgeSizeIcon", self );
	self.SizeLimIcon:SetVisible( false );
	
	--Create weight bar
	self.WeightBar = vgui.Create( "ItemforgePercentBar", self );
	
	--Create inventory slots control
	self.Slots = vgui.Create( "ItemforgeInventorySlots", self );
	
	--Create Action Buttons
	self.ActionButtons = {};
	
	--Use
	self.ActionButtons[1] = vgui.Create( "ItemforgeImageButton", self );
	self.ActionButtons[1]:SetSize( ActionButtonWidth, ActionButtonHeight );
	self.ActionButtons[1]:SetIcon( ActionButtonIcons[1] );
	self.ActionButtons[1].DoClick = function( self ) self:GetParent():PlayerUseItem() end
	
	--Consume
	self.ActionButtons[2] = vgui.Create( "ItemforgeImageButton", self );
	self.ActionButtons[2]:SetSize( ActionButtonWidth, ActionButtonHeight );
	self.ActionButtons[2]:SetIcon( ActionButtonIcons[2] );
	self.ActionButtons[2].DoClick = function( self ) LocalPlayer():PrintMessage( HUD_PRINTTALK, "This has been removed." ); end
	
	--Hold
	self.ActionButtons[3] = vgui.Create( "ItemforgeImageButton", self );
	self.ActionButtons[3]:SetSize( ActionButtonWidth, ActionButtonHeight );
	self.ActionButtons[3]:SetIcon( ActionButtonIcons[3] );
	self.ActionButtons[3].DoClick = function( self ) self:GetParent():PlayerHoldItem() end
	
	--Combine
	self.ActionButtons[4] = vgui.Create( "ItemforgeImageButton", self );
	self.ActionButtons[4]:SetSize( ActionButtonWidth, ActionButtonHeight );
	self.ActionButtons[4]:SetIcon( ActionButtonIcons[4] );
	
	--Drop
	self.ActionButtons[5] = vgui.Create( "ItemforgeImageButton", self );
	self.ActionButtons[5]:SetSize( ActionButtonWidth, ActionButtonHeight );
	self.ActionButtons[5]:SetIcon( ActionButtonIcons[5] );
	
	--Resize button
	self.ResizeButton = vgui.Create( "DSysButton", self );
		self.ResizeButton:SetSize( 16, 16 );
		self.ResizeButton:SetType( "grip" );
		self.ResizeButton:SetDrawBackground( false );
		self.ResizeButton:SetDrawBorder( false );
		self.ResizeButton:SetCursor( "sizenwse" );
		self.ResizeButton.OnMousePressed = function( self )
			local pnlParent = self:GetParent();
			local x, y = pnlParent:CursorPos();
			pnlParent:StartResize( x, y );
		end
		self.ResizeButton.OnMouseReleased = function( self )
			local pnlParent = self:GetParent();
			if pnlParent.Resizing then return pnlParent:StopResize() end
		end
		

	--Enable cursor while this is up
	self:MakePopup();
	self:SetAutoDelete( true );

	--Set inital size
	self:SetSize( self:GetColRowSize( DefaultColumns, DefaultRows ) );
end

--[[
* CLIENT

Removes the panel.
If this panel was observing an inventory, we unregister this panel.
]]--
function PANEL:RemoveAndCleanUp()
	--Remove & clean up slots
	self.Slots:RemoveAndCleanUp();

	local inv = self:GetInventory();
	if inv then
		self.CloseOnUnregister = false;
		inv:UnregisterObserver( self );
	end
	
	self:Remove();
end




--Inventory registration / updating




--[[
* CLIENT

Sets the inventory this panel should display.

If this is successful, will automatically set the slots to use the same inventory.

inv is an optional inventory you want the panel to display.
	If inv is nil / not given, no inventory will be displayed.
]]--
function PANEL:SetInventory( inv )
	--Do nothing if this is the same inventory we're already using, or if it isn't, unregister from the existing inventory
	local invCurrent = self:GetInventory();
	if		inv == invCurrent	then return;
	elseif	invCurrent			then self.CloseOnUnregister = false; invCurrent:UnregisterObserver( self ); self.CloseOnUnregister = true;
	end

	if inv == nil then return end
	return inv:RegisterObserver( self );
end

--[[
* CLIENT

Returns the inventory this panel is displaying.
]]--
function PANEL:GetInventory( inv )
	if self.Inventory && !self.Inventory:IsValid() then
		self.Inventory = nil;
	end
	return self.Inventory;
end

--[[
* CLIENT
* Event

Runs when this panel is registered with an inventory.
Cancels the registration if this panel already has an inventory.
]]--
function PANEL:OnRegister( inv )
	if self:GetInventory() then return false end
	
	--Set our inventory, tell slots to do same
	self.Inventory = inv;
	self.Slots:SetInventory( inv );

	self:Update( inv );

	return true;
end

--[[
* CLIENT
* Event

Runs when this panel is unregistered from it's inventory.
Closes the inventory when this happens.
]]--
function PANEL:OnUnregister( inv )
	if self:GetInventory() != inv then return end
	
	--Set our inventory to nil, tell slots to do same
	self.Inventory = nil;
	self.Slots:SetInventory( nil );

	if self.CloseOnUnregister then self:Close() end
end

--[[
* CLIENT
* Event

This runs when the panel receives an update from the inventory it's registered to.
]]--
function PANEL:Update( inv )
	if self:GetInventory() != inv then return end
	
	--Set titlebar text
	self.TitleText = inv:GetTitle()
	
	--Set size icon
	local iSize = inv:GetSizeLimit();
	if iSize > 0 then
		self.SizeLimIcon:SetVisible( true );
		self.SizeLimIcon:SetIconSize( iSize );
	else
		self.SizeLimIcon:SetVisible( false );
	end
	
	--Set weight bar
	self:SetWeightMeter( inv:GetWeightStored(), inv:GetWeightCapacity() );
end




--Mouse and associated events




--[[
* CLIENT
* Event

When the mouse is pressed, a drag begins if it was pressed over the title bar or the circular icon.
]]--
function PANEL:OnMousePressed()
	--Where is the cursor relative to the top-left corner of this panel
	local iCursorX, iCursorY = self:CursorPos();

	--Used to get the distance between the mouse and the center of the circle
	local fXOffset = iCursorX - CircleCenterX;
	local fYOffset = iCursorY - CircleCenterY;

	if		( iCursorX >= TitleX && iCursorX < TitleX + TitleStartCapWidth + self.TitleBarWidth + TitleEndCapWidth &&
			  iCursorY >= TitleY && iCursorY < TitleY + TitleDisplayHeight ) ||
			( fXOffset * fXOffset + fYOffset * fYOffset <= CircleRadius * CircleRadius ) then

		self:StartDrag( iCursorX, iCursorY );

	end
end

--[[
* CLIENT
* Event

When the mouse is released, if a drag is in progress, it stops.
]]--
function PANEL:OnMouseReleased()
	if self.Dragging then return self:StopDrag() end
end

--[[
* CLIENT
* Event

If a drag is in progress, moves the window to where the cursor is.
]]--
function PANEL:Think()
	if		self.Dragging then return self:DragThink()
	elseif	self.Resizing then return self:ResizeThink()
	end
end




--Layout and paint related




--[[
* CLIENT

Creates a rectangular, 2D polygon meant to be displayed on the screen.

x1, y1 are the coordinates of the rectangle's upper left corner.
x2, y2 are the coordinates of the rectangle's bottom right corner.
xTile should be the # of times the texture is tiled left-to-right.
yTile should be the # of times the texture is tiled top-to-bottom.
]]--
local function MakeRectPoly( x1, y1, x2, y2, xTile, yTile )
	local u = ( ( x2 - x1 ) / xTile );
	local v = ( ( y2 - y1 ) / yTile );
	return {
		{ x = x1,	y = y1,		u = 0,	v = 0 },
		{ x = x2,	y = y1,		u = u,	v = 0 },
		{ x = x2,	y = y2,		u = u,	v = v },
		{ x = x1,	y = y2,		u = 0,	v = v },
	};
end

--[[
* CLIENT
* Event

Runs when the panel's size changes.
Repositions and resizes the sub-panels.
]]--
function PANEL:PerformLayout()
	local w, h = self:GetSize();

	--We need to resize the rectangular polygons for the background / border every time the window is resized
	self.BackgroundVerts	= MakeRectPoly( BackgroundX,				BackgroundY,				w,							h,								BackgroundTileWidth,	BackgroundTileHeight );
	self.TopBorderVerts		= MakeRectPoly( BackgroundX + CornerWidth,	BackgroundY,				w - CornerWidth,				BackgroundY + BorderWidth,		BorderHeight,			BorderWidth );
	self.BottomBorderVerts	= MakeRectPoly( BackgroundX + CornerWidth,	h - BorderWidth,				w - CornerWidth,				h,								BorderHeight,			BorderWidth );
	self.LeftBorderVerts	= MakeRectPoly( BackgroundX,				BackgroundY + CornerHeight,	BackgroundX + BorderWidth,	h - CornerHeight,				BorderWidth,			BorderHeight );
	self.RightBorderVerts	= MakeRectPoly( w - BorderWidth,				BackgroundY + CornerHeight,	w,							h - CornerHeight,				BorderWidth,			BorderHeight );
	
	self.TitleBarWidth = self:GetWide() - TitleX - TitleStartCapWidth - TitleEndCapWidth;

	self.CloseButton:SetPos( w - CloseButtonWidth - CloseButtonPadding, CloseButtonY );
	self.SizeLimIcon:SetPos( SizeLimIconX, SizeLimIconY );
	self.WeightBar:SetPos( WeightBarX, WeightBarY );
	self.Slots:SetPos( SlotsX, SlotsY );
	self.Slots:SetSize( w - SlotsX - SlotsXMargin, h - SlotsY - SlotsYMargin );

	local iSpacing = ActionButtonWidth + ActionButtonPadding;
	local iActionButtonY = h - ActionButtonYPadding;
	self.ActionButtons[1]:SetPos( ActionButtonX,					iActionButtonY );
	self.ActionButtons[2]:SetPos( ActionButtonX + (     iSpacing ), iActionButtonY );
	self.ActionButtons[3]:SetPos( ActionButtonX + ( 2 * iSpacing ), iActionButtonY );
	self.ActionButtons[4]:SetPos( ActionButtonX + ( 3 * iSpacing ), iActionButtonY );
	self.ActionButtons[5]:SetPos( ActionButtonX + ( 4 * iSpacing ), iActionButtonY );
	self.ResizeButton:SetPos( self:GetWide() - 20, self:GetTall() - 20 );
end

--[[
* CLIENT
* Event

Draws the inventory.
This is a custom, highly graphical inventory, and does a LOT of drawing.
It draws the inventory background, the window's borders, corners, the circular icon, title bar, and weight meter text.
]]--
function PANEL:Paint()
	surface.SetDrawColor( 255, 255, 255, 255 );
	
	--Background
	surface.SetMaterial( BackgroundMat );
	surface.DrawPoly( self.BackgroundVerts );
	
	self:DrawTitleBar();
	self:DrawWeightText();
	self:DrawItemDescription();

	self:DrawBorders();

	return true;
end

--[[
* CLIENT

Draws the title bar and title text.
]]--
function PANEL:DrawTitleBar()
	--Title start cap
	surface.SetMaterial( TitleMats[1] );
	surface.DrawTexturedRect( TitleX, TitleY, TitleStartCapWidth, TitleHeight );
	
	--Title Bar
	surface.SetMaterial( TitleMats[2] );
	surface.DrawTexturedRect( TitleX2, TitleY, self.TitleBarWidth, TitleHeight );
	
	--Title end cap
	surface.SetMaterial( TitleMats[3] );
	surface.DrawTexturedRect( TitleX2 + self.TitleBarWidth, TitleY, TitleEndCapWidth, TitleHeight );
	
	--Title text
	if !self:GetInventory() then return end
	
	surface.SetFont( "ItemforgeInventoryTitle" );
	surface.SetTextColor( TitleTextColor.r, TitleTextColor.g, TitleTextColor.b, TitleTextColor.a );
	surface.SetTextPos( TitleTextX, TitleTextY );
	surface.DrawText( self.TitleText );
end

--[[
* CLIENT

Draws the weight text, which indicates how much more weight can be stored in the inventory. 
]]--
function PANEL:DrawWeightText()
	if !self.WeightBar:IsVisible() then return end
	
	surface.SetFont( "ItemforgeInventoryFont" );
	surface.SetTextColor( WeightLabelTextColor.r, WeightLabelTextColor.g, WeightLabelTextColor.b, WeightLabelTextColor.a );
	surface.SetTextPos( WeightLabelX, WeightLabelY );
	surface.DrawText( self.WeightText );
end

--[[
* CLIENT

Draws the description text for the selected item (if any item is selected).
]]--
function PANEL:DrawItemDescription()
	local itemSelected = self.Slots:GetLastSelectedItem();
	if itemSelected then draw.DrawText( itemSelected:GetName().."\n"..itemSelected:GetDescription(), "DefaultSmall", NameLabelX, self:GetTall() - NameLabelPadding, NameLabelColor, TEXT_ALIGN_LEFT ); end
end

--[[
* CLIENT

Draws the inventory window's borders and border corners.
]]--
function PANEL:DrawBorders()
	--Right border
	surface.SetMaterial( BorderMats[1] );
	surface.DrawPoly( self.RightBorderVerts );
	
	--Top border
	surface.SetMaterial( BorderMats[2] );
	surface.DrawPoly( self.TopBorderVerts );
	
	--Left border
	surface.SetMaterial( BorderMats[3] );
	surface.DrawPoly( self.LeftBorderVerts );
	
	--Bottom border
	surface.SetMaterial( BorderMats[4] );
	surface.DrawPoly( self.BottomBorderVerts );

	--SW corner
	surface.SetMaterial( CornerMats[1] );
	surface.DrawTexturedRect( BackgroundX, self:GetTall() - CornerHeight, CornerWidth, CornerHeight );
	
	--SE corner
	surface.SetMaterial( CornerMats[2] );
	surface.DrawTexturedRect( self:GetWide() - CornerWidth, self:GetTall() - CornerHeight, CornerWidth, CornerHeight );

	--NE corner
	surface.SetMaterial( CornerMats[3] );
	surface.DrawTexturedRect( self:GetWide() - CornerWidth, BackgroundY, CornerWidth, CornerHeight );

	--Circle in the NW corner
	self:DrawCircle();
end

--[[
* CLIENT

Draws the inventory window's circle, including the inventory icon.
]]--
function PANEL:DrawCircle()
	--Background
	surface.SetMaterial( CircleMats[1] );
	surface.DrawTexturedRect( CircleX, CircleY, CircleWidth, CircleHeight );

	--Icon
	local inv = self:GetInventory();
	if inv then
		local matIcon = inv:GetIcon();
		if matIcon then
			surface.SetMaterial( matIcon );
			surface.DrawPoly( CircleVerts );
		end
	end

	--Border (obscures any rough edges on icon)
	surface.SetMaterial( CircleMats[2] );
	surface.DrawTexturedRect( CircleX, CircleY, CircleWidth, CircleHeight );
end




--Miscellaneous functions




--[[
* CLIENT

Runs when the close button is pressed.
Removes and cleans up the panel.
]]--
function PANEL:Close()
	self:RemoveAndCleanUp();
end

--[[
* CLIENT

Sets the weight meter.
This sets the weight label and weight bar.

iWeight should be the total weight of all items in the inventory.
iMax should be the capacity of the inventory.
	If this is 0, the weight bar and weight text are hidden,
	because the function they serve to the user is now irrevelent.
]]--
function PANEL:SetWeightMeter( iWeight, iMax )
	if !self.WeightBar then return end
	
	if iMax > 0 then
		self.WeightBar:SetVisible( true );
		self.WeightBar:SetBarRatio( 1 - iWeight / iMax );		--Bar is full when inventory is empty.
		local iFree = iMax - iWeight;
		if iMax >= 1000 then	self.WeightText = ( 0.001 * iFree ).."kg/"..( 0.001 * iMax ).."kg"
		else					self.WeightText = iFree.."g/"..iMax.."g"
		end

	else
		self.WeightBar:SetVisible( false );
		self.WeightBar:SetBarRatio( 1 );
		self.WeightText = "";
	end
end

--Drag related

--[[
* CLIENT

Called to start a drag on this inventory window.
iCursorX and iCursorY are the coordinates that this window will center beneath the cursor.
	These coordinates should be relative to the top-left corner of the window.
]]--
function PANEL:StartDrag( iCursorX, iCursorY )
	self.MouseDownX = iCursorX;
	self.MouseDownY = iCursorY;

	self:MouseCapture( true );
	self.Dragging = true;
end

--[[
* CLIENT
* Event

Called every frame a drag is in progress.
]]--
function PANEL:DragThink()
	local iX = math.Clamp( gui.MouseX() - self.MouseDownX, DragLeftMargin, surface.ScreenWidth() - DragRightMargin );
	local iY = math.Clamp( gui.MouseY() - self.MouseDownY, DragTopMargin, surface.ScreenHeight() - DragBottomMargin );
	self:SetPos( iX, iY );
end

--[[
* CLIENT

Stops a drag if one is in progress.
]]--
function PANEL:StopDrag()
	if !self.Dragging then return end

	self:MouseCapture( false );
	self.Dragging = false;
end




--Resize related




--[[
* CLIENT

Called to start a drag on this inventory window.
iCursorX and iCursorY are the coordinates that this window will center beneath the cursor.
	These coordinates should be relative to the top-left corner of the window.
]]--
function PANEL:StartResize( iCursorX, iCursorY )
	self.MouseDownX = self:GetWide() - iCursorX;
	self.MouseDownY = self:GetTall() - iCursorY;

	self.ResizeButton:MouseCapture( true );
	self.Resizing = true;
end

--[[
* CLIENT
* Event

Called every frame a resize is in progress.
]]--
function PANEL:ResizeThink()
	local iCursorX, iCursorY = self:CursorPos();
	local iOldWidth, iOldHeight = self:GetSize();

	local iNewWidth, iNewHeight = self:GetIdealSnapSize( iCursorX + self.MouseDownX, iCursorY + self.MouseDownY );

	iNewWidth = math.max( iNewWidth, MinWidth );
	iNewHeight = math.max( iNewHeight, MinHeight );
	
	--Has the panel's size changed?
	if iOldWidth == iNewWidth && iOldHeight == iNewHeight then return end

	self:SetSize( iNewWidth, iNewHeight );
end

--[[
* CLIENT

Stops a resize if one is in progress.
]]--
function PANEL:StopResize()
	if !self.Resizing then return end

	self.ResizeButton:MouseCapture( false );
	self.Resizing = false;
end

--[[
* CLIENT

Give a width and height you are considering using for this panel, and this function
will return a width and height rounded downward, such that the inventory window's slots have an ideal width / height.
]]--
function PANEL:GetIdealSnapSize( iWidth, iHeight )
	local iSlotsWidth, iSlotsHeight = self.Slots:GetIdealSnapSize( iWidth - SlotsX - SlotsXMargin, iHeight - SlotsY - SlotsYMargin );

	return SlotsX + iSlotsWidth  + SlotsXMargin,
		   SlotsY + iSlotsHeight + SlotsYMargin;
end

--[[
* CLIENT

Returns the size the panel needs to be (in pixels) to display this many columns and rows of slots.
Includes enough space to display a scrollbar on the slots panel.
]]--
function PANEL:GetColRowSize( iColumns, iRows )
	local iSlotsWidth, iSlotsHeight = self.Slots:GetColRowSize( iColumns, iRows );
	return SlotsX + iSlotsWidth  + SlotsXMargin,
		   SlotsY + iSlotsHeight + SlotsYMargin;
end



--Action button related




--[[
* CLIENT

Makes the player use the selected item.
]]--
function PANEL:PlayerUseItem()
	local item = self.Slots:GetLastSelectedItem();
	if !item then return false end
	
	item:Use( LocalPlayer() );
end

--[[
* CLIENT

Makes the player hold the selected item.
]]--
function PANEL:PlayerHoldItem()
	local item = self.Slots:GetLastSelectedItem();
	if !item then return false end
	
	item:PlayerHold( LocalPlayer() );
end

vgui.Register( "ItemforgeInventory", PANEL, "Panel" );