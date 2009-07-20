--[[
item_magnet
SHARED

This item attracts other items to it. It can be turned on or off.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Item Magnet";
ITEM.Description="An object of mysterious origin, it attracts any items to it when turned on.";
ITEM.Base="item";
ITEM.WorldModel="models/Items/combine_rifle_ammo01.mdl";
ITEM.MaxHealth=300;
ITEM.Strength=150;
ITEM.Sounds={
	Sound("buttons/button18.wav"),
	Sound("buttons/button19.wav"),
	Sound("ambient/levels/citadel/extract_loop1.wav"),
};

--Server only
if SERVER then




function ITEM:OnUse(pl)
	self:Toggle();
	return true;
end

function ITEM:TurnOn()
	if self:GetNWBool("On")==true then return true end
	
	self:SetNWBool("On",true);
	self:StartThink();
	self:EmitSound(self.Sounds[1]);
	self:LoopingSound(self.Sounds[3],"MagnetPull");
	self:WireOutput("On",1);
end

function ITEM:TurnOff()
	if self:GetNWBool("On")==false then return true end
	
	self:SetNWBool("On",false);
	self:StopThink();
	self:EmitSound(self.Sounds[2]);
	self:StopLoopingSound("MagnetPull");
	self:WireOutput("On",0);
end

function ITEM:Toggle()
	if self:GetNWBool("On")==true then
		self:TurnOff();
	else
		self:TurnOn();
	end
end

function ITEM:OnThink()
	for k,v in pairs(IF.Items:GetAll()) do
		if v!=self then
			local ent=v:GetEntity();
			if ent then
				local phys=ent:GetPhysicsObject();
				if phys && phys:IsValid() then
					local dir=self:GetPos()-ent:GetPos();
					local force=dir:GetNormal()*(1/math.log((dir:Length()+5)*.2))*self.Strength;
					phys:ApplyForceCenter(force);
				end
			end
		end
	end
end

function ITEM:GetWireInputs(entity)
	return Wire_CreateInputs(entity,{"On"});
end

function ITEM:GetWireOutputs(entity)
	return Wire_CreateOutputs(entity,{"On"});
end

function ITEM:OnWireInput(entity,inputName,value)
	if inputName=="On" then
		if value==0 then	self:TurnOff();
		else				self:TurnOn();
		end
	end
end

function ITEM:PlayerSetStrength(pl,to)
	if !self:Event("CanPlayerInteract",false,pl) then return false end
	self.Strength=math.Clamp(to,0,1000);
end


IF.Items:CreateNWCommand(ITEM,"PlayerSetStrength",function(self,...) self:PlayerSetStrength(...) end,{"int"});




--Client only
else




ITEM.GlowMat=Material("sprites/gmdm_pickups/light");
ITEM.GlowColor=Color(255,200,0,255);
ITEM.GlowOffset=Vector(0,0,6.5);

--[[
Draws a glow sprite on an entity.
The entity varies depending on what is drawing.
]]--
function ITEM:DrawGlow(ent)
	if self:GetNWBool("On") then
		render.SetMaterial(self.GlowMat);
		render.DrawSprite(ent:LocalToWorld(self.GlowOffset),32,32,self.GlowColor);
	end
end

--Draw SWEP world model
function ITEM:OnSWEPDraw(eEntity,SWEP,bTranslucent)
	self["item"].OnSWEPDraw(self,eEntity,SWEP,bTranslucent);
	
	--TODO need to GetWorldModel() or something
	if SWEP.WM!=nil then
		self:DrawGlow(SWEP.WM.ent);
	end
end

--Called when a model associated with this item needs to be drawn
function ITEM:OnDraw3D(eEntity,bTranslucent)
	self["item"].OnDraw3D(self,eEntity,bTranslucent);
	self:DrawGlow(eEntity);
end

function ITEM:OnPopulateMenu(pMenu)
	local Slider = vgui.Create("DSlider");
		Slider:SetTrapInside(true);
		Slider:SetImage("vgui/slider");
		Slider:SetLockY(0.5);
		Slider:SetSize(100,13);
		Slider:SetSlideX(self.Strength*.001);
		Derma_Hook(Slider,"Paint","Paint","NumSlider");
		Slider.TranslateValues=function(p,x,y)
			self:SendNWCommand("PlayerSetStrength",x*1000);
			return x,y;
		end
	pMenu:AddPanel(Slider);
	self["item"].OnPopulateMenu(self,pMenu);
end

IF.Items:CreateNWCommand(ITEM,"PlayerSetStrength",nil,{"int"});




end

IF.Items:CreateNWVar(ITEM,"On","bool",false);

