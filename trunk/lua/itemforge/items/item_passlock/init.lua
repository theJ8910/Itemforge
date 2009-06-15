--[[
item_passlock
SERVER

This item is a password lock. It attaches to doors. This is a new version of an item that was in RPMod v2.
]]--

AddCSLuaFile("shared.lua");
AddCSLuaFile("cl_init.lua");

include("shared.lua");

ITEM.Requests=nil;
ITEM.Password="";

function ITEM:OnInit()
	self.Requests={};
end

function ITEM:OnUse(pl)
	if self:InWorld() then
		local att=self:GetAttachedEnt();

		if att then
			if self.Password=="" then
				self:SetPassword(pl);
			else
				self:RequestPassword(pl,"Enter Password:",self.OpenAttachedEnt)
			end
		else
			self:WorldAttach();
		end
	else
		self:EmitSound(self.DenySound);
	end
	return true;
end

--[[
Password was entered successfully; play sound + temporary skin change
]]--
function ITEM:PasswordSuccess()
	local ent=self:GetEntity();
	if ent then
		ent:Fire("skin","1",0);
		ent:Fire("skin","0",1);
	end
	self:EmitSound(self.AllowSound);
end

--[[
Password was entered incorrectly; play sound + temporary skin change
]]--
function ITEM:PasswordFail()
	local ent=self:GetEntity();
	if ent then
		ent:Fire("skin","2",0);
		ent:Fire("skin","0",1);
	end
	self:EmitSound(self.DenySound);
end

function ITEM:OpenAttachedEnt(pl,password)
	if password==self.Password then
		if !self["base_lock"].OpenAttachedEnt(self) then return false end
		self:PasswordSuccess();
		return true;
	else
		self:PasswordFail();
		return false;
	end
end

function ITEM:SetPassword(pl,to,oldPass)
	if !to then
		if self.Password!="" && self.Password!=oldPass then
			self:RequestPassword(pl,"Enter the old password:",self.CheckOldPassword);
		else
			self:RequestPassword(pl,"Enter a new password:",self.SetPassword);
		end
	else
		self:EmitSound(self.SetPassSound);
		self.Password=to;
	end
end

function ITEM:CheckOldPassword(pl,password)
	if password==self.Password then
		self:SetPassword(pl,nil,password);
		self:PasswordSuccess();
	else
		self:PasswordFail();
	end
end

--Requests a password from a player. When (or if) he responds, fCallback runs.
function ITEM:RequestPassword(pl,sQuestion,fCallback)
	local r={};
	r.Player=pl;
	r.Callback=fCallback;
	local i=table.insert(self.Requests,r);
	r.Timeout=self:SimpleTimer(60,self.ForgetRequest,i);
	
	self:SendNWCommand("AskForPassword",pl,i,sQuestion);
end

function ITEM:ForgetRequest(reqid)
	local r=self.Requests[reqid];
	self:DestroyTimer(r.Timeout);
	self.Requests[reqid]=nil;
end

function ITEM:ReturnPassword(pl,reqid,string)
	local request=self.Requests[reqid];
	if !request || pl!=request.Player then return false end
	request.Callback(self,pl,string);
	self:ForgetRequest(reqid);
end

IF.Items:CreateNWCommand(ITEM,"AskForPassword",nil,{"short","string"});
IF.Items:CreateNWCommand(ITEM,"ReturnPassword",function(self,...) self:ReturnPassword(...) end,{"short","string"});
IF.Items:CreateNWCommand(ITEM,"SetPassword",ITEM.SetPassword);