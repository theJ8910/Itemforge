--[[
item_lantern
SHARED

This item generates dynamic light. It can be turned on or off.
Set the color of the lantern to set the color of the light ( self:SetColor(Color(r,g,b,a)) )
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Lantern";
ITEM.Description="An electric lantern.";
ITEM.Weight=7000;
ITEM.Size=14;
ITEM.WorldModel="models/props/cs_italy/it_lantern1.mdl";
ITEM.Sounds={
	Sound("buttons/button1.wav"),
	Sound("buttons/button4.wav")
};

ITEM.HoldType="normal";

if SERVER then

ITEM.GibEffect = "glass";

else

ITEM.WorldModelNudge=Vector(0,0,8);

end


--Server only
if SERVER then




--[[
Whenever the lantern is used it's turned on or off.
]]--
function ITEM:OnUse(pl)
	self:Toggle();
	return true;
end

--[[
Turns the lantern on. Nothing happens if it's already on.
]]--
function ITEM:TurnOn()
	if self:GetNWBool("On") then return true end
	
	self:SetNWBool("On",true);
	self:EmitSound(self.Sounds[1]);
	self:WireOutput("On",1);
	return true;
end

--[[
Turns the lantern off. Nothing happens if it's already off.
]]--
function ITEM:TurnOff()
	if !self:GetNWBool("On") then return true end
	
	self:SetNWBool("On",false);
	self:EmitSound(self.Sounds[2]);
	self:WireOutput("On",0);
	return true;
end

--[[
If the lantern is on, turns it off, and vice versa.
]]--
function ITEM:Toggle()
	if self:GetNWBool("On") then return self:TurnOff();	end
	return self:TurnOn();
end

--[[
The lantern can report whether or not it is on to Wiremod
]]--
function ITEM:GetWireOutputs(entity)
	return Wire_CreateOutputs(entity,{"On"});
end

--[[
The lantern can be turned on/off with wiremod
]]--
function ITEM:GetWireInputs(entity)
	return Wire_CreateInputs(entity,{"On"});
end

--[[
The lantern can be turned on/off with wiremod
]]--
function ITEM:OnWireInput(entity,inputName,value)
	if inputName=="On" then
		if value==0 then	self:TurnOff();
		else				self:TurnOn();
		end
	end
end




--Client only
else




ITEM.GlowMat=Material("sprites/gmdm_pickups/light");	--This glow sprite is drawn on the item while the item is on
ITEM.GlowOffset=Vector(0,0,3.0);						--The glow sprite is offset from the center of the entity by this much.

--[[
We think clientside
]]--
function ITEM:OnInit()
	self:StartThink();
end

--[[
For a constant glow, dynamic lights must be created/refreshed every frame.
The item must be on and in the world/held by a player.
]]--
function ITEM:OnThink()
	if !self:GetNWBool("On") then return false end
	
	local ent=self:GetEntity() || self:GetWeapon();
	if !ent then return false end
	
	local dlight = DynamicLight(ent:EntIndex());
	if dlight then
		ent=(self.WMAttach && self.WMAttach.ent) || ent;
		
		local t=CurTime()+self:GetRand();
		local r=256 + math.sin(t*50) * 8;
		local c=self:GetColor();
		dlight.Pos = ent:GetPos();
		dlight.r = c.r;
		dlight.g = c.g;
		dlight.b = c.b;
		dlight.Brightness=5;
		dlight.Decay=r*2;
		dlight.Size=r;
		dlight.DieTime=CurTime()+0.2;
	end
end

--Pose model in item slot. I want it posed a certain way (standing upright)
function ITEM:OnPose3D(eEntity,PANEL)
	local r=(RealTime()+self:GetRand())*20;
	
	local min,max=eEntity:GetRenderBounds();
	local center=max-((max-min)*.5);			--Center, used to position 
	eEntity:SetAngles(Angle(0,r,0));
	eEntity:SetPos(Vector(0,0,0)-(eEntity:LocalToWorld(center)-eEntity:GetPos()));
end

--[[
Draws a glow sprite on an entity.
The entity varies depending on what is drawing.
]]--
function ITEM:DrawGlow(ent)
	if self:GetNWBool("On") then
		local x=62 + 2 * math.sin( (CurTime()+self:GetRand()) * 50) ;
		render.SetMaterial(self.GlowMat);
		render.DrawSprite(ent:LocalToWorld(self.GlowOffset),x,x,self:GetColor());
	end
end

function ITEM:SwapToHand()
	if self.WMAttach && self.WMAttach:ToAP("anim_attachment_RH") then
		self.WMAttach:Show();
		self.WMAttach:SetOffset(self.WorldModelNudge);
		self.WMAttach:SetOffsetAngles(self.WorldModelRotate);		
	end
end

function ITEM:SwapToHip()
	if self.WMAttach && self.WMAttach:ToBone("ValveBiped.Bip01_Pelvis") then
		self.WMAttach:Show();
		self.WMAttach:SetOffset(Vector(-10,0,0));
		self.WMAttach:SetOffsetAngles(Angle(0,0,-45));
	end
end

function ITEM:OnHold(pl,weapon)	
	self:BaseEvent("OnHold",nil,pl,weapon);
	--self:InheritedEvent("OnHold","base_item",nil,pl,weapon);
	--self["base_item"].OnHold(self,pl,weapon);
	
	if pl:GetActiveWeapon()==weapon then	self:SwapToHand();
	else									self:SwapToHip();
	end
end

--[[
Deploying the lantern moves the world model attachment to the player's hand
]]--
function ITEM:OnSWEPDeployIF()
	self:SwapToHand();
	
	if self.ItemSlot then self.ItemSlot:SetVisible(true); end
end

--[[
Holstering the lantern moves the world model attachment to the player's hip (Legend of Zelda: Twilight Princess anyone?)
]]--
function ITEM:OnSWEPHolsterIF()
	self:SwapToHip();
	
	if self.ItemSlot then self.ItemSlot:SetVisible(false); end
end


--Called when a model associated with this item needs to be drawn
function ITEM:OnDraw3D(eEntity,bTranslucent)
	self:BaseEvent("OnDraw3D",nil,eEntity,bTranslucent);
	self:DrawGlow(eEntity);
end




end

IF.Items:CreateNWVar(ITEM,"On","bool",false);

