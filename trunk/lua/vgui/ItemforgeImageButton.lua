/*
ItemforgeImageButton
CLIENT

Creates the ItemforgeImageButton VGUI control.
This inherits from the Button control.
This button has a total of three materials - an "pressed" and "released" material for the background of the button, and an icon displayed on top of that.
*/
local PANEL = {}

--Button Materials
PANEL.ReleasedMat=Material("itemforge/inventory/button_up");
PANEL.PressedMat=Material("itemforge/inventory/button_down");

--Current icon
PANEL.Icon=nil;

--MouseOver and Held are used to determine if the button should be drawn pressed down. If both are true, the button is drawn pressed.
PANEL.MouseOver=false;
PANEL.Held=false;

--Icon X and Icon Y determine where the icon is drawn.
PANEL.IconX=0;
PANEL.IconY=0;

function PANEL:Init()
	--No text on this button
	self:SetText("");
	self:SetAutoDelete(true);
end

--Set the button's released background material. This takes a Material().
function PANEL:SetReleaseMat(mat)
	self.ReleasedMat=mat;
end

--Set the button's pressed background material. This takes a Material().
function PANEL:SetPressMat(mat)
	self.PressedMat=mat;
end

--Set the button's icon. This takes a Material().
function PANEL:SetIcon(mat)
	self.Icon=mat;
end

--Mouse over
function PANEL:OnCursorEntered()
	self.MouseOver=true;
end

--Mouse out
function PANEL:OnCursorExited()
	self.MouseOver=false;
end 

--Mouse press
function PANEL:OnMousePressed()
	self:MouseCapture(true);
	self.Held=true;
end

--Mouse release
function PANEL:OnMouseReleased()
	self:MouseCapture(false);
	if !self.Held then return end
	self.Held=false;
	if !self.MouseOver then return end
	
	local s,r=pcall(self.DoClick,self);
	if !s then ErrorNoHalt(r.."\n") end
end 

--Click function
function PANEL:DoClick()
	Msg("Itemforge Image Button: This button needs to have an action assigned to it's DoClick\n");
end

--Draw the panel
function PANEL:Paint()
	local x=self.IconX;
	local y=self.IconY;
	
	surface.SetDrawColor(255,255,255,255);
	if self.Held && self.MouseOver then
		--Nudge icon a little bit if held
		x=x+1;
		y=y+1;
		
		surface.SetMaterial(self.PressedMat);
		surface.DrawTexturedRect(0,0,self:GetWide(),self:GetTall());
	else
		surface.SetMaterial(self.ReleasedMat);
		surface.DrawTexturedRect(0,0,self:GetWide(),self:GetTall());
	end
		
	if self.Icon then
		surface.SetMaterial(self.Icon);
		surface.DrawTexturedRect(x,y,self:GetWide(),self:GetTall());
	end
	
	return true;
end

vgui.Register("ItemforgeImageButton", PANEL, "Button");