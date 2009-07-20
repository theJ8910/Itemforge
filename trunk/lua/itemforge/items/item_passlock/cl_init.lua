--[[
item_passlock
CLIENT

This item is a password lock. It attaches to doors. This is a new version of an item that was in RPMod v2.
]]--

include("shared.lua");

local Forward=Vector(1,0,0);

ITEM.BackMat=Material("models/debug/debugwhite");
ITEM.BackColor=Color(136/255,148/255,140/255,1);

--Make a back polygon for this model using a mesh!
ITEM.BackCoords={
{["pos"]=Vector(0,3.0,5.5),		["normal"]=Forward},
{["pos"]=Vector(0,-3.0,5.5),	["normal"]=Forward},
{["pos"]=Vector(0,-3.0,-5.5),	["normal"]=Forward},
nil,
{["pos"]=Vector(0,3.0,-5.5),	["normal"]=Forward},
nil,
};
ITEM.BackCoords[4]=ITEM.BackCoords[3];
ITEM.BackCoords[6]=ITEM.BackCoords[1];

ITEM.Back=NewMesh();
ITEM.Back:BuildFromTriangles(ITEM.BackCoords);

--[[
Draws a back panel on an entity.
This is necessary because the keypad doesn't have a back panel.
That, and having a this in a function rather than a model means that we only draw the back when it needs to be drawn.
]]--
function ITEM:DrawBack(ent)
	--Make world matrix (NOTE: weird, the transformations were in the opposite order I expected them to be in...)
	local wm=Matrix();
	wm:Translate(ent:GetPos());
	wm:Rotate(ent:GetAngles());
	
	render.SetMaterial(self.BackMat);
	render.SetColorModulation(self.BackColor.r,self.BackColor.g,self.BackColor.b);
	render.SetBlend(self.BackColor.a);
	
	cam.PushModelMatrix(wm);
	self.Back:Draw();
	cam.PopModelMatrix();
end

--Pose model in item slot. I want it posed a certain way (standing upright)
function ITEM:OnPose3D(eEntity,PANEL)
	local min,max=eEntity:GetRenderBounds();
	local center=max-((max-min)*.5);			--Center, used to position 
	eEntity:SetAngles(Angle(0,(RealTime()+self:GetRand())*20,0));
	eEntity:SetPos(Vector(0,0,0)-(eEntity:LocalToWorld(center)-eEntity:GetPos()));
end

--Called when a model associated with this item needs to be drawn
function ITEM:OnDraw3D(eEntity,bTranslucent)
	self["base_lock"].OnDraw3D(self,eEntity,bTranslucent);
	if !self:GetAttachedEnt() then self:DrawBack(eEntity); end
end

--[[
The lock can have it's password set through it's right-click menu.
Likewise it also has all the options the base_lock has.
]]--
function ITEM:OnPopulateMenu(pMenu)
	self["base_lock"].OnPopulateMenu(self,pMenu);
	pMenu:AddOption("Set Password",function(panel) self:SendNWCommand("SetPassword") end);
end

--[[
Runs whenever the server requests this client to enter a password for this item.
]]--
function ITEM:AskForPassword(reqid,strQuestion)
	Derma_StringRequest("Password Lock",strQuestion,"",function(str) self:SendNWCommand("ReturnPassword",reqid,str) end,nil,"OK","Cancel");
end

IF.Items:CreateNWCommand(ITEM,"AskForPassword",function(self,...) self:AskForPassword(...) end,{"short","string"});
IF.Items:CreateNWCommand(ITEM,"ReturnPassword",nil,{"short","string"});
IF.Items:CreateNWCommand(ITEM,"SetPassword");