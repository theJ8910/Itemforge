--[[
ItemforgeImageButton
CLIENT

Creates the ItemforgeImageButton VGUI control.
This inherits from the Button control.
This button has a total of three materials - a "pressed" and "released" material for the background of the button, and an icon displayed on top of that.
]]--

local PANEL			= {};

--Button Materials
PANEL.ReleasedMat	= Material( "itemforge/inventory/button_up" );
PANEL.PressedMat	= Material( "itemforge/inventory/button_down" );

--Current icon
PANEL.Icon			= nil;

--MouseOver and Held are used to determine if the button should be drawn pressed down. If both are true, the button is drawn pressed.
PANEL.MouseOver		= false;
PANEL.Held			= false;

--Icon X and Icon Y determine where the icon is drawn.
PANEL.IconX			= 0;
PANEL.IconY			= 0;

--[[
* CLIENT
* Event

When the button is created, we hide it's text.

This is based off of the Button control, which has default text.
Because this is an image button, we don't want there to be any text.
]]--
function PANEL:Init()
	self:SetText( "" );
	self:SetAutoDelete( true );
end

--[[
* CLIENT

Sets the button's released background material.

mat should be a Material().
]]--
function PANEL:SetReleaseMat( mat )
	self.ReleasedMat = mat;
end

--[[
* CLIENT

Sets the button's pressed background material.

mat should be a Material().
]]--
function PANEL:SetPressMat( mat )
	self.PressedMat = mat;
end

--[[
* CLIENT

Set the button's icon.

mat should be a Material().
]]--
function PANEL:SetIcon( mat )
	self.Icon = mat;
end

--[[
* CLIENT
* Event

Records when the mouse is hovering over this button
]]--
function PANEL:OnCursorEntered()
	self.MouseOver = true;
end

--[[
* CLIENT
* Event

Records when the mouse is no longer hovering over this button
]]--
function PANEL:OnCursorExited()
	self.MouseOver = false;
end 

--[[
* CLIENT
* Event

Runs when the user presses down the button with his mouse.
Additionally, captures the mouse, so that even if the user moves the cursor off the button,
the button is informed when the user releases the mouse.
]]--
function PANEL:OnMousePressed( mc )
	self:MouseCapture( true );
	self.Held = true;
end

--[[
* CLIENT
* Event

This event runs when the user releases his mouse button while it's hovering this button
(or, if the button is capturing the mouse, if he released his mouse at all).

If a valid click occurs, runs the button's OnClick event.
A click is only valid if both a mouse press and a mouse release occured while the mouse was hovering over this button.
If the mouse was elsewhere on either event, nothing happens.
]]--
function PANEL:OnMouseReleased( mc )
	self:MouseCapture( false );
	if !self.Held then return end

	self.Held = false;
	if !self.MouseOver then return end
	
	local s, r = pcall( self.DoClick, self );
	if !s then ErrorNoHalt( r.."\n" ) end
end

--[[
* CLIENT

Click function
]]--
function PANEL:DoClick()
	Msg( "Itemforge UI: This button needs to have an action assigned to it's DoClick\n" );
end

--[[
* CLIENT

Draws the button's pressed / released background and icon.
]]--
function PANEL:Paint()
	local x = self.IconX;
	local y = self.IconY;
	
	surface.SetDrawColor( 255, 255, 255, 255 );
	if self.Held && self.MouseOver then
		--Nudge icon a little bit if held
		x = x + 1;
		y = y + 1;
		
		surface.SetMaterial( self.PressedMat );
		surface.DrawTexturedRect( 0, 0, self:GetWide(), self:GetTall() );
	else
		surface.SetMaterial( self.ReleasedMat );
		surface.DrawTexturedRect( 0, 0, self:GetWide(), self:GetTall() );
	end
		
	if self.Icon then
		surface.SetMaterial( self.Icon );
		surface.DrawTexturedRect( x, y, self:GetWide(), self:GetTall() );
	end
	
	return true;
end

vgui.Register( "ItemforgeImageButton", PANEL, "Button" );