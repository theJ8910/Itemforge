--[[
ItemforgeItemSlot
CLIENT

Creates the ItemforgeItemSlot VGUI control.
This control has four purposes:
	It displays the item on screen, giving the item a chance to do both 3D and 2D drawing inside of this control.
	For inventories, can display selection borders, and has overridable DoClick.
	This panel is a valid drag object (Itemforge UI can drag it)
	This panel is a valid drop object (Itemforge UI allows dragged objects to be dropped here)

This is used in two locations:
	It's displayed in an inventory window to display the contents of an inventory.
	It's displayed in the corner of your screen while you're holding an item as your active weapon.
]]--

local PANEL					= {};
PANEL.Item					= nil;											--This is the item that the slot is set to display.

PANEL.SlotOpen				= true;											--Is this slot open? If it is, it will draw a background, then the set item (if there is one), then the border. If it isn't, it draws a closed slot. This mostly applies to inventory slots.
PANEL.Draggable				= false;										--Can this panel be dragged?
PANEL.Droppable				= false;										--Can this panel have things dropped onto it?
PANEL.ContextMenuAllowed	= true;											--Can you right click the panel to get the displayed item's context menu?
PANEL.ShouldDrawBorder		= false;										--If this is true, a border with the color given below will be drawn around the box (it's selected).

PANEL.DragPanelName			= "ItemforgeItemSlot";							--If this panel is dragged, it creates this type of panel to act as it's drag image

PANEL.Model					= "";											--This is the name of the model being displayed for the panel, will be "" if no model is set
PANEL.ModelPanel			= nil;											--If the item opts to use a model, a model panel will be created for it.

PANEL.MouseOver				= false;										--Is the mouse hovering over this panel?
PANEL.LeftPressed			= false;										--Is the left mouse pressed down on this panel?
PANEL.RightPressed			= false;										--Is the right mouse pressed down on this panel?
PANEL.DragExpected			= false;										--If this is true, whenever the user moves his mouse outside the panel a drag is started. This becomes true when the user presses the mouse down, and false whenever a drag is started OR whenever the user releases his mouse.
PANEL.ClickX				= 0;											--This is the X and Y position on the panel that the user pressed his mouse down at.
PANEL.ClickY				= 0;



local SlotBackground	= Material( "itemforge/inventory/slot"			);	--This is the background image. This material will be drawn before drawing the icon.
local SlotBorder		= Material( "itemforge/inventory/slot_border"	);	--This is the border image. This material will be drawn after drawing the icon.
local SlotClosed		= Material( "itemforge/inventory/closedslot"	);	--This is a closed slot image. This is drawn if the slot is closed.

local BorderColor		= Color( 49,  209, 255, 255 );						--Color of the border, if a border is being drawn
local BorderColorDrop	= Color( 255, 175, 0,   255 );						--Color of the border, if a drag-drop is occuring and we're being moused over

local ModelPanelX		= 0.03125;											--The model panel is at this location on the panel (in the terms of 0-1)... 2 / 64 = 0.03125
local ModelPanelY		= 0.03125;
local ModelPanelW		= 0.9375;											--...at this size (in terms of 0-1). 60 / 64 = 0.9375
local ModelPanelH		= 0.9375;

local vZero				= Vector( 0, 0, 0 );
local vCamDir			= Angle( -45, -45, 0 ):Forward();




--Creation, removal




--[[
* CLIENT
* Event

By default item slots are visible and automatically delete themselves
]]--
function PANEL:Init()
	self:SetVisible( true );
	self:SetAutoDelete( true );
end

--[[
* CLIENT

Removes this panel.
If an item was being displayed by the panel, unregisters the panel from the item.
This will cause the model panel (if one existed) and it's associated entity to be removed immediately.
]]--
function PANEL:RemoveAndCleanUp()
	self:SetItem( nil );
	self:Remove();
end




--Item registration / updating




--[[
* CLIENT

Set the item this panel should display.
This function will fail if the slot is closed.

item is an optional item you want the panel to display.
	If item is nil / not given, no item will be displayed by the slot.
]]--
function PANEL:SetItem( item )
	--Do nothing if this is the same item we're already using, or if it isn't, unregister from the existing item
	local itemCurrent = self:GetItem();
	if		item == itemCurrent then return;
	elseif	itemCurrent			then itemCurrent:UnregisterObserver( self );
	end

	if item == nil then return end
	item:RegisterObserver( self );
end

--[[
* CLIENT

Returns the item this panel is displaying.
Returns nil if no item is set.
]]--
function PANEL:GetItem()
	return self.Item;
end

--[[
* CLIENT
* Event

Runs when this panel is registered with an item.
Cancels the registration if this panel already has an item, or if the panel is closed.
]]--
function PANEL:OnRegister( item )
	if self:GetItem() || !self:IsOpen() then return false end
	
	self.Item = item;

	self:Update( item );
	return true;
end

--[[
* CLIENT
* Event

Runs when this panel is unregistered from it's item.
]]--
function PANEL:OnUnregister( item )
	if self:GetItem() != item then return end
	
	--Set our item to nil
	self.Item = nil;
	
	self:CancelDrag();
	self:Update();
end

--[[
* CLIENT
* Event

This runs when an item registered with this panel updates itself.
]]--
function PANEL:Update( item )
	if		item == nil			   then		self:SetModel( "" ); return;
	elseif	self:GetItem() != item then		return;
	end

	if item:Event( "ShouldUseModelFor2D", true ) then	self:SetModel( item:GetWorldModel() );
	else												self:SetModel( "" );
	end
end




--Open / close slot




--[[
* CLIENT

Opens the slot.
]]--
function PANEL:Open()
	self.SlotOpen = true;
end

--[[
* CLIENT

Closes the slot.
Clears any items, borders, pending drags, etc.
]]--
function PANEL:Close()
	--No item being displayed while the slot is closed
	self:SetItem( nil );
	
	--Pending / current drags can no longer occur, drops are no longer valid
	self:CancelDrag();
	IF.UI:ClearDropObject( self );

	if self.LeftPressed == true || self.RightPressed == true then
		self:MouseCapture( false );

		self.LeftPressed = false;
		self.RightPressed = false;
	end

	self.SlotOpen = false;
end

--[[
* CLIENT

Returns true if the slot is open, false otherwise.
]]--
function PANEL:IsOpen()
	return self.SlotOpen;
end




--Border




--[[
* CLIENT

Turns the selection border on / off.

bDrawBorder is a true/false. If bDrawBorder is:
	true, a blue, pulsating border appears around the slot.
	false, then the border isn't drawn.
]]--
function PANEL:SetDrawBorder( bDrawBorder )
	self.ShouldDrawBorder = bDrawBorder;
end

--[[
* CLIENT

Returns true if the panel is drawing a selection border, and false otherwise.
]]--
function PANEL:GetDrawBorder()
	return self.ShouldDrawBorder;
end




--Context Menu




--[[
* CLIENT

Lets you set whether or not an item's context menu can be accessed by right-clicking the slot.

NOTE: Disallowing the context menu while a menu is open will not close the menu.

bMenuAllowed is a true/false. If bMenuAllowed is:
	true, right clicking the item slot will display the item's context menu.
	false, right clicking the item slot will do nothing.
]]--
function PANEL:SetContextMenuAllowed( bMenuAllowed )
	self.ContextMenuAllowed = bMenuAllowed;
end

--[[
* CLIENT

Returns true if the displayed item's context menu can be accessed by right-clicking the slot.
Returns false otherwise.
]]--
function PANEL:GetContextMenuAllowed()
	return self.ContextMenuAllowed;
end




--Mouse Events




--[[
* CLIENT
* Event

We keep track of whether or not the mouse is hovering this panel.
Additionally, if this slot can have panels dropped onto it, Itemforge's UI swaps the current drop object to this panel.
]]--
function PANEL:OnCursorEntered()
	self.MouseOver = true;
	
	if self:GetDroppable() then IF.UI:SetDropObject( self ) end
end

--[[
* CLIENT
* Event

We keep track of whether or not the mouse is hovering this panel.
Additionally, if this slot can have panels dropped onto it, Itemforge's UI clears this panel as the current drop object (because the mouse is no longer hovering it).

If a drag was pending, it activates when the mouse leaves the slot.
]]--
function PANEL:OnCursorExited()
	self.MouseOver = false;
	IF.UI:ClearDropObject( self );
	
	if self:IsDragExpected() && self:CanDrag() then
		self:Drag();
	end
end

--[[
* CLIENT
* Event

We keep track of left / right mouse presses.

If a left mouse button was pressed down on an open slot,
we expect the panel to be dragged soon.
]]--
function PANEL:OnMousePressed( eMC )
	--Anything we do here doesn't matter if the slot is closed or if the mouse wasn't overhead at the time.
	--The mouseover check is necessary in the case the panel is mouse capturing from a previous button press.
	if !self:IsOpen() || !self.MouseOver then return end
	
	if		eMC == MOUSE_LEFT	then
		self.LeftPressed = true;
		self:MouseCapture( true );

		if self:CanDrag() then	self:ExpectDrag( self:ScreenToLocal( gui.MousePos() ) );  end
		
	elseif	eMC == MOUSE_RIGHT	then
		self.RightPressed = true;
		self:MouseCapture( true );
	end
end

--[[
* CLIENT
* Event

When the right mouse button is released on an open slot, we display a menu for the item it's displaying.
When the left mouse button is released on an open slot, we run the slot's overridable DoClick.
	Additionally, if we were expecting the panel to be dragged, that is cancelled.
]]--
function PANEL:OnMouseReleased( eMC )
	if		self.RightPressed && eMC == MOUSE_RIGHT	then
		self.RightPressed = false;

		if self.MouseOver then
			local item = self:GetItem();
			if item && self:GetContextMenuAllowed() then item:ShowMenu( gui.MousePos() ) end
		end

	elseif	self.LeftPressed && eMC == MOUSE_LEFT	then
		self.LeftPressed = false;

		--If we were expecting a drag, forget it
		self:ForgetDrag();
		
		--Ignore clicks if we released while the mouse wasn't overhead, or if the mouse was released while dragging
		if self.MouseOver && !IF.UI:IsDragging() then
			--Call this panel's overridable DoClick
			local s, r = pcall( self.DoClick, self );
			if !s then ErrorNoHalt( "Itemforge UI: Error calling item slot's DoClick: "..r.."\n" ) end
		end
	end

	if !self.LeftPressed && !self.RightPressed then self:MouseCapture( false ); end
end

--[[
* CLIENT
* Event

Override this to set a click action
]]--
function PANEL:DoClick()
end




--Paint related




--[[
* CLIENT
* Event

Draws the panel
]]--
function PANEL:Paint()
	local iW, iH = self:GetSize();

	if self:IsOpen() then
		local item = self:GetItem();
		
		--Draw slot background
		surface.SetMaterial( SlotBackground );
		surface.SetDrawColor( 255, 255, 255, 255 );
		surface.DrawTexturedRect( 0, 0, iW, iH );
		
		--Draw item in both 3D and 2D
		if item then
			item:Event( "OnDraw2DBack", nil, iW, iH );
			if IsValid( self.ModelPanel ) then self.ModelPanel:Paint( item ) end
			item:Event( "OnDraw2D", nil, iW, iH );
		end
		
		--Draw slot border texture
		surface.SetMaterial( SlotBorder );
		surface.SetDrawColor( 255, 255, 255, 255 );
		surface.DrawTexturedRect( 0, 0, iW, iH );
		
		--If an object is being dragged, we want to know if it's an item being dragged.
		--Not all dragged objects contain items.
		local bValidDrop = false;
		if self.Droppable && self.MouseOver then
			
			local vDragObject = IF.UI:GetDragObject();
			if vDragObject then
				local fn = vDragObject.GetItem;

				if IF.Util:IsFunction( fn ) then
					local s, r = pcall( fn, vDragObject );
					if		!s				then	ErrorNoHalt( "Itemforge UI: \"GetItem\" on dragged object failed: "..r.."\n" );
					elseif	r && r != item	then	bValidDrop = true;
					end
				end
			end

		end
		
		--Draw dragdrop border if an item is being dragged (and of course if we aren't displaying that same item)
		if bValidDrop then
			self:DrawBorder( BorderColorDrop );
		
		--Draw selection border
		elseif self.ShouldDrawBorder == true then
			self:DrawBorder( BorderColor );
		end
	else
		--Draw closed slot
		surface.SetMaterial( SlotClosed );
		surface.SetDrawColor( 255, 255, 255, 255 );
		surface.DrawTexturedRect( 0, 0, iW, iH );
	end
	return true;
end

--[[
* CLIENT

Draws a border.

cColor is the color to draw the border.
]]--
function PANEL:DrawBorder( cColor )
	surface.SetDrawColor( cColor.r, cColor.g, cColor.b, 191.25 + 63.75 * ( math.sin( 5 * CurTime() ) ) );
	
	--Vertical lines
	surface.DrawRect( 0,					0,						2,						self:GetTall() );
	surface.DrawRect( self:GetWide() - 2,	0,						2,						self:GetTall() );
	
	--Horizontal lines
	surface.DrawRect( 2,					0,						self:GetWide() - 4,		2			   );
	surface.DrawRect( 2,					self:GetTall() - 2,		self:GetWide() - 4,		2			   );
end

--[[
* CLIENT
* Event

This is garry's Model Panel paint pretty much, but with comments and slight modifications
]]--
local SlotPaint = function( self, item )
	if ( !IsValid( self.Entity ) ) then return end
	
	local x, y = self:LocalToScreen( 0, 0 );
	
	--Pose the entity for the shot (we ask the item to do that)
	item:Event( "OnPose3D", nil, self.Entity, self );
	
	--Set up the camera and set the screen space that the drawing will occur in
	cam.Start3D( self.vCamPos, ( self.vLookatPos - self.vCamPos ):Angle(), self.fFOV, x, y, self:GetWide(), self:GetTall() );
	cam.IgnoreZ( true );	--We don't want it clipping something in the world on accident
	
	--If we didn't suppress the lighting then things in the game world like environmental light, spotlights, etc would accidentilly light the entity.
	--It's unspoken but everybody assumes the model is floating around in it's own dimension; little do they realize it's sharing the same world space as everything else!
	render.SuppressEngineLighting( true );
	
	--I'm not really sure what a lighting origin is. I guess it's where the light is sampled from in respect to world space when drawing.
	render.SetLightingOrigin( self.Entity:GetPos() );
	
	--Clears the model lighting of any pre-existing lights and sets the light to an ambient value (all values are between 0 and 1)
	render.ResetModelLighting( self.colAmbientLight.r / 255, self.colAmbientLight.g / 255, self.colAmbientLight.b / 255 );
	
	--sets up 7 "directional" lights. You got me on this one. I don't know how source does it's lighting so I'm leaving this in here.
	for i = 0, 6 do
		local col = self.DirectionalLight[i];
		if col then
			render.SetModelLighting( i, col.r / 255, col.g / 255, col.b / 255 );
		end
	end
	
	--We use the item's Draw3D event on _this_ entity!
	item:Event( "OnDraw3D", nil, self.Entity, false );
	
	--Clean up before the frame ends
	render.SuppressEngineLighting( false );
	cam.IgnoreZ( false );
	cam.End3D();
	
	self.LastPaint = RealTime();
end




--Model Panel related




--[[
* CLIENT
* Internal

There should be no reason for a scripter to call this directly.

Sets the 3D model being displayed by the panel.
Creates / removes model panels as necessary.

strModel is the filepath of the model to display.
	Use "" if you don't want a model to be displayed.
]]--
function PANEL:SetModel( strModel )
	if		strModel == ""				then	self:RemoveModelPanel();
	elseif	strModel != self:GetModel()	then	self:CreateModelPanel( strModel );
	end

	self.Model = strModel;
end

--[[
* CLIENT

Returns the filepath of the model this panel is displaying.
Returns "" if the panel isn't currently displaying a model.
]]--
function PANEL:GetModel()
	return self.Model;
end

--[[
* CLIENT
* Internal

There should be no reason for a scripter to call this directly.

Creates a model panel for the slot.
If a model panel already exists, it is replaced by the new one.

strModel is the filepath of the model to create.
]]--
function PANEL:CreateModelPanel( strModel )
	local pnlModel = vgui.Create( "DModelPanel", self );
	
	--We use custom painting
	pnlModel.Paint = SlotPaint;
	pnlModel:SetPaintedManually( true );
	
	--The position and size of the model panel depends on the size of the Item Slot
	local iW, iH = self:GetSize();
	pnlModel:SetPos(  math.floor( ModelPanelX * iW ), math.floor( ModelPanelY * iH ) );
	pnlModel:SetSize( math.floor( ModelPanelW * iW ), math.floor( ModelPanelH * iH ) );
	
	--I don't particularly understand why this wasn't done in the DModelPanel file... it's not like the panel does anything if clicked, but it's blocking my slots regardless.
	pnlModel:SetMouseInputEnabled( false );
	pnlModel:SetKeyboardInputEnabled( false );
	
	--Lastly we'll set the model to the requested model.
	pnlModel:SetModel( strModel );
	
	--If for some reason this didn't work (like the model didn't exist) we just end it here
	local eEntity = pnlModel:GetEntity();
	if !eEntity:IsValid() then
		pnlModel:Remove();
		return false;
	end
	
	--We use the bounding box and some trig to determine what distance the camera needs to be at to see the entire model.
	local vMin, vMax = eEntity:GetRenderBounds();
	
	--[[
	y = mx;
	
	d = [the largest side of the model's bounding box]
	f = [half of the Model Panel Camera's FOV in radians]
	
	y = 0.8 * d;
	m = sin( f ) / cos( f ) = tan( f );
	
	0.8 * d			   = tan( f ) * x;
	0.8 * d / tan( f ) = x;
	]]--
	
	--Position the camera at an interesting angle, at the calculated distance
	pnlModel:SetCamPos( vCamDir * ( 0.8 * ( math.max( vMax.x - vMin.x, vMax.y - vMin.y, vMax.z - vMin.z ) ) / math.tan( math.Deg2Rad( 0.5 * pnlModel:GetFOV() ) ) ) );
	
	--Look at the center of the bounding box (The model will be moved when posed so the center of the bounding box is at 0, 0, 0)
	pnlModel:SetLookAt( vZero );

	--Remove the model panel if we already have one, and replace it with the new one
	self:RemoveModelPanel();
	self.ModelPanel = pnlModel;

	return true;
end

--[[
* CLIENT
* Internal

There should be no reason for a scripter to call this directly.

Removes the model panel if we have one.
]]--
function PANEL:RemoveModelPanel()
	local pnlModel = self:GetModelPanel();
	if !pnlModel then return end
	
	--Remove the model entity immediately
	local eEntity = pnlModel.Entity;
	if eEntity then
		eEntity:Remove();
		pnlModel.Entity = nil;
	end

	pnlModel:Remove()
	self.ModelPanel = nil;
end

--[[
* CLIENT

Returns this panel's DModelPanel.
Returns nil if the slot doesn't have a model panel.
]]--
function PANEL:GetModelPanel()
	if self.ModelPanel && !self.ModelPanel:IsValid() then
		self.ModelPanel = nil;
	end
	return self.ModelPanel;
end




--Drag object related




--[[
* CLIENT

Sets whether or not the panel should be draggable or not.
bDraggable is a true/false. If bDraggable is:
	true, the panel allows itself to be dragged.
	false, then attempts to drags this panel are ignored.
		TODO: Fix it so drags in progress are stopped
]]--
function PANEL:SetDraggable( bDraggable )
	self.Draggable = bDraggable;
	if bDraggable == false then self:CancelDrag(); end
end

--[[
* CLIENT

Returns true if the panel is draggable, false otherwise.
]]--
function PANEL:GetDraggable()
	return self.Draggable;
end

--[[
* CLIENT

Returns true if a drag is currently possible
]]--
function PANEL:CanDrag()
	return self:GetDraggable() && self:IsOpen();
end

--[[
* CLIENT

This function is run if a drag is expected to start soon.

x and y are local coordinates on the panel describing where to
	center the panel over the cursor once the dragdrop starts.
	Usually, a click triggers ExpectDrag and the location the click occured are used for x and y.
]]--
function PANEL:ExpectDrag( x, y )
	self.DragExpected = true;
	self.ClickX, self.ClickY = x, y;
end

--[[
* CLIENT

If a drag is pending, cancel it.
]]--
function PANEL:ForgetDrag()
	self.DragExpected = false;
end

--[[
* CLIENT

Returns true if the panel is expecting a drag to start soon, false otherwise
]]--
function PANEL:IsDragExpected()
	return self.DragExpected;
end

--[[
* CLIENT

Run this function to start a drag/drop operation.
This function should be called some time after an ExpectDrag() and before a ForgetDrag().
]]--
function PANEL:Drag()
	self:ForgetDrag();
	
	self:MouseCapture( false );
	self.LeftPressed = false;
	self.RightPressed = false;

	IF.UI:Drag( self:GetDragObject(), self.ClickX, self.ClickY );
end

--[[
* CLIENT

When a drag starts, this function is called to decide what object will serve as the drag object.

This is usually the panel itself. However, 'inventory slots' panels need to override this and have their slots
use a temporary object instead of the panel itself. This is because the inventory slots are reused to display
other items, and can change to a different item if a user scrolls his mouse while dragging.
]]--
function PANEL:GetDragObject()
	return self;
end

--[[
* CLIENT

If this panel is currently being dragged, cancels the drag.
If a drag is expected to happen soon, forgets it.
]]--
function PANEL:CancelDrag()
	self:ForgetDrag();
	IF.UI:CancelDrag( self );
end

--[[
* CLIENT
* Event

Called by Itemforge UI after it allows this panel to be dragged.
This function should create and return a panel to be displayed underneath the user's cursor.
]]--
function PANEL:CreateDragImage()
	local pnlDrag = vgui.Create( self.DragPanelName );
	pnlDrag:MakePopup();
	pnlDrag:SetSize( self:GetWide(), self:GetTall() );
	pnlDrag:SetItem( self:GetItem() );
	pnlDrag:SetMouseInputEnabled( false );

	return pnlDrag;
end

--[[
* CLIENT

Calls when a drag begins (override this if you want it to do something different)
]]--
function PANEL:OnDragStart()
	
end

--[[
* CLIENT
* Event

Calls when a drag involving this panel was cancelled (override this if you want it to do something different).
Calls before OnDragEnd.
]]--
function PANEL:OnDragCancel()

end

--[[
* CLIENT

Calls when a drag ends (override this if you want it to do something different)
]]--
function PANEL:OnDragEnd()
	
end

--[[
* CLIENT
* Event

Occurs if a panel is dropped in the world (override this if you want it to do something different)
]]--
function PANEL:OnDropInWorld( traceRes )
	local droppedItem = self:GetItem();
	if !droppedItem then return false end
	
	droppedItem:Event( "OnDragDropToWorld", nil, traceRes );
end




--Drop object related




--[[
* CLIENT

Sets whether or not you should be able to drop other panels on this panel.

bDroppable is a true/false. If bDroppable is:
	true, then other panels can be dropped here.
	false, then drops to this panel are ignored.
]]--
function PANEL:SetDroppable( bDroppable )
	self.Droppable = bDroppable;
	if bDroppable == false then
		IF.UI:ClearDropObject( self );
	end
end

--[[
* CLIENT

Returns true if the panel can have things dropped upon it, false otherwise.
]]--
function PANEL:GetDroppable()
	return self.Droppable;
end

--[[
* CLIENT
* Event

Occurs if a drag object is dropped here (override this if you want it to do something different).

Return true if the panel handled the dropped object.
Return false if the panel cannot handle the dropped object.
]]--
function PANEL:OnDropHere( vDragObject )
	return false;
end

vgui.Register( "ItemforgeItemSlot", PANEL, "Panel" );