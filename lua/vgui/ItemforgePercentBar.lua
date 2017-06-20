--[[
ItemforgePercentBar
CLIENT

Creates the ItemforgePercentBar VGUI control.
This is used to create and display percent bars. A percent bar is horizontal, and is filled from left to right.
Use the panel's :SetBarSize() method to set the size of the percent bar, not :SetSize(). I recommend either ( 256, 16 ) for a large bar or ( 128, 8 ) for a small bar.
Use the panel's :SetBarRatio() function to set how full the bar is. It should be a number between 0 and 1. So, 0 is empty, 0.5 is half full, and 1 and full.
]]--

local PANEL					= {};

PANEL.Ratio					= 1;											--Fullness of the bar, between 0 and 1
PANEL.BackgroundMaterial	= Material( "itemforge/inventory/barback" );	--Default background material for percent bar
PANEL.Bar					= nil;											--This is the moving part of the percent bar
local DefaultWidth			= 256;											--Default width / height of the percent bar in pixels (should match texture dimensions)
local DefaultHeight			= 16;


--[[
* CLIENT
* Event

This panel acts as the background for the percent bar.
When the panel inits, it creates the moving part of the bar as a subpanel.

Additionally, the bar's default size is set here.
]]--
function PANEL:Init()
	self.Bar = vgui.Create( "ItemforgePercentBarBar", self );
	self:SetBarSize( DefaultWidth, DefaultHeight );
	self:SetAutoDelete( true );
end

--[[
* CLIENT

Sets the bar's total size (ex 256, 16)
]]--
function PANEL:SetBarSize( w, h )
	self:SetSize( w, h );
	self:SetBarRatio( self.Ratio );
end

--[[
* CLIENT

Sets the bar's fullness.

fRatio should be a number between 0 and 1.
	0 represents an empty bar.
	1 represents a full bar.
]]--
function PANEL:SetBarRatio( fRatio )
	self.Ratio = fRatio;
	self.Bar:SetBarRatio( fRatio );
end

--[[
* CLIENT

Returns the bar's fullness as a number between 0 and 1.
]]--
function PANEL:GetBarRatio()
	return self.Ratio;
end

--[[
* CLIENT

Sets the background material for the percent bar to use.

mat should be a Material().
]]--
function PANEL:SetBackMat( mat )
	self.BackgroundMaterial = mat;
end

--[[
* CLIENT

Sets the foreground material for the percent bar to use.

mat should be a Material().
]]--
function PANEL:SetBarMat( mat )
	self.Bar:SetBarMat( mat );
end

--[[
* CLIENT

Sets the color of the percent bar's foreground.

color should be the color you want to set the bar to.
]]--
function PANEL:SetBarColor( color )
	self.Bar:SetBarColor( color );
end

--[[
* CLIENT

Draws the background of the percent bar.
The foreground is drawn in the ItemforgePercentBarBar subpanel.
]]--
function PANEL:Paint()
	surface.SetMaterial( self.BackgroundMaterial );
	surface.SetDrawColor( 255, 255, 255, 255 );
	surface.DrawTexturedRect( 0, 0, self:GetWide(), self:GetTall() );
	
	return true;
end

vgui.Register( "ItemforgePercentBar", PANEL, "Panel" );