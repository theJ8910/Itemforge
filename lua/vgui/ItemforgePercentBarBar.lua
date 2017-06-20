--[[
ItemforgePercentBarBar
CLIENT

Creates the ItemforgePercentBarBar VGUI control.
This is only meant to be used by ItemforgePercentBar. Don't create it on it's own.
]]--

local PANEL			= {};

PANEL.BarMaterial	= Material( "itemforge/inventory/weightbar" );		--Material for the bar to use
PANEL.Color			= Color( 255, 255, 255, 255 )						--Color of the bar

--[[
* CLIENT
* Event

Some basic stuff to do on init.
]]--
function PANEL:Init()
	self:SetPos( 0, 0 );
	self:SetVisible( true );
	self:SetAutoDelete( true );
end

--[[
* CLIENT

Sets the bar's fullness.
Not called directly.

fRatio should be a number between 0 and 1.
	0 represents an empty bar.
	1 represents a full bar.
]]--
function PANEL:SetBarRatio( fRatio )
	self:SetSize( (self:GetParent():GetWide() * fRatio ), self:GetParent():GetTall() );
end

--[[
* CLIENT

Sets the foreground material for the percent bar to use.
Not called directly.

mat should be Material().
]]--
function PANEL:SetBarMat( mat )
	self.BarMaterial = mat;
end

--[[
* CLIENT

Set the foreground color.
Not called directly.

color should be the color you want to set the bar to.
]]--
function PANEL:SetBarColor( color )
	self.Color = color;
end

--[[
* CLIENT
* Event

Draws the panel.
Note the bar is always drawn at full size, this is to prevent the bar from pixelating.
Instead we resize the panel that it's being drawn in, causing the bar to be clipped.
]]--
function PANEL:Paint()
	surface.SetMaterial( self.BarMaterial );
	surface.SetDrawColor( self.Color.r, self.Color.g, self.Color.b, self.Color.a );
	surface.DrawTexturedRect( 0, 0, self:GetParent():GetWide(), self:GetParent():GetTall() );
	
	return true;
end

vgui.Register( "ItemforgePercentBarBar", PANEL, "Panel" );