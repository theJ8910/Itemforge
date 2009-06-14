/*
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
*/
local PANEL = {}

PANEL.Sizes={
	1,
	3,
	5,
	14,
	26,
	40,
	90,
}


--These materials correspond to the sizes listed above
PANEL.Materials={
	Material("itemforge/inventory/size_1"),
	Material("itemforge/inventory/size_2"),
	Material("itemforge/inventory/size_3"),
	Material("itemforge/inventory/size_4"),
	Material("itemforge/inventory/size_5"),
	Material("itemforge/inventory/size_6"),
	Material("itemforge/inventory/size_7"),
}

PANEL.IconWidth=16;
PANEL.IconHeight=16;
PANEL.CurrentSize=1;

--Current icon
PANEL.Material=PANEL.Materials[1];

function PANEL:Init()
	self:SetSize(self.IconWidth,self.IconHeight);
	self:SetAutoDelete(true);
end

--Set a size for this icon to display an icon for. 
function PANEL:SetIconSize(size)
	--Keep track of the current size
	self.CurrentSize=size;
	
	--[[
	Pick out the appropriate icon based on the size.
	To do this, we try to find a size in our list that exceeds the size provided.
	If we find it, we set the icon to the size icon one index below in the list (because we're rounding down)
	The default icon is the last icon (which is the biggest size listed). It is used in the case that a bigger size can't be found.
	]]--
	local x=table.getn(self.Sizes);
	if size>0 then
		for i=2,table.getn(self.Sizes) do
			if self.Sizes[i]>size then
				x=i-1;
				break;
			end
		end
	else
		x=1;
	end
	self.Material=self.Materials[x];
end

--Mouse over (going TODO something with this later)
function PANEL:OnCursorEntered()
end

--Draw the panel
function PANEL:Paint()
	if self.Material then
		surface.SetDrawColor(255,255,255,255);
		surface.SetMaterial(self.Material);
		surface.DrawTexturedRect(0,0,self:GetWide(),self:GetTall());
	end
		
	return true;
end

vgui.Register("ItemforgeSizeIcon", PANEL, "Panel");