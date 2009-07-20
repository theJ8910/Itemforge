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
PANEL.DrawBorder=false;												--If this is true, a border with the color given below will be drawn around the box (it's selected).
PANEL.MouseDown=false;
PANEL.ClickX=0;
PANEL.ClickY=0;
PANEL.ModelPanel=nil;												--If the item opts to use a model, a model panel will be created for it.

local SlotBackground=	Material("itemforge/inventory/slot");		--This is the background image. This material will be drawn before drawing the icon.
local SlotBorder=		Material("itemforge/inventory/slot_border");--This is the border image. This material will be drawn after drawing the icon.
local SlotClosed=		Material("itemforge/inventory/closedslot");	--This is a closed slot image. This is drawn if the slot is closed.

local BorderColor=Color(49,209,255,255);							--Color of the border, if a border is being drawn
local BorderColorDrop=Color(255,175,0,255);							--Color of the border, if a drag-drop is occuring and we're being moused over

local ModelPanelX=2;		--At this location on the panel...
local ModelPanelY=2;
local ModelPanelW=60;		--...at this size.
local ModelPanelH=60;

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
function PANEL:Open()
	self.SlotOpen=true;
end

function PANEL:Close()
	self:SetItem(nil);
	self:SetDrawBorder(false);
	self:MouseCapture(false);
	self:CancelDrag();
	self.MouseDown=false;
	self.MouseOver=false;
	self.ClickX=0;
	self.ClickY=0;
	
	self.SlotOpen=false;
	
end

function PANEL:RemoveModelPanel()
	if self.ModelPanel && self.ModelPanel:IsValid() then self.ModelPanel:Remove(); self.ModelPanel=nil; end
end

--Asks itemforge to start a drag/drop operation involving this panel
function PANEL:StartDrag()
	if !self.Draggable then return false end
	self.MouseDown=false;
	
	if IF.UI:Drag(self,self.ClickX,self.ClickY) then
		return true;
	end
	return false;
end

--Asks itemforge to stop the current drag/drop operation if this panel is involved
function PANEL:CancelDrag()
	IF.UI:CancelDrag(self);
end

--[[
This function creates a panel used while dragging this panel from one place to another.
While being dragged, this is the "drag image" displayed under the cursor.
]]--
function PANEL:MakeDragPanel()
	local panel=vgui.Create("ItemforgeItemSlot");
	panel:MakePopup();
	panel:SetSize(self:GetWide(),self:GetTall());
	panel:SetMouseInputEnabled(false);
	panel:SetItem(self:GetItem());
	return panel;
end



--Set/get stuff

--[[
Set the item this panel should render. You can set this to nil to make it render nothing.
This will fail if the slot is closed.
Returns true if the panel's item was set successfully. Returns false otherwise.
]]--
function PANEL:SetItem(item)
	if !self.SlotOpen then return false end
	if !item then
		self:RemoveModelPanel();
		self.Item=nil;
		
		return true;
	end
	
	if !item:IsValid() then ErrorNoHalt("Itemforge Item Slot: Couldn't set item on Item Slot; given item was invalid.\n"); return false end
	self.Item=item;
	
	if item:Event("ShouldUseModelFor2D",true) then
		self:RemoveModelPanel();
		
		self.ModelPanel=vgui.Create("DModelPanel",self);
		self.ModelPanel:SetPos(ModelPanelX,ModelPanelY);
		self.ModelPanel:SetSize(ModelPanelW,ModelPanelH);
		self.ModelPanel:SetModel(self.Item:GetWorldModel());
		
		if self.ModelPanel:GetEntity() then
			--We use the bounding box and some trig to determine what distance the camera needs to be at to see the entire model.
			local min,max=self.ModelPanel:GetEntity():GetRenderBounds();
			--local d=(min:Distance(max)*.5);
			local d=math.max(max.x-min.x,max.y-min.y,max.z-min.z);
			local f=math.Deg2Rad(self.ModelPanel:GetFOV()*.5);
			local x=0.8*d*(1/math.tan(f));
			
			--Position the camera at an interesting angle, at the calculated distance
			self.ModelPanel:SetCamPos(Angle(-45,-45,0):Forward() * x);
			
			--Look at the center of the bounding box
			self.ModelPanel:SetLookAt(Vector(0,0,0));
		end
		self.ModelPanel.Paint=SlotPaint;
		self.ModelPanel:SetPaintedManually(true);
		
		--I don't particularly understand why this wasn't done in the DModelPanel file... it's not like the panel does anything if clicked, but it's blocking my slots regardless.
		self.ModelPanel:SetMouseInputEnabled(false);
		self.ModelPanel:SetKeyboardInputEnabled(false);
	end
	
	return true;
end

function PANEL:SetDraggable(b)
	self.Draggable=b;
	if b==false then
		self:CancelDrag();
	end
end

function PANEL:SetDroppable(b)
	self.Droppable=b;
end

function PANEL:SetDrawBorder(b)
	self.DrawBorder=b;
end

--[[
Returns this panel's set item.
If no items is set, nil is returned.
If the item set is invalid, nil is returned and the panel's item is set to nil.
]]--
function PANEL:GetItem()
	if self.Item then
		if !self.Item:IsValid() then
			self:SetItem(nil);
			return nil;
		end
		return self.Item;
	end
	return nil;
end




--Events

--Occurs if a panel is dropped here (override this)
function PANEL:OnDrop(panel)
end

--Override this to set a click action
function PANEL:DoClick()
end

--When itemforge stops a drag-drop with this panel, this event runs
function PANEL:OnCancelDrag()
end

function PANEL:Init()
	self:SetVisible(true);
	self:SetAutoDelete(true);
end

function PANEL:OnCursorEntered()
	if !self.SlotOpen then return false end
	
	self.MouseOver=true;
	IF.UI:SetDropzone(self);
end

function PANEL:OnCursorExited()
	if !self.SlotOpen then return false end
	
	self.MouseOver=false;
	IF.UI:ClearDropzone(self);
	
	if self.MouseDown==true then
		self:StartDrag();
	end
end

function PANEL:OnMousePressed(mc)
	if !self.SlotOpen || mc==MOUSE_RIGHT then return false end
	
	--Record that the mouse has been pressed and where it has been pressed (used in drag code)
	self.MouseDown=true;
	self.ClickX,self.ClickY=self:ScreenToLocal(gui.MousePos());
end

function PANEL:OnMouseReleased(mc)
	if !self.SlotOpen then return false end
	if mc==MOUSE_RIGHT then
		local item=self:GetItem();
		if !item then return false end
		
		return item:ShowMenu(gui.MousePos());
	elseif mc==MOUSE_LEFT then
		self.MouseDown=false;
	
		--Ignore if we released the mouse while dragging
		if IF.UI:IsDragging() then return false end
		
		--Call this panel's overridable DoClick if something wasn't dropped here
		local s,r=pcall(self.DoClick,self);
		if !s then ErrorNoHalt(r.."\n") end
	end
end



--Draw the panel
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
		
		--Draw slot border
		surface.SetMaterial(SlotBorder);
		surface.SetDrawColor(255,255,255,255);
		surface.DrawTexturedRect(0,0,self:GetWide(),self:GetTall());
		
		local p=IF.UI:GetDragPanel();
		local isDragging=p && p!=self && self.MouseOver;
		
		--Draw selection border
		if self.DrawBorder==true || isDragging then
			local a=191.25+(math.sin(CurTime()*5)*63.75);
			
			if !isDragging then surface.SetDrawColor(BorderColor.r,BorderColor.g,BorderColor.b,a);
			else surface.SetDrawColor(BorderColorDrop.r,BorderColorDrop.g,BorderColorDrop.b,a) end
			
			--Vertical lines
			surface.DrawRect(0,0,2,self:GetTall());
			surface.DrawRect(self:GetWide()-2,0,2,self:GetTall());
			
			--Horizontal lines
			surface.DrawRect(2,0,self:GetWide()-4,2);
			surface.DrawRect(2,self:GetTall()-2,self:GetWide()-4,2);
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