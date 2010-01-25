--[[
Itemforge Item Timers
SHARED

This file implements functions to handles timers that can be set on individual items.
The difference between this and Garry's Mod timers is that the timers are connected to individual items; if an item is removed, any associated timers are stopped and removed.
This is really just abstracting from Garry's Mod timers, but I thought this would be useful for scripters so I made it.
]]--

--Don't modify/override these. They're either set automatically, don't need to be changed, or are listed here so I can keep track of them.
ITEM.Timers=nil;			--Timers started on this item are recorded here. When the item is removed, these timers are stopped.
ITEM.LastSimpleTimer=1;		--Last simple timer (recorded here so we don't search from the beginning every time)

--[[
* SHARED
* Protected

Starts a timer connected to this item.
See AdjustTimer below for an explanation of the arguments
]]--
function ITEM:CreateTimer(vID,delay,reps,fCallback,...)
	if !vID			then return self:Error("Couldn't create timer - timer ID not given! ID needs to be a string or number.\n") end
	if !delay		then return self:Error("Couldn't create timer - delay not given.\n") end
	if !reps		then return self:Error("Couldn't create timer - number of times to repeat not given.\n") end
	if !fCallback	then return self:Error("Couldn't create timer - function not given.\n")  end
	
	--Create timers collection if it hasn't been created already
	if !self.Timers then self.Timers={}; end
	
	--Remove an existing timer with this ID if there is one
	if self:HasTimer(vID) then self:DestroyTimer(vID) end
	
	self:AdjustTimer(vID,delay,reps,fCallback,...);
	self:StartTimer(vID);
	
	return true;
end
IF.Items:ProtectKey("CreateTimer");

--[[
* SHARED
* Protected

Starts a timer connected to this item.
Simple timers only runs once, and are assigned an unused unique ID (that is, this function will ALWAYS start a new timer).
fCallback should be the function that will be called when the timer ends. This function will be given this item as it's first argument.
Any other arguments given to StartTimer will be given to fCallback whenever it runs.
This returns the unique ID (a string) if successful, or false if unsuccessful.
]]--
function ITEM:SimpleTimer(delay,fCallback,...)
	if !delay		then return self:Error("Couldn't create simple timer - delay not given. \n") end
	if !fCallback	then return self:Error("Couldn't create simple timer - function not given. \n") end
	
	--Create timers collection if it hasn't been created already
	if !self.Timers then self.Timers={}; end
	
	--Find a unique ID to use
	local i=self.LastSimpleTimer;
	while self.Timers["simple_"..i]!=nil do
		i=i+1;
	end
	self.LastSimpleTimer=i;
	
	--Simple timers clean themselves up
	local s="simple_"..i;
	if self:CreateTimer(s,delay,1,function(...) self:DestroyTimer(s); fCallback(...) end,...) then
		return s;
	end
	
	return false;
end
IF.Items:ProtectKey("SimpleTimer");

--[[
* SHARED
* Protected

Creates a timer without starting it, or changes an existing timer.
vID should be a unique string or int that is used to identify this timer. Example: "ThrowTimer", "ExplodeTimer", "TickTimer", etc
delay should be the time (in seconds) to wait before calling the given function.
	This can be a fraction too like 2.5 seconds for 2 and a half seconds.
	A value of 0 does NOT trigger the timer right after calling this function. Instead, the timer will be triggered the next frame.
reps is an optional number of times this timer repeats before being removed.
	If this is nil or not given, this defaults to 1.
	A value of 0 will make the timer repeat indefinitely until it is removed/destroyed.
fCallback should be the function that will be called when the timer ends. This function will be given this item as it's first argument.
Any other arguments given to StartTimer will be given to fCallback whenever it runs. So if you did:
	function ITEM:WatchAlarm(player)
		player:PrintMessage(HUD_PRINTTALK,"BEEP BEEP! ALARM GOING OFF!\n");
	end
	function ITEM:SetAlarm()
		self:StartTimer("WatchTimer",5,1,self.WatchAlarm,self.Owner)
	end
Then five seconds after you run SetAlarm, WatchAlarm runs and tells the player you gave it that his watch is going off.
]]--
function ITEM:AdjustTimer(vID,delay,reps,fCallback,...)
	if !vID			then return self:Error("Couldn't adjust timer - timer ID not given! ID needs to be a string or number.\n") end
	if !delay		then return self:Error("Couldn't adjust timer - delay not given.\n") end
	if !reps		then return self:Error("Couldn't adjust timer - number of times to repeat not given.\n") end
	if !fCallback	then return self:Error("Couldn't adjust timer - function not given.\n") end
	
	--Create timers collection if it hasn't been created already
	if !self.Timers then self.Timers={}; end
	
	local ID="if_item"..self:GetID().."_"..vID;
	
	--Create this timer if it hasn't been created yet
	if !self:HasTimer(vID) then
		self.Timers[vID]=ID;
	end
	timer.Adjust(ID,delay,reps,fCallback,self,...);
end
IF.Items:ProtectKey("AdjustTimer");

--[[
* SHARED
* Protected

Starts (or restarts) a timer on this item
Returns true if the timer is [re]started, or false if not.
]]--
function ITEM:StartTimer(vID)
	if !self:HasTimer(vID) then return false end
	return timer.Start(self.Timers[vID]);
end
IF.Items:ProtectKey("StartTimer");

--[[
* SHARED
* Protected

Stops a timer on this item.
NOTE: Stopping a timer is not the same as pausing it; a timer must start all over (with StartTimer) after it has been stopped.

Returns true if the timer was stopped, or false if not.
]]--
function ITEM:StopTimer(vID)
	if !self:HasTimer(vID) then return false end
	return timer.Stop(self.Timers[vID]);
end
IF.Items:ProtectKey("StopTimer");

--[[
* SHARED
* Protected

Pauses a timer on this item.
NOTE: Pausing a timer is not the same as stopping it; when a timer is unpaused, it will continue where it left off (ex: if a 5 second timer is paused at 4 seconds, then 1 second after being unpaused it will finish)

Returns true if the timer WENT FROM RUNNING TO PAUSED.
Returns false for any other reason (timer was stopped, timer was already paused, there was no timer by that name)
]]--
function ITEM:PauseTimer(vID)
	if !self:HasTimer(vID) then return false end
	return timer.Pause(self.Timers[vID]);
end
IF.Items:ProtectKey("PauseTimer");

--[[
* SHARED
* Protected

Unpauses a timer on this item.
NOTE: Unpausing a timer is not the same as starting it; when a timer is unpaused, it will continue where it was paused. If the timer is restarted, then it starts the timer from the beginning again.

Returns true if the timer WENT FROM PAUSED TO RUNNING.
Returns false for any other reason (timer was stopped, timer was running, there was no timer by that name)
]]--
function ITEM:UnPauseTimer(vID)
	if !self:HasTimer(vID) then return false end
	return timer.UnPause(self.Timers[vID]);
end
IF.Items:ProtectKey("UnPauseTimer");
ITEM.UnpauseTimer=ITEM.UnPauseTimer;
IF.Items:ProtectKey("UnpauseTimer");

--[[
* SHARED
* Protected

Toggles the timer between paused and unpaused.

Returns true if the timer was paused or unpaused.
Returns false for any other reason (usually because timer was stopped or there was no timer by that name)
]]--
function ITEM:ToggleTimer(vID)
	if !self:HasTimer(vID) then return false end
	return timer.Toggle(self.Timers[vID]);
end
IF.Items:ProtectKey("ToggleTimer");

--[[
* SHARED
* Protected

Is there a timer with a certain ID on this item?
vID can be a string or integer.
Returns true if there's a timer with the given ID on this item, or false otherwise.
]]--
function ITEM:HasTimer(vID)
	return (self.Timers!=nil && self.Timers[vID]!=nil);
end
IF.Items:ProtectKey("HasTimer");

--[[
* SHARED
* Protected

Permanantly stops an active timer.
Returns false if the timer was not found or couldn't be stopped for some reason, and true if it was stopped successfully.
]]--
function ITEM:DestroyTimer(vID)
	if !vID then return self:Error("Couldn't destroy/remove timer - timer ID not given! ID needs to be a string or number.\n") end
	if !self:HasTimer(vID) then return false end
	
	timer.Destroy(self.Timers[vID]);
	self.Timers[vID]=nil;
end
IF.Items:ProtectKey("DestroyTimer");
ITEM.RemoveTimer=ITEM.DestroyTimer;
IF.Items:ProtectKey("RemoveTimer");

--[[
* SHARED
* Protected

Permanantly stops all active timers on this item.
Returns true if all timers were removed successfully (or if there were no timers).
]]--
function ITEM:DestroyAllTimers()
	if !self.Timers then return true end
	
	for k,v in pairs(self.Timers) do
		timer.Destroy(v);
	end
	self.Timers=nil;
	
	return true;
end
IF.Items:ProtectKey("DestroyAllTimers");
ITEM.RemoveAllTimers=ITEM.DestroyAllTimers;
IF.Items:ProtectKey("RemoveAllTimers");