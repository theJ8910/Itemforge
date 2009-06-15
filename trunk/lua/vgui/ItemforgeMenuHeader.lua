/*
ItemforgeMenuHeader
CLIENT

Creates the ItemforgeMenuHeader VGUI control.
This panel displays the name of an item at the top of an Item's right-click menu.
*/
local PANEL = {}

--What color is the text and background
PANEL.TextColor=Color(0,0,0,255);
PANEL.Color=Color(255,201,0,255);

function PANEL:Init()
	--Create the black text on the header
	self.Label=Label("",self)
	self.Label:SetTextColor(self.TextColor);
	self.Label:SetContentAlignment(4);		--Align left
	self.Label:SetTextInset(5);
	--This panel takes up 20 pixels on the menu
	self:SetTall(20);
end

--Runs when this panel is resized or otherwise needs to be reconfigured
function PANEL:PerformLayout()
	self.Label:SetPos(0,3);
end

--Sets the header text
function PANEL:SetText(str)
	self.Label:SetText(str);
	self.Label:SizeToContents();
end

--Draw the panel
function PANEL:Paint()
	surface.SetDrawColor(self.Color.r,self.Color.g,self.Color.b,self.Color.a);
	surface.DrawRect(0,0,self:GetSize());
	return true;
end

vgui.Register("ItemforgeMenuHeader", PANEL, "Panel");