--[[
DVScrollBarItemforge
CLIENT

Creates the DVScrollBarItemforge Derma control.
This Derma control is a modified version of the DVScrollBar control.

I created a custom scrollbar based off the Derma one, because the Derma scrollbar didn't have the functionality I needed.
I have modified it to suit my needs... this scrollbar is identical to a DVScrollBar in every way,
except for the following ( which I marked with Changed: )
]]--
local PANEL = {};

--[[
* CLIENT
* Event

Initializes the panel (does nothing)
]]--
function PANEL:Init()
end

--[[
* CLIENT

Enables / disables the scrollbar.

Changed:
	I removed the part that invalidated the layout of the parent.
	This scrollbar does not scroll a panel on the parent
]]--
function PANEL:SetEnabled( b )
	if !b then
		self.Offset = 0;
		self:SetScroll( 0 );
		self.HasChanged = true;
	end
	
	self:SetMouseInputEnabled( b ); 
	self:SetVisible( b );
	self:SetAutoDelete( true );
	self.Enabled = b;	 
end

--[[
* CLIENT
* Event

When the mouse wheel is scrolled, scrolls the scrollbar.
Does nothing if the scrollbar is not visible (this is necessary because OnMouseWheeled events on other panels often forward their events to an associated scrollbar).

Returns true if the scrollbar moved at all,
or false otherwise.

Changed:
	This function was multiplying the scroll amount by -2. This has been changed to -1.
]]--
function PANEL:OnMouseWheeled( iDelta )
	if !self:IsVisible() then return false end
	
	return self:AddScroll( -iDelta );
end

--[[
* CLIENT

Makes the scrollbar scroll downward (positive numbers) or upwards (negative numbers).

iDelta should be the amount you want to scroll.

Returns true if the scrollbar moved at all,
or false otherwise.

Changed:
	This function was multiplying the scroll amount by 25, which I have removed.
	This is because the original was designed to scroll something on the parent and expected scroll amounts to be in terms of pixels.
]]--
function PANEL:AddScroll( iDelta )
	local OldScroll = self:GetScroll();
	self:SetScroll( self:GetScroll() + iDelta );
	
	return OldScroll == self:GetScroll();
end

--[[
* CLIENT

Sets the scroll position.
If this panel's parent has an OnVScroll event, calls it, and passes the scroll position.

iScrollPos should be the position you want to set the scroll to.

Changed:
	This function has been modified a bit.
	I make sure that the scroll amount is set to a whole number,
	and I have removed the part that invalidated the layout of the parent.
	I implemented better error checking / handling for the OnVScroll event call.
	Lastly, the scroll position is given to the parent's hook, rather than the change.
]]--
function PANEL:SetScroll( iScrollPos )
	if !self.Enabled then self.Scroll = 0; return end
	
	self.Scroll = math.floor( math.Clamp( iScrollPos, 0, self.CanvasSize ) );
	self:InvalidateLayout();
	
	local pnlParent = self:GetParent();
	if !IF.Util:IsPanel( pnlParent ) then return end

	local fn = pnlParent.OnVScroll;
	if !IF.Util:IsFunction( fn ) then return end
	
	local s, r = pcall( fn, pnlParent, self:GetScroll() );
	if !s then ErrorNoHalt( "Itemforge UI: Scrollbar called parent's OnVScroll but failed: "..r ); end
end

derma.DefineControl( "DVScrollBarItemforge", "A vertical scrollbar modified for Itemforge", PANEL, "DVScrollBar" );