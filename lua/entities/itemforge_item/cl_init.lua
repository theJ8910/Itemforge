--[[
itemforge_item
CLIENT

This entity is an 'avatar' of an item. When on the ground, this entity represents that item.
]]--

include( "shared.lua" );

language.Add( "itemforge_item", "Item" );

ENT.DragPanelName		= "ItemforgeItemSlot";	--When this entity is dragged, this type of panel will be created for the drag image
ENT.DragPanelWidth		= 64;					--The drag image will be this wide/tall
ENT.DragPanelHeight		= 64;

ENT.HasInitialized		= false;				--This will be true if the entity has already been initialized, or false if it hasn't.
ENT.MouseOver			= false;				--Is the mouse hovering over this entity?
ENT.LeftPressed			= false;				--Is the left mouse pressed down on this entity?
ENT.RightPressed		= false;				--Is the right mouse pressed down on this entity?

local ItemEvents		= {};					--Item events are ENT events that call when an item is set
local ItemlessEvents	= {};					--Itemless events are ENT events that call when an item is not set
local ItemlessEntities	= {};					--ItemlessEntities is a table of Itemforge entities that haven't been bound to an item clientside yet.

--[[
* CLIENT
* Event

Clear the item's association to this entity if it's removed clientside
]]--
function ENT:OnRemove()
	--We're removing the entity right now
	self.BeingRemoved = true;
	
	--Clear the one-way connection between entity and item
	local item = self:GetItem();
	if !item then return true end
	self:SetItem( nil );
	
	--Clear the item's connection to the entity (the item "forgets" that this was it's entity)
	item:ToVoid( false, self.Entity, nil, false );
	
	return true;
end

--[[
* CLIENT
* Event

Runs when the entity needs to be drawn, and is not translucent. Passes responsibility for this task to the item.
If no item has been acquired clientside, then we'll do the default draw instead.
]]--
function ItemlessEvents:Draw()
	self:DrawModel();
	if self.IsWire then Wire_Render( self ) end	--WIRE
end
function ItemEvents:Draw()
	self:GetItem():Event( "OnDraw3D", nil, self, false );
	if self.IsWire then Wire_Render( self ) end	--WIRE
end

--[[
* CLIENT
* Event

Runs when the entity needs to be drawn, and is translucent. Passes responsibility for this task to the item.
If no item has been acquired clientside, then we'll do the default draw instead.
]]--
function ItemlessEvents:DrawTranslucent()
	self:DrawModel();
	if self.IsWire then Wire_Render( self ) end	--WIRE
end
function ItemEvents:DrawTranslucent()
	self:GetItem():Event( "OnDraw3D", nil, self, true );
	if self.IsWire then Wire_Render( self ) end			--WIRE
end

--[[
* CLIENT
* Event
* WIRE

THIS EVENT IS SHARED but we only use it clientside
]]--
function ENT:Think()
	if self.IsWire then self["BaseWireEntity"].Think( self ); end
end

--[[
* CLIENT
* Event

When an object is dropped on this entity (with Itemforge UI's drag/drop system), this function runs.

Returns false if this entity cannot accept this object.
Returns true if the entity handled the dropped object.
]]--
function ENT:OnDropHere( vDragObject )
	--We want to make two items interact - this entity's item and the dropped panel's item.
	
	--Does this entity have an item set yet?
	local item = self:GetItem();
	if !item then return false end
	
	--Can the drag object hold an item?
	local fnGetItem = vDragObject.GetItem;
	if !IF.Util:IsFunction( fnGetItem ) then return false end
	
	--Does the drag object have an item set, and is it different from this item?
	local s, r = pcall( fnGetItem, vDragObject );
	if !s then ErrorNoHalt( "Itemforge Item Entity: Error calling \"GetItem\" on drag object "..tostring( vDragObject )..": "..r.."\n" ); return false;
	elseif r && r != item then
		if item:Event( "OnDragDropHere", true, r ) then
			r:Event( "OnDragDropToItem", nil, item );
		end
	end
	
	return true;
end

--[[
* CLIENT
* Event

This event is called by Itemforge's UI when the user presses his mouse while it's hovering over this entity.
	
eMC is the mouse-code. It identifies what mouse button was pressed. This will be a MOUSE_ enum: MOUSE_LEFT, MOUSE_RIGHT, etc.
iX and iY is the position on the screen the user pressed the mouse at.
traceRes is the screen-to-world trace results of this event.
]]--
function ENT:OnMousePressed( eMC, iX, iY, traceRes )
	if !self.MouseOver then return end

	if		eMC == MOUSE_LEFT	then
		self.LeftPressed = true;
		self:MouseCapture( true );

		self:ExpectDrag();

	elseif	eMC == MOUSE_RIGHT	then
		self.RightPressed = true;
		self:MouseCapture( true );
		return;
	end
end

--[[
* CLIENT
* Event

This event is called by Itemforge's UI when the user releases his mouse while it's hovering over this entity.
	
eMC is the mouse-code. It identifies what mouse button was released. This will be a MOUSE_ enum: MOUSE_LEFT, MOUSE_RIGHT, etc.
iX and iY is the position on the screen the user released the mouse at.
traceRes is the screen-to-world trace results of this event.
]]--
function ENT:OnMouseReleased( eMC, iX, iY, traceRes )
	if		self.RightPressed && eMC == MOUSE_RIGHT	then
		self.RightPressed = false;

		if self.MouseOver then
			local item = self:GetItem();
			if item then item:ShowMenu( iX, iY ) end
		end
	elseif	self.LeftPressed && eMC == MOUSE_LEFT	then
		self.LeftPressed = false;

		--If we were expecting a drag, forget it
		self:ForgetDrag();

		--Ignore clicks if we released while the mouse wasn't overhead, or if the mouse was released while dragging
		if self.MouseOver && !IF.UI:IsDragging() then
			--Call this entity's DoClick
			self:DoClick();
		end
	end

	if !self.LeftPressed && !self.RightPressed then self:MouseCapture( false ); end
end

--[[
* CLIENT
* Event

Called when the entity is left-clicked.
Maybe this would be good for an item event or something.
]]--
function ENT:DoClick()
	--DEBUG
	Msg( tostring(self).." clicked\n" );
end

--[[
* CLIENT
* Event

We keep track of whether or not the mouse is hovering this entity.
Additionally, Itemforge's UI swaps the current drop object to this entity.
]]--
function ENT:OnCursorEntered()
	self.MouseOver = true;

	IF.UI:SetDropObject( self.Entity );
end

--[[
* CLIENT
* Event

We keep track of whether or not the mouse is hovering this entity.
Additionally, Itemforge's UI clears this entity as the current drop object (because the mouse is no longer hovering it).
]]--
function ENT:OnCursorExited()
	self.MouseOver = false;
	IF.UI:ClearDropObject( self.Entity );

	if self:IsDragExpected() then
		self:Drag();
	end
end

--[[
* CLIENT

Calls when a drag begins (override this if you want it to do something different)
]]--
function ENT:OnDragStart()
	
end

--[[
* CLIENT
* Event

Calls when a drag involving this entity was cancelled (override this if you want it to do something different).
Calls before OnDragEnd.
]]--
function ENT:OnDragCancel()

end

--[[
* CLIENT

Calls when a drag ends (override this if you want it to do something different)
]]--
function ENT:OnDragEnd()
	
end

--[[
* CLIENT
* Event

Occurs if a panel is dropped in the world (override this if you want it to do something different)
]]--
function ENT:OnDropInWorld( traceRes )
	local droppedItem = self:GetItem();
	if !droppedItem then return false end
	
	droppedItem:Event( "OnDragDropToWorld", nil, traceRes );
end

--[[
* CLIENT
* Event

This function is called to drag the entity's item.
]]--
function ENT:Drag()
	self:ForgetDrag();
	
	self:MouseCapture( false );
	self.LeftPressed = false;
	self.RightPressed = false;

	IF.UI:Drag( self, 0.5 * self.DragPanelWidth, 0.5 * self.DragPanelHeight );
end

--[[
* CLIENT

Turns mouse captures involving this entity on / off
]]--
function ENT:MouseCapture( bCapture )
	IF.UI:MouseCapture( self, bCapture );
end

--[[
* CLIENT

This function is run if a drag is expected to start soon.
]]--
function ENT:ExpectDrag()
	self.DragExpected = true;
end

--[[
* CLIENT

Returns true if the entity is expecting a drag to start soon, false otherwise
]]--
function ENT:IsDragExpected()
	return self.DragExpected;
end

--[[
* CLIENT

If a drag is expected, makes it forget about it
]]--
function ENT:ForgetDrag()
	self.DragExpected = false;
end

--[[
* CLIENT
* Event

Called by Itemforge UI after it allows this entity to be dragged.
This function should create and return a panel to be displayed underneath the user's cursor.
]]--
function ENT:CreateDragImage()
	local pnlDrag = vgui.Create( self.DragPanelName );
	pnlDrag:MakePopup();
	pnlDrag:SetSize( self.DragPanelWidth, self.DragPanelHeight );
	pnlDrag:SetItem( self:GetItem() );
	pnlDrag:SetMouseInputEnabled( false );

	return pnlDrag;
end

--[[
* CLIENT

Reconfigures the ENT to use Itemless events
]]--
function ENT:SwapToItemlessEvents()
	for k, v in pairs( ItemlessEvents ) do
		self[k] = v;
	end
end

--[[
* CLIENT

Reconfigures the ENT to use Item events
]]--
function ENT:SwapToItemEvents()
	for k, v in pairs( ItemEvents ) do
		self[k] = v;
	end
end

--Calling this here makes the class itself default to itemless events
ENT:SwapToItemlessEvents();

--[[
* CLIENT

Registers this entity as having no item.
]]--
function ENT:RegisterAsItemless()
	ItemlessEntities[self] = self;
end

--[[
* CLIENT

Unregisters the entity as having no item.
]]--
function ENT:UnregisterAsItemless()
	ItemlessEntities[self] = nil;
end

hook.Add( "Think", "itemforge_ent_think", function()
	local item;
	for k, v in pairs( ItemlessEntities ) do
			
		if k:IsValid() then
			item = IF.Items:Get( v:GetDTInt( "i" ) );
			if item then	v:SetItem( item )	end

		--This is a necessary cleanup check because unfortunately ENT:Remove() does not indicate the final removal of a weapon.
		--Entities become Itemless on removal, and unintentionally remain in the ItemlessEntities table in the event of real removal.
		else
			ItemlessEntities[k] = nil;
		end

			
	end
end );