--[[
ItemforgeInventorySlots
CLIENT

Creates the ItemforgeInventorySlots VGUI control.
This VGUI control creates a set of slots that display the contents of a given inventory, and a scrollbar to scroll through the inventory's contents.
The number of slots displayed depends on the size of the slots, the amount of padding between them, and the size of this panel.
The slots are ItemforgeItemSlot controls.
This panel can simply display the items, or it can allow selection of the items.
]]--

local PANEL				= {};

PANEL.Scrollbar			= nil;					--DVScrollbar VGUI control belonging to this panel
PANEL.ScrollbarWidth	= 16;					--Width of scrollbar (height is the same as the height of this panel)
PANEL.Inventory			= nil;					--The inventory whose items are currently being displayed on this panel
PANEL.Row				= 0;					--The starting row of items that is being displayed from the inventory.



PANEL.Selections		= nil;					--1..n queue of selected itemids. Oldest selections appear at front (Selections[1]). New selections are added to the back( Selections[size-1] ).
PANEL.SelectedItems		= nil;					--Table of selected items used for fast lookup. Uses item ID for key. SelectedItems[itemid] will be true if that item is selected.
PANEL.SelectionType		= IFUI_SELECT_MULTI;	--How many items can be selected at a time, if any?
PANEL.DragsAllowed		= true;					--Can slots with items in them be dragged?

PANEL.Slots				= nil;					--Panel slots
PANEL.SlotWidth			= 64;					--Size of a single slot (in pixels)
PANEL.SlotHeight		= 64;
PANEL.SlotPaddingX		= 2;					--Padding between slots (in pixels)
PANEL.SlotPaddingY		= 2;

PANEL.SlotsWide			= 0;					--How many slots are displayed, in each row/column? (set automatically by PerformLayout function)
PANEL.SlotsHigh			= 0;



--[[
* CLIENT
* Event

When the panel is created, creates tables to keep track of slot panels and selected items.
Also creates a scrollbar to scroll the slots, starting it off at the top row.
]]--
function PANEL:Init()
	self.Slots = {};
	self.Selections = {};
	self.SelectedItems = {};
	self.Row = 0;
	
	self.Scrollbar = vgui.Create( "DVScrollBarItemforge", self );
end

--[[
* CLIENT

Removes the panel.
If this panel was observing an inventory, we unregister this panel.
]]--
function PANEL:RemoveAndCleanUp()
	--Unregister self from inventory
	local inv = self:GetInventory();
	if inv then	inv:UnregisterObserver( self ) end

	--Clean up slots
	for i = 1, #self.Slots do
		self.Slots[i]:RemoveAndCleanUp();
	end

	self:Remove();
end

--[[
* CLIENT

Give a width and height you are considering using for this panel, and this function
will return a width and height rounded downward, such that the right / bottom edges
of this panel will be right next to a column / row of slots.
]]--
function PANEL:GetIdealSnapSize( iWidth, iHeight )
	return self:GetColRowSize( math.floor( ( iWidth  + self.SlotPaddingX - self.ScrollbarWidth ) / ( self.SlotWidth  + self.SlotPaddingX ) ),
							   math.floor( ( iHeight + self.SlotPaddingY )						 / ( self.SlotHeight + self.SlotPaddingY ) )
							 );
end

--[[
* CLIENT

Returns the size the panel needs to be (in pixels) to display this many columns and rows of slots.
Includes enough space to display a scrollbar on the right side.
]]--
function PANEL:GetColRowSize( iColumns, iRows )
	return iColumns * ( self.SlotWidth	+ self.SlotPaddingX ) - self.SlotPaddingX + self.ScrollbarWidth,
		   iRows	* ( self.SlotHeight + self.SlotPaddingY ) - self.SlotPaddingY;
end

--[[
* CLIENT
* Event

Runs when the panel's size changes (or the layout is otherwise invalidated)
]]--
function PANEL:PerformLayout()
	--Determine space that a single slot will occupy (size of slot + padding)
	local iSlotOccWidth		= self.SlotWidth  + self.SlotPaddingX;
	local iSlotOccHeight	= self.SlotHeight + self.SlotPaddingY;
	
	--Determine how many slots can be displayed (we add some padding onto the side to account for the fact that we only need padding BETWEEN slots)
	local iSlotsWide = math.floor( ( self:GetWide() + self.SlotPaddingX - self.ScrollbarWidth ) / iSlotOccWidth );
	local iSlotsHigh = math.floor( ( self:GetTall() + self.SlotPaddingY ) / iSlotOccHeight );
	
	--[[
	If the number of slots that can be displayed has changed from what it currently is, we add or remove slots as necessary.
	We check because that way this panel can be resized as much as necessary without needlessly removing/creating slots each time
	]]--
	if iSlotsWide != self.SlotsWide || iSlotsHigh != self.SlotsHigh then
		
		local iOldSlots = self.SlotsWide * self.SlotsHigh;
		self.SlotsWide = iSlotsWide;
		self.SlotsHigh = iSlotsHigh;
		
		--Create new slots or reposition existing slots
		local i = 1;
		for y = 0, iSlotsHigh - 1 do
			for x = 0, iSlotsWide - 1 do
				
				if self.Slots[i] == nil then
					local pnlSlot = self:CreateSlot();
					self.Slots[i] = pnlSlot;
				end

				self.Slots[i]:SetPos( iSlotOccWidth * x, iSlotOccHeight * y );
				
				i = i + 1;
			end
		end

		--Remove existing unused slots if necessary
		for x = i, iOldSlots do
			self.Slots[x]:RemoveAndCleanUp();
			self.Slots[x] = nil;
		end

		
	end
	
	self.Scrollbar:SetPos( self:GetWide() - self.ScrollbarWidth, 0 );
	self.Scrollbar:SetSize( self.ScrollbarWidth, self:GetTall() );
	
	--Set up the scrollbar, display the contents of the inventory in the newly created slots
	self:Update( self:GetInventory() );
end




--Inventory registration / updating




--[[
* CLIENT

Sets the inventory whose contents this panel should display.

inv is an optional inventory you want the panel to display.
	If inv is nil / not given, no inventory will be displayed.
]]--
function PANEL:SetInventory( inv )
	--Do nothing if this is the same inventory we're already using, or if it isn't, unregister from the existing inventory
	local invCurrent = self:GetInventory();
	if		inv == invCurrent	then return;
	elseif	invCurrent			then invCurrent:UnregisterObserver( self );
	end

	if inv == nil then return end
	return inv:RegisterObserver( self );
end

--[[
* CLIENT

Returns the inventory this panel is displaying.
Returns nil if no inventory is being displayed.
]]--
function PANEL:GetInventory()
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
	if self.Inventory then return false end
	
	self.Inventory = inv;
	self:Update( inv );
	return true;
end

--[[
* CLIENT
* Event

Runs when this panel is unregistered from it's inventory.
]]--
function PANEL:OnUnregister( inv )
	if self:GetInventory() != inv then return end
	
	--Set our inventory to nil
	self.Inventory = nil;

	self:Update( nil );
end

--[[
* CLIENT

Update the contents of these slots with the given inventory.
If the given inventory is nil, the slots will be closed.
]]--
function PANEL:Update( inv )
	if self.Inventory != inv then return end
	
	--Lets make sure all of our selections are still valid.
	self:ValidateSelectedItems();
	
	--Next, we need to set the scrollbar's ratio (this determines how big the bar is - the number of lines it shows compared to the number of total lines).
	--In order to do that, we need to calculate how many rows of slots can be viewed for this inventory
	
	--At minimum, this will be the number of rows of slots displayed without scrolling
	local iCalcRowsTotal = self.SlotsHigh;
	
	--If an inventory has been given...
	if inv then
		--Then we first need to determine what the last slot of this inventory is
		local i = 0;
		local iMaxSlots = inv:GetMaxSlots();
		--If our inventory has a limited number of slots
		if iMaxSlots > 0 then
			i = iMaxSlots;								--Then we can just set it to the max number of slots (because the last slot == max slots)
		
		--But if it has an unlimited number of slots...
		else
			i = table.maxn( inv.Items ) + self.SlotsWide;		--Then we need to determine the last occupied slot in the inventory (plus an extra row - the extra row is so additional items can be dragged and dropped in case the last row is full).
		end
		
		--Here we'll determine how many rows are between the first slot and the last slot.
		local iRowCount = math.ceil( i / self.SlotsWide );
		
		--If the row count exceeds the rows displayed, we use the row count. 
		if iRowCount > iCalcRowsTotal then iCalcRowsTotal = iRowCount end
	end
	
	self.Scrollbar:SetUp( self.SlotsHigh, iCalcRowsTotal );
	local iRow = self.Row;
	if iRow > iCalcRowsTotal - 1 then
		iRow = iCalcRowsTotal - 1;
	end

	if self.Scrollbar.Enabled then		self.Scrollbar:SetScroll( iRow );
	else								self:Display( 0 );
	end
end


--Slot related




--[[
* CLIENT
* Event

This function runs when a slot is clicked.

self is the slot panel that was clicked.
]]--
local SlotClick = function( self )
	self:GetParent():OnSlotClicked( self );
end

--[[
* CLIENT
* Event

This function runs when a drag object is dropped on a slot.

self is the slot panel that had the other panel dropped on it.
vDragObject is the drag object that the user dropped.

Returns true if the drop was handled, false otherwise
]]--
local SlotDrop = function( self, vDragObject )
	return self:GetParent():OnSlotDrop( self, vDragObject );
end

--[[
* CLIENT
* Event

Does nothing. Returns nothing.
]]--
local SlotProxyDoNothing = function( self ) end

--[[
* CLIENT
* Event

Always returns true.
]]--
local SlotProxyIsValid = function( self ) return true end

--[[
* CLIENT
* Event

Returns the slot proxy's item.
]]--
local SlotProxyGetItem = function( self )
	if self.Item && !self.Item:IsValid() then
		self.Item = nil;
	end
	return self.Item;
end

--[[
* CLIENT
* Event

Creates and returns a drag image.
]]--
local SlotProxyCreateDragImage = function( self )
	local pnlDrag = vgui.Create( self.DragPanelName );
	pnlDrag:MakePopup();
	pnlDrag:SetSize( self.Wide, self.Tall );
	pnlDrag:SetItem( self:GetItem() );
	pnlDrag:SetMouseInputEnabled( false );

	return pnlDrag;
end

--[[
* CLIENT
* Event

Inventory slots need to use proxy objects for drags, rather than using the slots themselves.
This is because the inventory slot's contents can change during a drag, which would cancel the drag.
]]--
local SlotGetDragObject = function( self )
	return {
		["DragPanelName"]	= self.DragPanelName,
		["Wide"]			= self:GetWide(),
		["Tall"]			= self:GetTall(),
		["Item"]			= self:GetItem(),
		["IsValid"]			= SlotProxyIsValid,
		["GetItem"]			= SlotProxyGetItem,
		["CreateDragImage"] = SlotProxyCreateDragImage,
		["OnDragStart"]		= SlotProxyDoNothing,
		["OnDragCancel"]	= SlotProxyDoNothing,
		["OnDragEnd"]		= SlotProxyDoNothing,
		["OnDropInWorld"]	= self.OnDropInWorld,
	};
end

--[[
* CLIENT

Creates and returns a slot panel.
]]--
function PANEL:CreateSlot()
	local pnlSlot = vgui.Create( "ItemforgeItemSlot", self );
	
	pnlSlot:SetSize( self.SlotWidth, self.SlotHeight );
	pnlSlot:SetDraggable( false );
	pnlSlot:SetDroppable( true );
	pnlSlot.DoClick			= SlotClick;
	pnlSlot.OnDropHere		= SlotDrop;
	pnlSlot.GetDragObject	= SlotGetDragObject;
	return pnlSlot;
end

--[[
* CLIENT

Fills the slots with items starting at the given row in the current inventory (first row in the inventory is 0)
]]--
function PANEL:Display( iRow )
	local inv = self:GetInventory();
	if !inv then
		--Close all the slots if there is no inventory
		for i = 1, #self.Slots do
			self.Slots[i]:Close();
		end
		return;
	end
	
	iRow = iRow or 0;
	self.Row = iRow;
	
	local bDragAllowed = self:GetDragsAllowed();

	local iMaxSlots = self.Inventory:GetMaxSlots();
	local iOffset = iRow * self.SlotsWide;
	for i = 1, #self.Slots do
		local n = iOffset + i;
		local pnlSlot = self.Slots[i];
		if n <= iMaxSlots or iMaxSlots == 0 then
			local item = self.Inventory:GetItemBySlot( n );
			pnlSlot:Open();
			pnlSlot:SetItem( item );
			pnlSlot.SlotNum = n;

			pnlSlot:SetDraggable( bDragAllowed && item != nil );
		else
			pnlSlot:Close();
		end
	end
	
	self:DisplaySelectedItems();
end

--[[
* CLIENT

Sets whether or not drags are allowed on the slots.

bAllowed is a true/false. If this is:
	true, drags are allowed.
	false, drags are not allowed.
]]--
function PANEL:SetDragsAllowed( bAllowed )
	local bChange = ( self.DragsAllowed != bAllowed );

	self.DragsAllowed = bAllowed;
	if bChange then self:Display( self.Row ) end
end

--[[
* CLIENT

Returns true if drags are allowed on the slots.
Returns false otherwise.
]]--
function PANEL:GetDragsAllowed()
	return self.DragsAllowed;
end




--[[
Control Feedback
The scrollbar and item slots send feedback to this panel, which is handled here
Additionally, this panel provides feedback to controls on it in this section
]]--

--[[
* CLIENT
* Event

We'll pass mousewheel movements to the scrollbar.
]]--
function PANEL:OnMouseWheeled( iDelta )
	return self.Scrollbar:OnMouseWheeled( iDelta );
end

--[[
* CLIENT
* Event

The scrollbar will call this function when it scrolls.
]]--
function PANEL:OnVScroll( iScrollPosition )
	self:Display( iScrollPosition );
	return true;
end

--[[
* CLIENT
* Event

If a slot is clicked it runs this function.

pnlSlot is the panel that the click happened on.
]]--
function PANEL:OnSlotClicked( pnlSlot )
	local item = pnlSlot:GetItem();
	if !item then return end
	
	self:ToggleSelection( item );
end

--[[
* CLIENT
* Event

If a slot has a drag object dropped on it, this function runs.

pnlSlot is the slot that had the object dropped on it.
vDragObject is the drag object that was dropped.
]]--
function PANEL:OnSlotDrop( pnlSlot, vDragObject )
	
	--If we don't have an inventory set, drag/drops are pointless
	local inv = self:GetInventory();
	if !inv then return false end
	
	--Is the dropped object related to an item?
	local fnGetItem = vDragObject.GetItem;
	if !IF.Util:IsFunction( fnGetItem ) then return false end

	--Does the dropped panel have an item set?
	local s, r = pcall( fnGetItem, vDragObject );
	if		!s then	ErrorNoHalt( "Itemforge UI: GetItem on dropped drag object "..tostring( vDragObject ).." failed: "..r.."\n" ); return false;
	elseif	!r then return false end
	
	local item = pnlSlot:GetItem();
	if item then
		--Call the dragdrop events.
		if item:Event( "OnDragDropHere", true, r ) then
			r:Event( "OnDragDropToItem", nil, item );
		end
	else
		r:Event( "OnDragDropToInventory", nil, inv, pnlSlot.SlotNum );
	end
end


--[[
Relating to selection of items...
]]--

--[[
* CLIENT

Sets the type of item selection allowed by this panel.

eSelType is an IFUI_SELECT_* enum.
	Valid values are IFUI_SELECT_NONE, IFUI_SELECT_SINGLE, and IFUI_SELECT_MULTI.
	If changing to IFUI_SELECT_NONE, all previously selected items are deselected.
	If changing to IFUI_SELECT_SINGLE and multiple items were previously selected, deselects all but one item.
]]--
function PANEL:SetSelectionType( eSelType )
	self.SelectionType = eSelType;

	if		eSelType == IFUI_SELECT_NONE	then	self:DeselectAllItems();
	elseif	eSelType == IFUI_SELECT_SINGLE	then	self:DeselectAllItemsExceptOne();
	end
end

--[[
* CLIENT

Returns the type of slot selection allowed by this panel.

Can return IFUI_SELECT_NONE, IFUI_SELECT_SINGLE, or IFUI_SELECT_MULTI.
]]--
function PANEL:GetSelectionType()
	return self.SelectionType;
end

--[[
* CLIENT

Returns true if the given item is selected.
Returns false otherwise.
]]--
function PANEL:IsItemSelected( item )
	return self.SelectedItems[item:GetID()] != nil;
end

--[[
* CLIENT

Returns true if an item can be selected by this panel.
Returns false if selection is not allowed, a valid item wasn't given, if this panel is not displaying an inventory, or if the item is not in the displayed inventory.
]]--
function PANEL:CanSelectItem( item )
	return ( self:GetSelectionType() != IFUI_SELECT_NONE && IF.Util:IsItem( item ) && self:GetInventory() && item:GetContainer() == self.Inventory );
end

--[[
* CLIENT

Selects an item if it's not selected,
or deselects an item if it is selected
]]--
function PANEL:ToggleSelection( item )
	if !IF.Util:IsItem( item ) then return end
	
	if		self:IsItemSelected( item )		then	self:DeselectItem( item );
	else											self:SelectItem( item );
	end
end

--[[
* CLIENT

Tries to select the given item.
Items must pass the CanSelectItem test above, otherwise they cannot be selected.

If selection type is set to IFUI_SELECT_SINGLE,
then this will deselect the current selection before selecting the new one.

item is the item you want to select.

Returns true if it was selected or was already selected.
Returns false otherwise.
]]--
function PANEL:SelectItem( item )
	if self:IsItemSelected( item ) then return true	 end
	if !self:CanSelectItem( item ) then return false end
	
	--Deselect all other other items if only single select is allowed
	if self:GetSelectionType() == IFUI_SELECT_SINGLE then self:DeselectAllItems() end

	local iItemID = item:GetID();
	self.SelectedItems[iItemID] = item;
	table.insert( self.Selections, iItemID );

	self:DisplaySelectedItems();
	
	return true;
end

--[[
* CLIENT

Deselects a selected item.

item can be an item or an item id. If it's a item id, then the selected item with that ID is removed.
	The reason it can take either is just in case we're deselecting an item that no longer exists.
bDisplay is an optional true/false. If bDisplay is:
	true, nil, or not given, then the selection will display immediately. 
	false, then we won't do DisplaySelectedItems() after deselecting the item (in case you're deselecting a lot at once).
]]--
function PANEL:DeselectItem( item, bDisplay )
	local iItemID = item;
	if !IF.Util:IsNumber( item ) then
		if !IF.Util:IsItem( item ) then return end
		iItemID = item:GetID();
	end
	
	if !self.SelectedItems[iItemID] then return false end

	self.SelectedItems[iItemID] = nil;
	for k, v in ipairs( self.Selections ) do
		if v == iItemID then
			table.remove( self.Selections, k );
			break;
		end
	end
	
	
	if bDisplay != false then self:DisplaySelectedItems() end
end

--[[
* CLIENT

Deselects every selected item.
]]--
function PANEL:DeselectAllItems()
	for k, v in pairs( self.SelectedItems ) do
		self:DeselectItem( k, false );
	end
	
	self:DisplaySelectedItems();
end

--[[
* CLIENT

Deselects every selected item, except for one.
If no items were selected to begin with, things remain this way.
]]--
function PANEL:DeselectAllItemsExceptOne()
	local bFoundFirst = false;
	for k, v in pairs( self.SelectedItems ) do
		if bFoundFirst then		self:DeselectItem( k, false );
		else					bFoundFirst = true;
		end
	end

	self:DisplaySelectedItems();
end

--[[
* CLIENT

Returns the selected item, or if multiple items are selected, returns nil.
Returns nil if nothing is selected.
]]--
function PANEL:GetSelectedItem()
	if self.Selections[2] then return nil end
	return IF.Items:Get( self.Selections[1] );
end

--[[
* CLIENT

Returns the selected item, or if multiple items are selected, returns the first selected item.
Returns nil if nothing is selected.
]]--
function PANEL:GetFirstSelectedItem()
	return IF.Items:Get( self.Selections[1] );
end

--[[
* CLIENT

Returns the selected item, or if multiple items are selected, returns the last selected item.
Returns nil if nothing is selected.
]]--
function PANEL:GetLastSelectedItem()
	return IF.Items:Get( self.Selections[#self.Selections] );
end

--[[
* CLIENT

Returns a table of all the items selected.
The table is 1..n and is sorted in the order items were selected (with older selections appearing first).
The table will be empty if no items are selected.

This is mostly only useful if this panel allows multi-selection.
If the slots only allow single-selection, the table will only contain 1 item if something is selected.
In this case, it's better to just use self:GetSelectedItem().
]]--
function PANEL:GetSelectedItems()
	local t = {};
	for i = 1, #self.Selections do
		t[i] = IF.Items:Get( self.Selections[i] );
	end
	return t;
end

--[[
* CLIENT

Returns how many items are selected.
]]--
function PANEL:HowManySelected()
	return table.Count( self.SelectedItems );
end

--[[
* CLIENT

Turns selection borders on items slots on or off depending
on whether or not the item slot is displaying a selected item
]]--
function PANEL:DisplaySelectedItems()
	local slot, item;
	for i = 1, #self.Slots do
		slot = self.Slots[i];
		item = slot:GetItem();
		
		--If this slot is displaying an item, and it's selected, we draw the border.
		if item && self:IsItemSelected( item ) then		slot:SetDrawBorder( true );
		else											slot:SetDrawBorder( false );
		end
	end
end

--[[
* CLIENT

Checks all of the panel's selected items to make sure they can still be selected
This is necessary because, for example, a selected item can be taken out of the inventory this panel displays
]]--
function PANEL:ValidateSelectedItems()
	--TODO: I don't like having to run validation. I need to identify the cases that selection turns on / off.
	for k, v in pairs( self.SelectedItems ) do
		if !self:CanSelectItem( v ) then self:DeselectItem( k ); end
	end
end

vgui.Register( "ItemforgeInventorySlots", PANEL, "Panel" );