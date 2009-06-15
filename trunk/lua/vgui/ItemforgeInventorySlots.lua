/*
ItemforgeInventorySlots
CLIENT

Creates the ItemforgeInventorySlots VGUI control.
This VGUI control creates a set of slots that display the contents of a given inventory, and a scrollbar to scroll through the inventory's contents.
The number of slots displayed depends on the size of the slots, the amount of padding between them, and the size of this panel.
The slots are ItemforgeItemSlot controls.
This panel can simply display the items, or it can allow selection of the items.
*/
local PANEL = {}

PANEL.Scrollbar=nil;			--DVScrollbar VGUI control belonging to this panel
PANEL.ScrollbarWidth=16;		--Width of scrollbar (height is the same as the height of this panel)
PANEL.Inventory=nil;			--The inventory whose items are currently being displayed on this panel
PANEL.Row=0;					--The starting row of items that is being displayed from the inventory.



PANEL.SelectedItems=nil;		--Items in the inventory being displayed that are selected by this panel
PANEL.CanSelectItems=true;		--Can items be selected (by clicking slots?)

PANEL.Slots=nil;				--Panel slots
PANEL.SlotWidth=64;				--Size of a single slot
PANEL.SlotHeight=64;
PANEL.SlotPaddingX=2;			--Padding between slots
PANEL.SlotPaddingY=2;

PANEL.SlotsWide=0;				--How many slots are displayed, in each row/column? (set automatically by PerformLayout function)
PANEL.SlotsHigh=0;
--This function runs when a slot is clicked
local SlotClick=function(self)
	self:GetParent():OnSlotClicked(self);
end

--This function runs when a panel is dropped on a slot
local SlotDrop=function(self,panel)
	self:GetParent():OnSlotDrop(self,panel);
end

function PANEL:Init()
	self.Slots={};
	self.SelectedItems={};
	self.Row=0;
	
	--I created a custom scrollbar based off the Derma one, because it didn't have the functionality I needed
	self.Scrollbar=vgui.Create("DVScrollBarItemforge",self);
end


--Runs when the panel's size changes (or the layout is otherwise invalidated)
function PANEL:PerformLayout()
	--Determine space that a single slot will occupy (size of slot + padding)
	local slotOccWidth=self.SlotWidth+self.SlotPaddingX;
	local slotOccHeight=self.SlotHeight+self.SlotPaddingY;
	
	--Determine how many slots can be displayed (we add some padding onto the side to account for the fact that we only need padding BETWEEN slots)
	local sw=math.floor((self:GetWide()+self.SlotPaddingX-self.ScrollbarWidth)/slotOccWidth);
	local sh=math.floor((self:GetTall()+self.SlotPaddingY)/slotOccHeight);
	
	--[[
	If the number of slots that can be displayed has changed from what it currently is, we remove any existing slots and make new ones.
	We check because that way this panel can be resized as much as necessary without needlessly removing/creating slots each time
	]]--
	if sw~=self.SlotsWide or sh~=self.SlotsHigh then
		self.SlotsWide=sw;
		self.SlotsHigh=sh;
		
		--Remove existing slots if necessary
		for k,v in pairs(self.Slots) do
			v:Remove();
		end
		
		--Create new slots
		self.Slots={};
		local i=1;
		for y=0,sh-1 do
			for x=0,sw-1 do
				local slot=vgui.Create("ItemforgeItemSlot",self);
				
				slot:SetPos(x*slotOccWidth,y*slotOccHeight);
				slot:SetSize(self.SlotWidth,self.SlotHeight);
				slot:SetDraggable(false);
				slot:SetDroppable(true);
				slot.DoClick=SlotClick;
				slot.OnDrop=SlotDrop;
				self.Slots[i]=slot;
				i=i+1;
			end
		end
	end
	
	self.Scrollbar:SetPos(self:GetWide()-self.ScrollbarWidth,0);
	self.Scrollbar:SetSize(self.ScrollbarWidth,self:GetTall());
	
	--Set up the scrollbar, display the contents of the inventory in the newly created slots
	self:Update(self:GetInventory());
end

--[[
Relating to fundamental properties of inventory slots control
]]--


--Update the contents of these slots with the given inventory.
--If the given inventory is nil, the slots will be closed.
function PANEL:Update(inv)
	--First we'll set the inventory we're displaying items for here
	if inv && !inv:IsValid() then
		ErrorNoHalt("Itemforge UI: Tried to Update() ItemforgeInventorySlot with an invalid inventory!\n");
		inv=nil;
	end
	
	self.Inventory=inv;
	
	--Then, we'll make sure that all of our selections are still valid.
	self:ValidateSelectedItems();
	
	--Next, we need to set the scrollbar's ratio (this determines how big the bar is - the number of lines it shows compared to the number of total lines).
	--In order to do that, we need to calculate how many rows of slots can be viewed for this inventory
	
	--At minimum, this will be the number of rows of slots displayed without scrolling
	local calcRowsTotal=self.SlotsHigh;
	
	--If an inventory has been given...
	if inv then
		--Then we first need to determine what the last slot of this inventory is
		local i=0;
		
		--If our inventory has a limited number of slots in inventory
		if inv:GetMaxSlots()>0 then
			i=inv:GetMaxSlots();						--Then we can just set it to the max number of slots (because the last slot == max slots)
		
		--But if it has an unlimited number of slots...
		else
			i=table.maxn(inv.Items)+self.SlotsWide;		--Then we need to determine the last occupied slot in the inventory (plus an extra row - the extra row is so additional items can be dragged and dropped in case the last row is full).
		end
		
		--Here we'll determine how many rows are between the first slot and the last slot.
		local rowCount=math.ceil(i/self.SlotsWide);
		
		--If the row count exceeds the rows displayed, we use the row count. 
		if rowCount>calcRowsTotal then calcRowsTotal=rowCount end
	end
	
	self.Scrollbar:SetUp(self.SlotsHigh,calcRowsTotal);
	local row=self.Row;
	if row>calcRowsTotal-1 then
		row=calcRowsTotal-1;
	end
	if self.Scrollbar.Enabled then
		self.Scrollbar:SetScroll(row);
	else
		self:Display(0);
	end
end

--Fills the slots with items starting at the given row in the current inventory (first row in the inventory is 0)
function PANEL:Display(row)
	local inv=self:GetInventory();
	if !inv then
		--Close all the slots if there is no inventory
		for i=1, table.getn(self.Slots) do
			self.Slots[i]:Close();
		end
		return;
	end
	
	local row=(row or 0);
	self.Row=row;
	
	local offset=(row*self.SlotsWide);
	for i=1,table.getn(self.Slots) do
		local n=offset+i;
		if n<=self.Inventory.MaxSlots or self.Inventory.MaxSlots==0 then
			local item=self.Inventory:GetItemBySlot(n);
			self.Slots[i]:Open();
			self.Slots[i]:SetItem(item);
			self.Slots[i].invSlot=n;
			if item then self.Slots[i]:SetDraggable(true); end
		else
			self.Slots[i]:Close();
		end
	end
	
	self:DisplaySelectedItems();
end

--Gets the inventory whose contents are being displayed on this.
function PANEL:GetInventory(inv)
	local i=self.Inventory;
	if i then
		if !i:IsValid() then
			self.Inventory=nil;
			return nil;
		end
		return i;
	end
	return nil;
end




--[[
Control Feedback
The scrollbar and item slots send feedback to this panel, which is handled here
Addtionally, this panel provides feedback to controls on it in this section
]]--

--We'll pass mousewheel movements to the scrollbar
function PANEL:OnMouseWheeled(dlta)
	return self.Scrollbar:OnMouseWheeled(dlta);
end

--The scrollbar will call this function when it scrolls
function PANEL:OnVScroll(offset)
	self:Display(offset);
	return true;
end

--If a slot is clicked it runs this function. Slot is the panel that the click happened on.
function PANEL:OnSlotClicked(slot)
	local item=slot:GetItem();
	if item!=nil then
		self:ToggleSelection(item);
	end
end

--If a slot has a panel dropped on it this function runs. Slot is the panel that the drop happened on.
--TODO pcall events
function PANEL:OnSlotDrop(slot,droppedPanel)
	--If we don't have an inventory set, drag/drops are pointless
	local inv=self:GetInventory();
	if !inv then return false end
	
	--Ignore if we drop the panel on itself, or if the dropped panel wasn't an item slot (we can only deal with item slots at the moment) we'll quit here
	if slot==droppedPanel || string.lower(droppedPanel.ClassName)!="itemforgeitemslot" then return false end
	
	--if we dropped a panel here we expect it to contain an item
	local droppedItem=droppedPanel:GetItem();
	if !droppedItem then return false end
	
	local item=slot:GetItem();
	if !item then
		droppedItem:OnDragDropToInventory(inv,slot.invSlot);
	else
		if item:OnDragDropHere(droppedItem) then
			droppedItem:OnDragDropToItem(item);
		end
	end
end


--[[
Relating to selection of items...
Enable/Disable Selection, Can Select Item, Select Item, Deselect Item, Toggle Selection, Deselect All, Validate All, Display Selected Items, Get First Selected Item, Get All Selected Items, How Many Selected.
]]--

function PANEL:EnableSelection()
	self.CanSelectItems=true;
end

function PANEL:DisableSelection()
	self:DeselectAllItems();
	self.CanSelectItems=false;
end

--Returns true if an item can be selected by this panel
--Returns false if... selection is turned off, no item is given, or is invalid, or this panel is not displaying an inventory, or if the item is not in the displayed inventory.
function PANEL:CanSelectItem(item)
	if !self.CanSelectItems || !item || !item:IsValid() || !self.Inventory || item:GetContainer()!=self.Inventory then return false end
	return true;
end

--Selects an item in the inventory
function PANEL:SelectItem(item)
	if !self:CanSelectItem(item) || self.SelectedItems[item:GetID()]!=nil then return false end
	
	self.SelectedItems[item:GetID()]=item;
	self:DisplaySelectedItems();
	
	return true;
end

--[[
Deselects a selected item.
Item can be an item or an item id. If it's a item id, then the selected item with that ID is removed.
	The reason it can take either is just in case we're deselecting an item that no longer exists
Display is optional. If display is false, then we won't do DisplaySelectedItems() after deselecting the item (in case you're deselecting a lot at once).
]]--
function PANEL:DeselectItem(item,display)
	local k=item;
	if type(item)!="number" then
		if !item || !item:IsValid() then return false end
		k=item:GetID();
	end
	
	if !self.SelectedItems[k] then return false end
	self.SelectedItems[k]=nil;
	
	if display!=false then self:DisplaySelectedItems(); end
	
	return true;
end

--Deselects everything.
function PANEL:DeselectAllItems()
	for k,v in pairs(self.SelectedItems) do
		self:DeselectItem(k,false);
	end
	
	self:DisplaySelectedItems();
	return true;
end

--Selects an item if it's not selected, deselects an item if it is selected
function PANEL:ToggleSelection(item)
	if !item || !item:IsValid() then return false end
	
	if !self.SelectedItems[item:GetID()] then
		return self:SelectItem(item);
	else
		return self:DeselectItem(item);
	end
end

--Turns borders on items slots on or off depending on whether or not the item slot is displaying a selected item
function PANEL:DisplaySelectedItems()
	
	for i=1,table.getn(self.Slots) do
		local item=self.Slots[i]:GetItem();
		if item && self.SelectedItems[item:GetID()] then
			--If this slot is displaying an item, and it's selected, we draw the border.
			self.Slots[i]:SetDrawBorder(true);
		else
			--Otherwise not
			self.Slots[i]:SetDrawBorder(false); 
		end
	end
end

--Checks all of the panel's selected items to make sure they can still be selected
--This is necessary because... lets say a selected item was taken out of the inventory this panel displays, for example)
function PANEL:ValidateSelectedItems()
	for k,v in pairs(self.SelectedItems) do
		if !self:CanSelectItem(v) then self:DeselectItem(k); end
	end
end

--Returns the first selected item or nil if nothing is selected
--What does "first selected item" mean? Our selected item list is sorted by Item ID. So, the first selected item will be the item with the lowest ID.
--Example: If Item 40, Item 3, and Item 8 are selected, then Item 3 will be returned.
function PANEL:GetSelectedItem()
	for i=1,table.maxn(self.SelectedItems) do
		if self.SelectedItems[i] then
			return self.SelectedItems[i];
		end
	end
	
	return nil;
end

--Returns a table of all the items selected... table will be empty if no items are selected
function PANEL:GetSelectedItems()
	local t={};
	local i=1;
	for k,v in pairs(self.SelectedItems) do
		t[i]=v;
		i=i+1;
	end
	return t;
end

--How many items are selected?
function PANEL:HowManySelected()
	return table.Count(self.SelectedItems);
end

vgui.Register("ItemforgeInventorySlots", PANEL, "Panel");