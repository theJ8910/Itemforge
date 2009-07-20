/*
ItemforgeItemCard
CLIENT

Creates the ItemforgeItemCard VGUI control.
This control is used to display information about an item.
*/
local PANEL = {}

--What item is this panel displaying.
PANEL.Item=nil;

--Size icon
PANEL.SizeIcon=nil;
PANEL.SizeIconX=0;
PANEL.SizeIconY=0;

function PANEL:Init()
	--Create size limit icon
	self.SizeIcon=vgui.Create("ItemforgeSizeIcon",self);
	self.SizeIcon:SetPos(self.SizeIconX,self.SizeIconY);
end

function PANEL:Paint()
	surface.SetDrawColor(255,255,255,255);
	
	--[[
	surface.SetFont("ItemforgeInventoryFont");
	surface.SetTextColor(self.WeightLabelTextColor.r,self.WeightLabelTextColor.g,self.WeightLabelTextColor.b,self.WeightLabelTextColor.a);
	surface.SetTextPos(self.WeightLabelX,self.WeightLabelY);
	surface.DrawText(self.Inventory:GetWeightFree().."kg/"..self.Inventory:GetWeightCapacity().."kg");
	]]--
	
	return true;
end

function PANEL:SetItem(item)
end