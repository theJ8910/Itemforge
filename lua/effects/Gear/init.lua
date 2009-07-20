--[[
Gear
CLIENT

When you attach gear to something with the GearAttach module, this effect is used to draw the gear.
This is automatically removed when the gear is :Remove() ed.
]]--
EFFECT.Ent=nil;

function EFFECT:Init(data)
	self.GearID = data:GetScale();
	self.Ent	= data:GetEntity();
	self.Max	= self.Ent:OBBMaxs();
	self.Min	= self.Ent:OBBMins();
end

function EFFECT:Think()
	if !IF.GearAttach.Attachments[self.GearID] then return false end
	self:SetRenderBoundsWS(self.Ent:LocalToWorld(self.Min),self.Ent:LocalToWorld(self.Max))
	return true;
end

function EFFECT:Render()
	if !IF.GearAttach.Attachments[self.GearID] then return false end
	IF.GearAttach.Attachments[self.GearID]:Draw();
end