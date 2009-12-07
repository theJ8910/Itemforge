--[[
itemforge_item
CLIENT

This entity is an 'avatar' of an item. When on the ground, this entity represents that item.
]]--
include("shared.lua")

language.Add("itemforge_item","Item");

function ENT:Draw()
	--If the item can't be found we'll just draw the model (no hook)
	local item=self:GetItem();
	if !item then
		self.Entity:DrawModel();
		return true;
	end
	
	item:Event("OnDraw3D",nil,self.Entity,false);
	
	if self.IsWire then Wire_Render(self.Entity) end	--WIRE
	
	return true;
end

function ENT:DrawTranslucent()
	--If the item can't be found we'll just draw the model (no hook)
	local item=self:GetItem();
	if !item then
		self.Entity:DrawModel();
		return true;
	end
	
	item:Event("OnDraw3D",nil,self.Entity,false);
	
	if self.IsWire then Wire_Render(self.Entity) end	--WIRE
	
	return true;
end

--[[
When a panel is dropped on this entity, this function runs.
Returns false if this entity cannot accept this panel.
Returns true if the entity handled the dropped panel.
]]--
function ENT:OnDragDropHere(panel)
	--We want to make two items interact - this entity's item and the dropped panel's item.
	
	--Does this entity have an item set yet?
	local item=self:GetItem();
	if !item then return false; end
	
	--Can the panel hold an item?
	if !panel.GetItem then return false end
	
	--Does the panel have an item set, and is it different from this item?
	local s,r=pcall(panel.GetItem,panel);
	if !s then	ErrorNoHalt(r.."\n"); return false;
	elseif r && r!=item then
		if item:Event("OnDragDropHere",true,r) then
			r:Event("OnDragDropToItem",nil,item);
		end
	end
	
	return true;
end

--[[
This event is called by Itemforge's UI when the user presses his mouse while it's hovering over this entity.

If the mouse is being captured by this entity, the event runs even if mouse isn't overhead.
	IF.UI:EntityCaptureMouse(true,self);
	
mc is the mouse-code. It identifies what mouse button was pressed. This will be a MOUSE_ enum: MOUSE_LEFT, MOUSE_RIGHT, etc.
x and y is the position on the screen the user pressed the mouse at.
traceRes is the screen-to-world trace results of this event.
]]--
function ENT:OnMousePressed(mc,x,y,traceRes)
	if mc!=MOUSE_LEFT then return false end
	
	--TODO possibly move this code to the item or something?
	self.DragExpected=true;
end

--[[
This event is called by Itemforge's UI when the user releases his mouse while it's hovering over this entity.

If the mouse is being captured by this entity, the event runs even if mouse isn't overhead.
	IF.UI:EntityCaptureMouse(true,self);
	
mc is the mouse-code. It identifies what mouse button was released. This will be a MOUSE_ enum: MOUSE_LEFT, MOUSE_RIGHT, etc.
x and y is the position on the screen the user released the mouse at.
traceRes is the screen-to-world trace results of this event.
]]--
function ENT:OnMouseReleased(mc,x,y,traceRes)
	if mc==MOUSE_LEFT then
		self.DragExpected=false;
		return false;
	elseif mc==MOUSE_RIGHT then
		local item=self:GetItem();
		if !item then return false end
		
		return item:ShowMenu(x,y);
	end
	return false;
end

--[[
This event is called by Itemforge's UI when the user's cursor "enters" the entity, meaning:
	A. The user's cursor is hovering over this entity (determined by a screen trace) this frame
	B. The cursor wasn't visible or was hovering over something else last frame
]]--
function ENT:OnCursorEntered()
	IF.UI:SetDropEntity(self.Entity);
end

--[[
This event is called by Itemforge's UI when the user's cursor "exits" the entity, meaning:
	A. The user's cursor is hovering over this entity (determined by a screen trace) this frame
	B. The cursor wasn't visible or was hovering over something else last frame
]]--
function ENT:OnCursorExited()
	IF.UI:ClearDropEntity(self.Entity);
	if self.DragExpected then
		self:Drag();
	end
end

--[[
This function is called to drag the entity's item (as a panel onscreen)
]]--
function ENT:Drag()
	self.DragExpected=false;
	local item=self:GetItem();
	if !item || IF.UI:IsDragging() then return false end
	
	local panel=vgui.Create("ItemforgeItemSlot");
	panel:MakePopup();
	panel:SetSize(64,64);
	panel:SetItem(item);
	panel:SetMouseInputEnabled(false);
	
	if IF.UI:Drag(panel,32,32) then
		return true;
	end
	return false;
end

--Clear the item's association to this entity if it's removed clientside
function ENT:OnRemove()
	--We're removing the item right now, don't try to reaquire the item
	self.BeingRemoved=true;
	self.Entity:SetNWInt("i",0);
	
	--Clear the one-way connection between entity and item
	local item=self:GetItem();
	if !item then return true end
	self.Item=nil;
	
	--Clear the item's connection to the entity (the item "forgets" that this was it's entity)
	item:ToVoid(false,self.Entity,nil,false);
	
	return true;
end

--[[
The item this entity is supposed to be representing may not be known or exist clientside when the item is created. We'll search for it until we find it. 
THIS IS SHARED but we only use it clientside
]]--
function ENT:Think()
	if !self:GetItem() then return; end
	
	--WIRE
	if self.IsWire then self["BaseWireEntity"].Think(self); end
end