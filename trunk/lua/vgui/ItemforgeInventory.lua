/*
ItemforgeInventory
CLIENT

Creates the ItemforgeInventory VGUI control.
This control is used to display and provide interaction between a player and the contents of an inventory.
*/

local PANEL = {}

--What inventory is this window displaying?
PANEL.Inventory=nil;
PANEL.TitleBarWidth=0;							--Width of the title bar's solid portion, is set automatically
PANEL.TitleText="";								--What does the title bar have written on it? Is set automatically.
PANEL.BackgroundTilesX=0;						--How many tiles wide/tall is the background? Is set automatically.
PANEL.BackgroundTilesY=0;
PANEL.CloseButton=nil;
PANEL.SizeLimIcon=nil;
PANEL.WeightBar=nil;
PANEL.Slots=nil;
PANEL.ActionButtons=nil;
PANEL.MouseDown=false
PANEL.MouseDownX=0;
PANEL.MouseDownY=0;
PANEL.Dragging=false;

--Background
local BackgroundMat=Material("itemforge/inventory/bgpattern");
local BackgroundX=17;					--Where does the background begin drawing?
local BackgroundY=17;
local BackgroundTileWidth=32;			--Width/height of an individual background tile
local BackgroundTileHeight=32;

--Title Bar
local TitleMats={
	Material("itemforge/inventory/title_startcap"),
	Material("itemforge/inventory/title_bar"),
	Material("itemforge/inventory/title_endcap"),
}
local TitleX=63;								--The title bar starts drawing at this location
local TitleY=21;
local TitleHeight=32;							--Height of the title bar (texture size)
local TitleDisplayHeight=24;					--Height of the title bar (as it appears on the inventory)
local TitleStartCapWidth=8;						--Width of the title bar's starting cap
local TitleEndCapWidth=8;						--Width of the title bar's end cap
local TitleEndCapPadding=0;						--How much space between the end of the title bar cap and the right border?
local TitleTextColor=Color(255,255,255,255);	--What color is the title bar text?
local TitleTextX=69;							--Where does the text start drawing?
local TitleTextY=17;

--Borders and corners
local BorderMats={
	Material("itemforge/inventory/border_right"),
	Material("itemforge/inventory/border_top"),
	Material("itemforge/inventory/border_left"),
	Material("itemforge/inventory/border_bottom"),
}
--Border width/height - these are for vertical borders, swap width/height for horizontal borders.
local BorderWidth=8;
local BorderHeight=32;

--There are only three corners because one is hidden by the circle
local CornerMats={
	Material("itemforge/inventory/corner_sw"),
	Material("itemforge/inventory/corner_se"),
	Material("itemforge/inventory/corner_ne"),
}
local CornerWidth=8;
local CornerHeight=8;

--Circle
local CircleMats={
	Material("itemforge/inventory/circle"),
	Material("itemforge/inventory/circle_border")
}
local CircleX=0;
local CircleY=0;
local CircleWidth=64;
local CircleHeight=64;
local CircleVerts={};			--An unchanging verts table. This is used to draw an icon inside of the circle.
local CircleRadius=29.5;		--The radius of the circle; starting at the center of the circle, the radius should land you in the middle of the border.
local circleCenterX=CircleX+(CircleWidth*.5);
local circleCenterY=CircleY+(CircleHeight*.5);

if true then
	local CircleVertDetail=32;		--How many verts total on the circle? Increasing this number makes the circle with the icon in it smoother but makes the inventory draw a little slower.
	
	--[[
	The radius is half the length of the diameter, so radius/diameter = .5.
	Or it would be if we weren't working with a texture. Our radius isn't _exactly_ .5, due to technical restrictions of what we're working with, you understand.
	UV coordinates are between 0 and 1, which is why we're converting here.
	We need both pixel coordinates (for drawing at a given location) and UV coordinates (used to "cut out" part of a texture; we're drawing a rough circle, right? So we need to "cut out" a circle from whatever texture we're using.)
	]]--
	local uvRadius=CircleRadius/CircleWidth;
	local slice=360/CircleVertDetail;
	
	--Precompute circle vertices
	for i=1,CircleVertDetail do
		local ang=math.Deg2Rad(slice*i);
		
		--x and y are coordinates describing the position of a point in the direction of ang from 0,0.
		--x and y are between [-1,1].
		local x=math.cos(ang);
		local y=math.sin(ang);
		
		local v={};
		v.u=0.5+(x*uvRadius);
		v.v=0.5+(y*uvRadius);
		v.x=circleCenterX+(x*CircleRadius);
		v.y=circleCenterY+(y*CircleRadius);
		
		CircleVerts[i]=v;
	end
end

--Close Button
local CloseButtonX=413;
local CloseButtonY=25;
local CloseButtonWidth=16;
local CloseButtonHeight=16;

--Size limit icon
local SizeLimIconX=63;
local SizeLimIconY=48;

--Weight bar/label related
local WeightBarX=81;
local WeightBarY=48;
local WeightLabelX=340;
local WeightLabelY=49;
local WeightLabelTextColor=Color(255,128,0,255);

--Selected Item Name/Description label related
local NameLabelX=22;
local NameLabelY=232;
local NameLabelColor=Color(255,128,0,255);

--Slots panel... Where do the slots start at? How big should the slot container be?
local SlotsX=22;
local SlotsY=66;
local SlotsWidth=410;
local SlotsHeight=130;

--Drag restrictions
local DragMarginY=-36;		--The box can only be dragged 36 pixels above the visible area

--Inventory fonts
surface.CreateFont("Verdana",28,400,true,false,"ItemforgeInventoryTitle");	--font size 18pts
surface.CreateFont("Verdana",15,400,true,false,"ItemforgeInventoryFont");
surface.CreateFont("Verdana",15,700,true,false,"ItemforgeInventoryFontBold");

--Action buttons
local ActionButtonX=22;			--Where do action buttons start
local ActionButtonY=198;
local ActionButtonWidth=32;		--How big are they?
local ActionButtonHeight=32;
local ActionButtonPadding=2;	--How much padding between them?
local ActionButtonIcons={
	Material("itemforge/inventory/useicon"),
	Material("itemforge/inventory/consumeicon"),
	Material("itemforge/inventory/holdicon"),
	Material("itemforge/inventory/combineicon"),
	Material("itemforge/inventory/dropicon"),
	Material("itemforge/inventory/releaseicon")
}


function PANEL:Init()
	--Set inital size
	self:SetSize(437,353);
	
	--Precompute number of background tiles
	self.BackgroundTilesX=math.ceil((self:GetWide()-BackgroundX)/BackgroundTileWidth);
	self.BackgroundTilesY=math.ceil((self:GetTall()-BackgroundY)/BackgroundTileHeight);
	
	--Precompute size of title bar
	self.TitleBarWidth=self:GetWide()-TitleX-TitleStartCapWidth-TitleEndCapWidth;
	
	--Create close button
	self.CloseButton=vgui.Create("DSysButton",self);
	self.CloseButton:SetType("close");
	self.CloseButton:SetPos(CloseButtonX,CloseButtonY);
	self.CloseButton:SetSize(CloseButtonWidth,CloseButtonHeight);
	self.CloseButton.DoClick=function(self) self:GetParent():Close() end
	
	--Create size limit icon
	self.SizeLimIcon=vgui.Create("ItemforgeSizeIcon",self);
	self.SizeLimIcon:SetPos(SizeLimIconX,SizeLimIconY);
	self.SizeLimIcon:SetVisible(false);
	
	--Create weight bar
	self.WeightBar=vgui.Create("ItemforgePercentBar",self);
	self.WeightBar:SetPos(WeightBarX,WeightBarY);
	
	--Create inventory slots control
	self.Slots=vgui.Create("ItemforgeInventorySlots",self);
	self.Slots:SetPos(SlotsX,SlotsY);
	self.Slots:SetSize(SlotsWidth,SlotsHeight);
	
	--Create Action Buttons
	local spacing=ActionButtonWidth+ActionButtonPadding;
	self.ActionButtons={};
	
	--Use
	self.ActionButtons[1]=vgui.Create("ItemforgeImageButton",self);
	self.ActionButtons[1]:SetPos(ActionButtonX,ActionButtonY);
	self.ActionButtons[1]:SetSize(ActionButtonWidth,ActionButtonHeight);
	self.ActionButtons[1]:SetIcon(ActionButtonIcons[1]);
	self.ActionButtons[1].DoClick=function(self) self:GetParent():PlayerUseItem() end
	
	--Consume
	self.ActionButtons[2]=vgui.Create("ItemforgeImageButton",self);
	self.ActionButtons[2]:SetPos(ActionButtonX+(spacing),ActionButtonY);
	self.ActionButtons[2]:SetSize(ActionButtonWidth,ActionButtonHeight);
	self.ActionButtons[2]:SetIcon(ActionButtonIcons[2]);
	self.ActionButtons[2].DoClick=function(self) LocalPlayer():PrintMessage(HUD_PRINTTALK,"This has been removed."); end
	
	--Hold
	self.ActionButtons[3]=vgui.Create("ItemforgeImageButton",self);
	self.ActionButtons[3]:SetPos(ActionButtonX+(spacing*2),ActionButtonY);
	self.ActionButtons[3]:SetSize(ActionButtonWidth,ActionButtonHeight);
	self.ActionButtons[3]:SetIcon(ActionButtonIcons[3]);
	self.ActionButtons[3].DoClick=function(self) self:GetParent():PlayerHoldItem() end
	
	--Combine
	self.ActionButtons[4]=vgui.Create("ItemforgeImageButton",self);
	self.ActionButtons[4]:SetPos(ActionButtonX+(spacing*3),ActionButtonY);
	self.ActionButtons[4]:SetSize(ActionButtonWidth,ActionButtonHeight);
	self.ActionButtons[4]:SetIcon(ActionButtonIcons[4]);
	
	--Drop
	self.ActionButtons[5]=vgui.Create("ItemforgeImageButton",self);
	self.ActionButtons[5]:SetPos(ActionButtonX+(spacing*4),ActionButtonY);
	self.ActionButtons[5]:SetSize(ActionButtonWidth,ActionButtonHeight);
	self.ActionButtons[5]:SetIcon(ActionButtonIcons[5]);
	
	--Enable cursor while this is up
	self:MakePopup();
	self:SetAutoDelete(true);
end

function PANEL:Paint()
	surface.SetDrawColor(255,255,255,255);
	
	--Background
	surface.SetMaterial(BackgroundMat);
	for y=0,self.BackgroundTilesY-1 do
		for x=0,self.BackgroundTilesX-1 do
			surface.DrawTexturedRect(BackgroundX+(x*BackgroundTileWidth),BackgroundY+(y*BackgroundTileHeight),BackgroundTileWidth,BackgroundTileHeight);
		end
	end
	
	--Title start cap
	surface.SetMaterial(TitleMats[1]);
	surface.DrawTexturedRect(TitleX,TitleY,TitleStartCapWidth,TitleHeight);
	
	--Title Bar
	surface.SetMaterial(TitleMats[2]);
	surface.DrawTexturedRect(TitleX+TitleStartCapWidth,TitleY,self.TitleBarWidth,TitleHeight);
	
	--Title end cap
	surface.SetMaterial(TitleMats[3]);
	surface.DrawTexturedRect(TitleX+TitleStartCapWidth+self.TitleBarWidth,TitleY,TitleEndCapWidth,TitleHeight);
	
	--Title text
	if self.Inventory && self.Inventory:IsValid() then
		surface.SetFont("ItemforgeInventoryTitle");
		surface.SetTextColor(TitleTextColor.r,TitleTextColor.g,TitleTextColor.b,TitleTextColor.a);
		surface.SetTextPos(TitleTextX,TitleTextY);
		surface.DrawText(self.TitleText);
		
		--Weight bar text
		if self.WeightBar:IsVisible() then
			surface.SetFont("ItemforgeInventoryFont");
			surface.SetTextColor(WeightLabelTextColor.r,WeightLabelTextColor.g,WeightLabelTextColor.b,WeightLabelTextColor.a);
			surface.SetTextPos(WeightLabelX,WeightLabelY);
			surface.DrawText(self.Inventory:GetWeightFree().."kg/"..self.Inventory:GetWeightCapacity().."kg");
		end
		
		local selected=self.Slots:GetSelectedItem()
		if selected then
			--[[
			surface.SetFont("DefaultSmall");
			surface.SetTextColor(NameLabelColor.r,NameLabelColor.g,NameLabelColor.b,NameLabelColor.a);
			surface.SetTextPos(NameLabelX,NameLabelY);
			surface.DrawText(selected:GetName().."\n"..selected:GetDescription());
			]]--
			draw.DrawText(selected:GetName().."\n"..selected:GetDescription(),"DefaultSmall",NameLabelX,NameLabelY,NameLabelColor,TEXT_ALIGN_LEFT);
		end
	end
	
	--Right border
	local x=self:GetWide()-BorderWidth;
	surface.SetMaterial(BorderMats[1]);
	for y=0,self.BackgroundTilesY-1 do
		surface.DrawTexturedRect(x,BackgroundY+(y*BorderHeight),BorderWidth,BorderHeight);
	end
	
	--Top border
	local y=BackgroundY;
	surface.SetMaterial(BorderMats[2]);
	for x=0,self.BackgroundTilesX-1 do
		surface.DrawTexturedRect(BackgroundX+(x*BorderHeight),y,BorderHeight,BorderWidth);
	end
	
	--Left border
	local x=BackgroundX;
	surface.SetMaterial(BorderMats[3]);
	for y=0,self.BackgroundTilesY-1 do
		surface.DrawTexturedRect(x,BackgroundY+(y*BorderHeight),BorderWidth,BorderHeight);
	end
	
	--Bottom border
	local y=self:GetTall()-BorderWidth;
	surface.SetMaterial(BorderMats[4]);
	for x=0,self.BackgroundTilesX-1 do
		surface.DrawTexturedRect(BackgroundX+(x*BorderHeight),y,BorderHeight,BorderWidth);
	end
	
	--Corners
	--SW
	surface.SetMaterial(CornerMats[1]);
	surface.DrawTexturedRect(BackgroundX,self:GetTall()-CornerHeight,CornerWidth,CornerHeight);
	--SE
	surface.SetMaterial(CornerMats[2]);
	surface.DrawTexturedRect(self:GetWide()-CornerWidth,self:GetTall()-CornerHeight,CornerWidth,CornerHeight);
	--NE
	surface.SetMaterial(CornerMats[3]);
	surface.DrawTexturedRect(self:GetWide()-CornerWidth,BackgroundY,CornerWidth,CornerHeight);
	
	--Circle (in the NW corner)
	surface.SetMaterial(CircleMats[1]);
	surface.DrawTexturedRect(CircleX,CircleY,CircleWidth,CircleHeight);
	
	--Icon Circle; we draw the icon for this inventory inside of a circle
	if self.Inventory && self.Inventory:IsValid() then
		local icon=self.Inventory:GetIcon();
		if icon then
			surface.SetMaterial(icon);
			surface.DrawPoly(CircleVerts);
		end
	end
	--This draws the border to obscure any rough edges on the icon circle
	surface.SetMaterial(CircleMats[2]);
	surface.DrawTexturedRect(CircleX,CircleY,CircleWidth,CircleHeight);
	
	return true;
end

function PANEL:OnMousePressed()
	self.MouseDownX,self.MouseDownY=self:ScreenToLocal(gui.MousePos());
	if (self.MouseDownX>=TitleX && self.MouseDownX<TitleX+TitleStartCapWidth+self.TitleBarWidth+TitleEndCapWidth && self.MouseDownY>=TitleY && self.MouseDownY<TitleY+TitleDisplayHeight) || (math.sqrt(math.pow(self.MouseDownX-circleCenterX,2)+math.pow(self.MouseDownY-circleCenterY,2))<=CircleRadius) then
		self.Dragging=true;
	end
end

function PANEL:OnMouseReleased()
	self.Dragging=false;
end

function PANEL:Think()
	--You can drag this window if you drag the title bar or if you drag the circle
	if self.Dragging then
		local y=math.max(gui.MouseY()-self.MouseDownY,DragMarginY);
		self:SetPos(gui.MouseX()-self.MouseDownX,y)
	end
end

--Try to bind the given inventory to our panel
function PANEL:SetInventory(inv)
	return inv:BindPanel(self);
end

function PANEL:Close()
	--If we have an inventory bound, we unbind it (which will close the inventory anyway, so we just return)
	if self.Inventory then self.Inventory:UnbindPanel(self); return end
	
	self:Remove();
end





--This function runs when an inventory binds this panel to it
function PANEL:InventoryBind(inv)
	if self.Inventory then return false end
	
	self.Inventory=inv;
	self:InventoryUpdate(inv);
	return true;
end

--This function runs when an inventory unbinds this panel from it
function PANEL:InventoryUnbind(inv)
	if self.Inventory!=inv then return false end
	
	--Set our inventory to nil and close this panel
	self.Inventory=nil;
	self:Close();
	
	return true;
end

--This runs when an inventory bound to this panel updates itself.
function PANEL:InventoryUpdate(inv)
	if self.Inventory!=inv then return false end
	
	--Set titlebar text
	self.TitleText=self.Inventory:GetTitle()
	
	--Update slots
	self.Slots:Update(inv);
	
	--Set size icon
	local size=self.Inventory:GetSizeLimit();
	if size>0 then
		self.SizeLimIcon:SetVisible(true);
		self.SizeLimIcon:SetIconSize(size);
	else
		self.SizeLimIcon:SetVisible(false);
	end
	
	--Set weight bar
	local max=self.Inventory:GetWeightCapacity()
	if max>0 then
		local wt=self.Inventory:GetWeightStored();
		self.WeightBar:SetVisible(true);
		self.WeightBar:SetBarRatio(1-(wt/max));		--Bar is full when inventory is empty.
	else
		self.WeightBar:SetVisible(false);
		self.WeightBar:SetBarRatio(1);
	end
	
	return true;
end

--Set the weight meter. This sets the weight label and weight bar. wt should be the total weight of all items in the inventory, and max should be the capacity of the inventory.
function PANEL:SetWeightMeter(wt,max)
	if !self.WeightBar then return false end
	
	if max>0 then
		self.WeightBar:SetVisible(true);
		self.WeightBar:SetBarRatio(1-(wt/max));		--Bar is full when inventory is empty.
	else
		self.WeightBar:SetVisible(false);
		self.WeightBar:SetBarRatio(1);
	end
end

function PANEL:PlayerUseItem()
	local item=self.Slots:GetSelectedItem();
	if !item then return false end
	
	item:Use(LocalPlayer());
end

function PANEL:PlayerHoldItem()
	local item=self.Slots:GetSelectedItem();
	if !item then return false end
	
	item:Hold(LocalPlayer());
end


vgui.Register("ItemforgeInventory", PANEL, "Panel");