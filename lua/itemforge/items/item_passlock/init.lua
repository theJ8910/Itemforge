--[[
item_passlock
SERVER

This item is a password lock. It attaches to doors.
This is a new version of an item that was in RPMod v2.
]]--

AddCSLuaFile( "shared.lua" );
AddCSLuaFile( "cl_init.lua" );

include( "shared.lua" );

--Password Lock
ITEM.Requests = nil;
ITEM.Password = "";

--[[
* SERVER
* Event

Every time we request a password on the server, we store a request
which contains the player we're asking, the callback function, and a timeout timer
in the item's Requests table. We create a requests table for every new password lock here:
]]--
function ITEM:OnInit()
	self.Requests = {};
end

--[[
* SERVER
* Event

When we use the password lock, something happens depending on the state the password lock is in.
]]--
function ITEM:OnUse( pl )
	if self:GetAttachedEnt() || self:GetAttachedItem() then
		if		self.Password == "" then		self:SetPassword( pl );
		elseif	self:IsAttachmentLocked() then	self:RequestPassword( pl, "Enter password to unlock:",	function( self, pl, str ) self:Event( "UnlockAttachment", false, pl, str ) end );
		else									self:RequestPassword( pl, "Enter password to lock:",	function( self, pl, str ) self:Event( "LockAttachment",   false, pl, str ) end );
		end
	elseif self:InWorld() then	self:WorldAttach();
	else						self:EmitSound( self.DenySound );
	end
	return true;
end

--[[
* SERVER

Password was entered successfully; play sound + temporary skin change
]]--
function ITEM:PasswordSuccess()
	local eEntity = self:GetEntity();
	if eEntity then
		eEntity:Fire( "skin", "1", 0 );
		eEntity:Fire( "skin", "0", 1 );
	end
	self:EmitSound( self.AllowSound );
end

--[[
* SERVER

Password was entered incorrectly; play sound + temporary skin change
]]--
function ITEM:PasswordFail()
	local eEntity = self:GetEntity();
	if eEntity then
		eEntity:Fire( "skin", "2", 0 );
		eEntity:Fire( "skin", "0", 1 );
	end
	self:EmitSound( self.DenySound );
end

--[[
* SERVER

Unlocks the attached entity if the password given matches this password.
]]--
function ITEM:LockAttachment( pl, strPassword )
	if !pl then return self:BaseEvent( "LockAttachment", false ); end
	
	if strPassword == self.Password then
		self:BaseEvent( "LockAttachment" );
		self:PasswordSuccess();
		return true;
	else
		self:PasswordFail();
		return false;
	end
end

--[[
* SERVER

Unlocks the attached entity if the password given matches this password.
]]--
function ITEM:UnlockAttachment( pl, strPassword )
	if !pl then return self:BaseEvent( "UnlockAttachment", false ); end
	
	if strPassword == self.Password then
		self:BaseEvent( "UnlockAttachment" );
		self:PasswordSuccess();
		return true;
	else
		self:PasswordFail();
		return false;
	end
end

--[[
* SERVER

This function is run in three cases:
	Whenever the client selects "Set Password" clientside (or uses an attached password lock without a password set).
	After the client enters the old password correctly.
	After the client enters the new password.
]]--
function ITEM:SetPassword( pl, strTo, strOldPass )
	if !strTo then
		if self.Password != "" && self.Password != strOldPass then
			self:RequestPassword( pl, "Enter the old password:", self.CheckOldPassword );
		else
			self:RequestPassword( pl, "Enter a new password:", self.SetPassword );
		end
	else
		self:EmitSound( self.SetPassSound );
		self.Password = strTo;
	end
end

--[[
* SERVER

This function runs whenever the client is changing the password and enters the old password.
Continues to the next step if it was correct, or fails if it wasn't.
]]--
function ITEM:CheckOldPassword( pl, strPassword )
	if strPassword == self.Password then
		self:SetPassword( pl, nil, strPassword );
		self:PasswordSuccess();
	else
		self:PasswordFail();
	end
end

--[[
* SERVER

Requests a password from a player. 

pl is the player we will ask for a password.
strQuestion is a string containing a question for the player.
	This is usually something like "Enter Password:".
fnCallback runs when (or if) the player responds.
]]--
function ITEM:RequestPassword( pl, strQuestion, fnCallback )
	local r = {};
	local i = table.insert( self.Requests, r );

	r.Player	= pl;
	r.Callback	= fnCallback;
	r.Timeout	= self:SimpleTimer( 60, self.ForgetRequest, i );
	
	self:SendNWCommand( "AskForPassword", pl, i, strQuestion );
end

--[[
* SERVER

Cleans up a request that was temporarily stored.
Runs whenever the request is answered or times out.
]]--
function ITEM:ForgetRequest( iReqID )
	local r = self.Requests[iReqID];
	self:DestroyTimer( r.Timeout );
	self.Requests[iReqID] = nil;
end

--[[
* SERVER

Whenever a password is requested and the player enters it,
this function runs to double check that the request is still valid,
that the player who responded was the same one we requested information from,
and finally to run the callback function and clean up the request.
]]--
function ITEM:ReturnPassword( pl, iReqID, str )
	local r = self.Requests[iReqID];
	if !r || pl != r.Player then return false end
	r.Callback( self, pl, str );

	self:ForgetRequest( iReqID );
end

IF.Items:CreateNWCommand( ITEM, "AskForPassword",	nil,													{ "short", "string" } );
IF.Items:CreateNWCommand( ITEM, "ReturnPassword",	function( self, ... ) self:ReturnPassword( ... ) end,	{ "short", "string" } );
IF.Items:CreateNWCommand( ITEM, "SetPassword",		function( self, ... ) self:SetPassword( ... )	 end						  );