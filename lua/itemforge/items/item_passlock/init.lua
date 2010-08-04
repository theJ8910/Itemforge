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

--[[
Every time we request a password on the server, we store a request
which contains the player we're asking, the callback function, and a timeout timer
in the item's Requests table. We create a requests table for every new password lock here:
]]--
function ITEM:OnInit()
	self.Requests={};
end

--[[
When we use the password lock, something happens depending on the state the password lock is in.
]]--
function ITEM:OnUse(pl)
	if self:GetAttachedEnt() || self:GetAttachedItem() then
		if self.Password=="" then
			self:SetPassword(pl);
		elseif self:IsAttachmentLocked() then
			self:RequestPassword(pl,"Enter password to unlock:",function(self,pl,string) self:Event("UnlockAttachment",false,pl,string) end);
		else
			self:RequestPassword(pl,"Enter password to lock:",function(self,pl,string) self:Event("LockAttachment",false,pl,string) end);
		end
	elseif self:InWorld() then	self:WorldAttach();
	else						self:EmitSound(self.DenySound);
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

--[[
Unlocks the attached entity if the password given matches this password.
]]--
function ITEM:LockAttachment(pl,password)
	if !pl then return self:BaseEvent("LockAttachment",false); end
	
	if password==self.Password then
		self:BaseEvent("LockAttachment");
		self:PasswordSuccess();
		return true;
	else
		self:PasswordFail();
		return false;
	end
end

--[[
Unlocks the attached entity if the password given matches this password.
]]--
function ITEM:UnlockAttachment(pl,password)
	if !pl then return self:BaseEvent("UnlockAttachment",false); end
	
	if password==self.Password then
		self:BaseEvent("UnlockAttachment");
		self:PasswordSuccess();
		return true;
	else
		self:PasswordFail();
		return false;
	end
end

--[[
This function is run in three cases:
	Whenever the client selects "Set Password" clientside (or uses an attached password lock without a password set).
	After the client enters the old password correctly.
	After the client enters the new password.
]]--
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

--[[
This function runs whenever the client is changing the password and enters the old password.
Continues to the next step if it was correct, or fails if it wasn't.
]]--
function ITEM:CheckOldPassword(pl,password)
	if password==self.Password then
		self:SetPassword(pl,nil,password);
		self:PasswordSuccess();
	else
		self:PasswordFail();
	end
end

--[[
Requests a password from a player. 
pl is the player we will ask for a password.
sQuestion is a string containing a question for the player; this is usually something like "Enter Password:".
fCallback runs when (or if) the player responds.
]]--
function ITEM:RequestPassword(pl,sQuestion,fCallback)
	local r={};
	r.Player=pl;
	r.Callback=fCallback;
	local i=table.insert(self.Requests,r);
	r.Timeout=self:SimpleTimer(60,self.ForgetRequest,i);
	
	self:SendNWCommand("AskForPassword",pl,i,sQuestion);
end

--[[
Cleans up a request that was temporarily stored.
Runs whenever the request is answered or times out.
]]--
function ITEM:ForgetRequest(reqid)
	local r=self.Requests[reqid];
	self:DestroyTimer(r.Timeout);
	self.Requests[reqid]=nil;
end

--[[
Whenever a password is requested and the player enters it,
this function runs to double check that the request is still valid,
that the player who responded was the same one we requested information from,
and finally to run the callback function and clean up the request.
]]--
function ITEM:ReturnPassword(pl,reqid,string)
	local request=self.Requests[reqid];
	if !request || pl!=request.Player then return false end
	request.Callback(self,pl,string);
	self:ForgetRequest(reqid);
end

IF.Items:CreateNWCommand(ITEM,"AskForPassword",nil,{"short","string"});
IF.Items:CreateNWCommand(ITEM,"ReturnPassword",function(self,...) self:ReturnPassword(...) end,{"short","string"});
IF.Items:CreateNWCommand(ITEM,"SetPassword",function(self,...) self:SetPassword(...) end);