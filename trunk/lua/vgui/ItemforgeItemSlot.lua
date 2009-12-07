/*
ItemforgeItemSlot
CLIENT

Creates the ItemforgeItemSlot VGUI control.
This control has four purposes:
	It displays the item on screen, giving the item a chance to do both 3D and 2D drawing inside of this control.
	It can be clicked to 'select' an item (in an inventory)
	It can be dragged.
	It acts as a drop-zone.
This is used in two locations:
	It's displayed in an inventory window to display the contents of an inventory.
	It's displayed when an itemforge_item_held SWEP is deployed (translation - while you're holding an item as a weapon)
*/

local PANEL = {}
PANEL.Item=nil;														--This is the item that the slot is set to display.

PANEL.SlotOpen=true;												--Is this slot open? If it is, it will draw a background, then the set item (if there is one), then the border. If it isn't, it draws a closed slot. This mostly applies to inventory slots.
PANEL.Draggable=false;												--Can this panel be dragged?
PANEL.Droppable=false;												--Can this panel have things dropped onto it?
PANEL.ShouldDrawBorder=false;										--If this is true, a border with the color given below will be drawn around the box (it's selected).
PANEL.DragExpected=false;											--If this is true, whenever the user moves his mouse outside the panel a drag is started. This becomes true when the user presses the mouse down, and false whenever a drag is started OR whenever the user releases his mouse.
PANEL.ClickX=0;														--This is the X and Y position on the panel that the user pressed his mouse down at.
PANEL.ClickY=0;
PANEL.ModelPanel=nil;												--If the item opts to use a model, a model panel will be created for it.

local SlotBackground=	Material("itemforge/inventory/slot");		--This is the background image. This material will be drawn before drawing the icon.
local SlotBorder=		Material("itemforge/inventory/slot_border");--This is the border image. This material will be drawn after drawing the icon.
local SlotClosed=		Material("itemforge/inventory/closedslot");	--This is a closed slot image. This is drawn if the slot is closed.

local BorderColor=Color(49,209,255,255);							--Color of the border, if a border is being drawn
local BorderColorDrop=Color(255,175,0,255);							--Color of the border, if a drag-drop is occuring and we're being moused over

local ModelPanelX=0.03125;		--The model panel is at this location on the panel (in the terms of 0-1)... 2/64 = 0.03125
local ModelPanelY=0.03125;
local ModelPanelW=0.9375;		--...at this size (in terms of 0-1).	60/64 = 0.9375
local ModelPanelH=0.9375;

--This is garry's Model Panel paint pretty much, but with comments and slight modifications
local SlotPaint=function(self,item)
	if ( !IsValid( self.Entity ) ) then return end
	
	local x,y=self:LocalToScreen(0,0);
	
	--Pose the entity for the shot (we ask the item to do that)
	item:Event("OnPose3D",nil,self.Entity,self);
	
	--Set up the camera and set the screen space that the drawing will occur in
	cam.Start3D(self.vCamPos,(self.vLookatPos-self.vCamPos):Angle(),self.fFOV,x,y,self:GetWide(),self:GetTall());
	cam.IgnoreZ(true);	--We don't want it clipping  something in the world on accident
	
	--If we didn't suppress the lighting then things in the game world like environmental light, spotlights, etc would accidentilly light the entity.
	--It's unspoken but everybody assumes the model is floating around in it's own dimension; little do they realize it's sharing the same world space as everything else!
	render.SuppressEngineLighting( true )
	
	--I'm not really sure what a lighting origin is. I guess it's where the light is sampled from in respect to world space when drawing.
	render.SetLightingOrigin( self.Entity:GetPos() )
	
	--Clears the model lighting of any pre-existing lights and sets the light to an ambient value (all values are between 0 and 1)
	render.ResetModelLighting( self.colAmbientLight.r/255, self.colAmbientLight.g/255, self.colAmbientLight.b/255 )
	
	--sets up 7 "directional" lights. You got me on this one. I don't know how source does it's lighting so I'm leaving this in here.
	for i=0,6 do
		local col=self.DirectionalLight[i];
		if (col) then
			render.SetModelLighting(i,col.r/255,col.g/255,col.b/255);
		end
	end
	
	--We use the item's Draw3D function on _this_ entity!
	--Whether bTranslucent is true or not depends on if the alpha is 255 or not.
	item:Event("OnDraw3D",nil,self.Entity,false);
	
	--Clean up before the frame ends
	render.SuppressEngineLighting(false);
	cam.IgnoreZ(false);
	cam.End3D()
	
	self.LastPaint = RealTime();
end



--Panel methods

--Opens the slot.
function PANEL:Open()
	self.SlotOpen=true;
end

--Closes the slot. Clears any items, borders, pending drags, etc.
function PANEL:Close()
	self:SetItem(nil);
	IF.UI:ClearDropzone(self);
	self.MouseOver=false;
	
	self.SlotOpen=false;
end

--[[
Set the item this panel should render. You can set this to nil to make it render nothing.
This will fail if the slot is closed.
Returns true if the panel's item was set successfully. Returns false otherwise.
]]--
function PANEL:SetItem(item)
	if !self.SlotOpen then return false end
	
	self:ForgetDrag();
	if !item then
		self:RemoveModelPanel();
		self.Item=nil;
		
		return true;
	end
	
	if !item:IsValid() then ErrorNoHalt("Itemforge Item Slot: Couldn't set item on Item Slot; given item was invalid.\n"); return false end
	self.Item=item;
	
	if item:Event("ShouldUseModelFor2D",true) then
		self:CreateModelPanel(self.Item:GetWorldModel());
	end
	
	return true;
end

--[[
Returns this panel's set item.
If no items is set, nil is returned.
If the item set is invalid, nil is returned and the panel's item is set to nil.
]]--
function PANEL:GetItem()
	if self.Item && !self.Item:IsValid() then
		self:SetItem(nil);
	end
	return self.Item;
end

--Creates a model panel.
function PANEL:CreateModelPanel(sModel)
	--Remove the model panel if we already have one
	self:RemoveModelPanel();
	
	self.ModelPanel=vgui.Create("DModelPanel",self);
	
	--We use custom painting
	self.ModelPanel.Paint=SlotPaint;
	self.ModelPanel:SetPaintedManually(true);
	
	--The position and size of the model panel depends on the size of the Item Slot
	local w,h=self:GetSize();
	self.ModelPanel:SetPos(math.floor(ModelPanelX*w),math.floor(ModelPanelY*h));
	self.ModelPanel:SetSize(math.floor(ModelPanelW*w),math.floor(ModelPanelH*h));
	
	--I don't particularly understand why this wasn't done in the DModelPanel file... it's not like the panel does anything if clicked, but it's blocking my slots regardless.
	self.ModelPanel:SetMouseInputEnabled(false);
	self.ModelPanel:SetKeyboardInputEnabled(false);
	
	--Lastly we'll set the model to the requested model.
	self.ModelPanel:SetModel(sModel);
	
	--If for some reason this didn't work we just end it here
	local ent=self.ModelPanel:GetEntity();
	if !ent then return false end
	
	--We use the bounding box and some trig to determine what distance the camera needs to be at to see the entire model.
	local min,max=ent:GetRenderBounds();
	
	--[[
	y = mx;
	
	d = [the largest side of the model's bounding box]
	f = [half of the Model Panel Camera's FOV in radians]
	
	y = 0.8*d;
	m = sin(f)/cos(f) = tan(f);
	
	0.8*d = tan(f)*x;
	0.8*d/tan(f) = x;
	]]--
	
	--Position the camera at an interesting angle, at the calculated distance
	self.ModelPanel:SetCamPos(Angle(-45,-45,0):Forward() * ( 0.8*(math.max(max.x-min.x,max.y-min.y,max.z-min.z))/math.tan(math.Deg2Rad(self.ModelPanel:GetFOV()*.5))));
	
	--Look at the center of the bounding box (The model will be moved when posed so the center of the bounding box is at 0,0,0)
	self.ModelPanel:SetLookAt(Vector(0,0,0));
	
	return true;
end

--[[
Removes the model panel if we have one
]]--
function PANEL:RemoveModelPanel()
	if self.ModelPanel && self.ModelPanel:IsValid() then self.ModelPanel:Remove(); self.ModelPanel=nil; end
end

--[[
Sets whether or not the panel should be draggable or not.
]]--
function PANEL:SetDraggable(b)
	self.Draggable=b;
	if b==false then self:ForgetDrag(); end
end

--[[
Sets whether or not you should be able to drop other panels on this panel.
If there is a drag-drop occuring
]]--
function PANEL:SetDroppable(b)
	self.Droppable=b;
	if b==false then
		IF.UI:ClearDropzone(self);
	end
end

--This function is run if a drag is expected
function PANEL:ExpectDrag(x,y)
	if !self.Draggable then return false end
	
	self.DragExpected=true;
	self.ClickX,self.ClickY=x,y;
end

--If a drag is pending, cancel it.
function PANEL:ForgetDrag()
	self.DragExpected=false;
end

--[[
Run this function to start a drag/drop operation.
This function should be called some time after an ExpectDrag() and before a ForgetDrag().
Rather than dragging _this_ panel, we create a floating panel which is basically the same as this panel, and drag IT.
That way, even if the contents of this panel change, or the window that contained this panel is closed, etc, we can still drag the item somewhere.
]]--
function PANEL:Drag()
	self:ForgetDrag();
	
	if IF.UI:IsDragging() then return false end
	
	local panel=vgui.Create("ItemforgeItemSlot");
	panel:MakePopup();
	panel:SetSize(self:GetWide(),self:GetTall());
	panel:SetItem(self:GetItem());
	panel:SetMouseInputEnabled(false);
	
	if IF.UI:Drag(panel,self.ClickX,self.ClickY) then
		return true;
	end
	return false;
end

function PANEL:SetDrawBorder(b)
	self.ShouldDrawBorder=b;
end

function PANEL:DrawBorder(color)
	surface.SetDrawColor(color.r,color.g,color.b,191.25+(math.sin(CurTime()*5)*63.75));
	
	--Vertical lines
	surface.DrawRect(0,0,2,self:GetTall());
	surface.DrawRect(self:GetWide()-2,0,2,self:GetTall());
	
	--Horizontal lines
	surface.DrawRect(2,0,self:GetWide()-4,2);
	surface.DrawRect(2,self:GetTall()-2,self:GetWide()-4,2);
end



--Events

--Occurs if a panel is dropped here (override this if you want it to do something different)
function PANEL:OnDragDropHere(panel)
	
end

--Occurs if a panel is dropped in the world (override this if you want it to do something different)
function PANEL:OnDragDropToWorld(traceRes)
	local droppedItem=self:GetItem();
	if !droppedItem then return false end
	
	droppedItem:Event("OnDragDropToWorld",nil,traceRes);
end

--Override this to set a click action
function PANEL:DoClick()
end

function PANEL:OnCancelDrag()
	self:Remove();
end

function PANEL:Init()
	self:SetVisible(true);
	self:SetAutoDelete(true);
end

function PANEL:OnCursorEntered()
	if !self.SlotOpen then return false end
	
	self.MouseOver=true;
	
	if self.Droppable then
		IF.UI:SetDropzone(self);
	end
end

function PANEL:OnCursorExited()
	if !self.SlotOpen then return false end
	
	self.MouseOver=false;
	IF.UI:ClearDropzone(self);
	
	if self.DragExpected==true then
		self:Drag();
	end
end

function PANEL:OnMousePressed(mc)
	if !self.SlotOpen || mc==MOUSE_RIGHT then return false end
	
	self:ExpectDrag(self:ScreenToLocal(gui.MousePos()));
end

function PANEL:OnMouseReleased(mc)
	if !self.SlotOpen then return false end
	if mc==MOUSE_RIGHT then
		local item=self:GetItem();
		if !item then return false end
		
		return item:ShowMenu(gui.MousePos());
	elseif mc==MOUSE_LEFT then
		--If we were expecting a drag, forget it
		self:ForgetDrag();
		
		--Ignore if we released the mouse while dragging
		if IF.UI:IsDragging() then return false end
		
		--Call this panel's overridable DoClick if something wasn't dropped here
		local s,r=pcall(self.DoClick,self);
		if !s then ErrorNoHalt(r.."\n") end
	end
end



--Draw the panel
--Good
function PANEL:Paint()
	if self.SlotOpen==true then
		local item=self:GetItem();
		
		--Draw slot background
		surface.SetMaterial(SlotBackground);
		surface.SetDrawColor(255,255,255,255);
		surface.DrawTexturedRect(0,0,self:GetWide(),self:GetTall());
		
		--Draw item in both 3D and 2D
		if item then
			if self.ModelPanel && self.ModelPanel:IsValid() then self.ModelPanel:Paint(item) end
			item:Event("OnDraw2D",nil,self:GetWide(),self:GetTall());
		end
		
		--Draw slot border texture
		surface.SetMaterial(SlotBorder);
		surface.SetDrawColor(255,255,255,255);
		surface.DrawTexturedRect(0,0,self:GetWide(),self:GetTall());
		
		
		
		--If a panel is being dragged, we want to know if it's an item being dragged.
		--Not all dragged panels contain items.
		local bValidDrop=false;
		if self.Droppable && self.MouseOver then
			local p=IF.UI:GetDragPanel();
			if p && p.GetItem then
				local s,r=pcall(p.GetItem,p);
				if !s then
					ErrorNoHalt(r.."\n");
				elseif r && r!=item then
					bValidDrop=true;
				end
			end
		end
		 
		--Draw dragdrop border if an item is being dragged (and of course if we aren't displaying that same item)
		if bValidDrop then
			self:DrawBorder(BorderColorDrop);
		
		--Draw selection border
		elseif self.ShouldDrawBorder==true then
			self:DrawBorder(BorderColor);
		end
	else
		--Draw closed slot
		surface.SetMaterial(SlotClosed);
		surface.SetDrawColor(255,255,255,255);
		surface.DrawTexturedRect(0,0,self:GetWide(),self:GetTall());
	end
	return true;
end

vgui.Register("ItemforgeItemSlot", PANEL, "Panel");