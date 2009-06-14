/*
ItemforgePercentBarBar
CLIENT

Creates the ItemforgePercentBarBar VGUI control.
This is only meant to be used by ItemforgePercentBar. Don't create it on it's own.
*/
local PANEL = {}

PANEL.BarMaterial=Material("itemforge/inventory/weightbar");		--Material for the bar to use
PANEL.Color=Color(255,255,255,255)									--Color of the bar

--Some basic stuff to do on init.
function PANEL:Init()
	self:SetPos(0,0);
	self:SetVisible(true);
	self:SetAutoDelete(true);
end

--Sets the ratio of the bar (between 0 and 1). Not called directly
function PANEL:SetBarRatio(ratio)
	self:SetSize((self:GetParent():GetWide()*ratio),self:GetParent():GetTall());
end

--Sets the foreground material for the percent bar to use. Not called directly
function PANEL:SetBarMat(Mat)
	self.BarMaterial=Mat;
end

--Set the foreground color. Not called directly.
function PANEL:SetBarColor(color)
	self.Color=color;
end

--Draw the panel
function PANEL:Paint()
	surface.SetMaterial(self.BarMaterial);
	surface.SetDrawColor(self.Color.r,self.Color.g,self.Color.b,self.Color.a);
	surface.DrawTexturedRect(0,0,self:GetParent():GetWide(),self:GetParent():GetTall());	--Note the bar is always drawn at full size, this is to prevent the bar from pixelating. Instead we resize the panel that it's being drawn in, causing the bar to be clipped
	
	return true;
end

vgui.Register("ItemforgePercentBarBar", PANEL, "Panel");