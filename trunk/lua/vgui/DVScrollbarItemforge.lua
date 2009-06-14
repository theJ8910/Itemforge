/*
DVScrollBarItemforge
CLIENT

Creates the DVScrollBarItemforge Derma control.
This Derma control is a modified version of the DVScrollBar control.
I have modified it to suit my needs... this scrollbar is identical to a DVScrollBar in every way except for the following:
*/
local PANEL = {}

function PANEL:Init()
end

--I removed the part that invalidated the layout of the parent - this scrollbar does not scroll something on the parent
function PANEL:SetEnabled(b)
	if !b then
		self.Offset=0;
		self:SetScroll(0);
		self.HasChanged=true;
	end
	
	self:SetMouseInputEnabled(b); 
	self:SetVisible(b);
	self:SetAutoDelete(true);
	self.Enabled=b;	 
end

--This function was multiplying the scroll amount by -2. This has been changed to -1.
function PANEL:OnMouseWheeled(dlta)
	if (!self:IsVisible()) then return false end
	
	return self:AddScroll(dlta*-1);
end

--This function was multiplying the scroll amount by 25, which I have removed.
--This is because the original was designed to scroll something on the parent and expected scroll amounts to be in terms of pixels.
function PANEL:AddScroll(dlta)
	local OldScroll = self:GetScroll();
	self:SetScroll(self:GetScroll()+dlta);
	
	return OldScroll == self:GetScroll();
end 

--This function has been modified a bit. I make sure that the scroll amount is set to a whole number, and I have removed the part that invalidated the layout of the parent. Lastly, the scroll amount is given to the parent's hook, rather than the offset.
function PANEL:SetScroll(scrll)
	if ( !self.Enabled ) then self.Scroll = 0 return end
	self.Scroll = math.floor(math.Clamp(scrll,0,self.CanvasSize));
	self:InvalidateLayout();
	
	local func = self:GetParent().OnVScroll;
	if func then
		func(self:GetParent(),self:GetScroll());
	end
end

derma.DefineControl("DVScrollBarItemforge", "A vertical scrollbar modified for Itemforge", PANEL, "DVScrollBar");  