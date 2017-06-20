--[[
ItemforgeSizeIcon
CLIENT

Creates the ItemforgeSizeIcon VGUI control.
This panel is simply an image that takes a size and displays an icon.
It's used to display the size of items, and size limit for inventories.

Item size has nothing to do with weight, it has more to do with how much space it occupies. A car would occupy more space than a coin, for example.
The main reason item size exists is to let you make containers that can only hold small items.
A size icon is displayed on the card for an item, to give the player an idea what size the item is.
A size icon will also be displayed on an inventory to give the player an idea how large items that can be put inside it can be.
Each size in Sizes corresponds to an icon in Materials. If a size falls between two numbers, lets say "3" falls "1" and "4", it's rounded down, so the icon for "1" is displayed.
]]--

local PANEL = {};

PANEL.Sizes = {
	1,
	3,
	5,
	14,
	26,
	40,
	90,
}


--These materials correspond to the sizes listed above
PANEL.Materials = {
	Material( "itemforge/inventory/size_1" ),
	Material( "itemforge/inventory/size_2" ),
	Material( "itemforge/inventory/size_3" ),
	Material( "itemforge/inventory/size_4" ),
	Material( "itemforge/inventory/size_5" ),
	Material( "itemforge/inventory/size_6" ),
	Material( "itemforge/inventory/size_7" ),
}

PANEL.IconWidth		= 16;
PANEL.IconHeight	= 16;
PANEL.CurrentSize	= 1;

--Current icon
PANEL.Material		= PANEL.Materials[1];

--[[
* CLIENT
* Event

Sets the icon's size to it's default
]]--
function PANEL:Init()
	self:SetSize( self.IconWidth, self.IconHeight );
	self:SetAutoDelete( true );
end

--[[
* CLIENT

Set a size for this icon to display an icon for. 
]]--
function PANEL:SetIconSize( iSize )
	--Keep track of the current size
	self.CurrentSize = iSize;

	local x = 1;
	while x < #self.Sizes && iSize > self.Sizes[x + 1] do
		x = x + 1;
	end
	self.Material = self.Materials[x];
end

--[[
* CLIENT
* Event

Mouse over (going TODO something with this later)
]]--
function PANEL:OnCursorEntered()
end

--[[
* CLIENT
* Event

Draws the panel
]]--
function PANEL:Paint()
	if self.Material then
		surface.SetDrawColor( 255, 255, 255, 255 );
		surface.SetMaterial( self.Material );
		surface.DrawTexturedRect( 0, 0, self:GetWide(), self:GetTall() );
	end
		
	return true;
end

vgui.Register( "ItemforgeSizeIcon", PANEL, "Panel" );