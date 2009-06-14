/*
ItemforgePercentBar
CLIENT

Creates the ItemforgePercentBar VGUI control.
This is used to create and display percent bars. A percent bar is horizontal, and is filled from left to right.
Use the panel's :SetBarSize() method to set the size of the percent bar, not :SetSize(). I recommend either (256,16) for a large bar or (128,8) for a small bar.
Use the panel's :SetBarRatio() function to set how full the bar is. It should be a number between 0 and 1. So, 0 is empty, 0.5 is half full, and 1 and full.
*/

local PANEL = {}

PANEL.Ratio=1;														--Fullness is between 0 and 1
PANEL.BackgroundMaterial=Material("itemforge/inventory/barback");	--Default background material for percent bar
PANEL.Bar=nil;														--This is the moving part of the percent bar

function PANEL:Init()
	self.Bar=vgui.Create("ItemforgePercentBarBar",self);
	self:SetBarSize(256,16);
	self:SetVisible(true);
	self:SetAutoDelete(true);
end

--Sets the bar's total size (ex 256,16)
function PANEL:SetBarSize(w,h)
	self:SetSize(w,h);
	self:SetBarRatio(self.Ratio);
end

--Sets the bar's fullness. Number is a ratio (between 0 and 1)
function PANEL:SetBarRatio(ratio)
	self.Ratio=ratio;
	self.Bar:SetBarRatio(ratio);
end

function PANEL:GetBarRatio()
	return self.Ratio;
end

--Sets the background material for the percent bar to use
function PANEL:SetBackMat(Mat)
	self.BackgroundMaterial=Mat;
end

--Sets the foreground material for the percent bar to use
function PANEL:SetBarMat(Mat)
	self.Bar:SetBarMat(Mat);
end

function PANEL:SetBarColor(color)
	self.Bar:SetBarColor(color);
end

--Draw the panel
function PANEL:Paint()
	surface.SetMaterial(self.BackgroundMaterial);
	surface.SetDrawColor(255,255,255,255);
	surface.DrawTexturedRect(0,0,self:GetWide(),self:GetTall());
	
	return true;
end

vgui.Register("ItemforgePercentBar", PANEL, "Panel");