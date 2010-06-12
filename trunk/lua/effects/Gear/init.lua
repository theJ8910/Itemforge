--[[
Gear
CLIENT

When you attach gear to something with the GearAttach module, this effect is used to draw the gear.
This is automatically removed when the gear is :Remove() ed.
]]--
EFFECT.Ent=nil;
EFFECT.Max=Vector(0,0,0);
EFFECT.Min=Vector(0,0,0);

function EFFECT:Init(data)
	self.GearID = data:GetAttachment();
	self.Ent	= data:GetEntity();
	if !self.Ent then return false end
	
	self.Max	= self.Ent:OBBMaxs();
	self.Min	= self.Ent:OBBMins();
end

function EFFECT:Think()
	local gear = IF.GearAttach.Attachments[self.GearID];
	if !gear then return false;
	elseif !self.Ent || !self.Ent:IsValid() then gear:Remove(); return false end
	
	self:SetRenderBoundsWS(self.Ent:LocalToWorld(self.Min),self.Ent:LocalToWorld(self.Max))
	return true;
end

function EFFECT:Render()
	local gear = IF.GearAttach.Attachments[self.GearID];
	if !gear then return false end
	gear:PreDraw();
	gear:Draw();
end