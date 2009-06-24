--[[
Itemforge Item Sounds
SHARED

This file implements functions to play and manage looping and non-looping sounds.
]]--

--Don't modify/override these. They're either set automatically, don't need to be changed, or are listed here so I can keep track of them.
ITEM.LoopingSounds=nil;		--Whenever looping sounds are created, they are kept track of here.

--[[
Causes the item to emit a sound.
True is returned if the sound is played.
False is returned if the sound couldn't be played (probably because the item is in the void or otherwise couldn't be located).
]]--
function ITEM:EmitSound(sound,amp,pitch)
	--If the item is in the world, we'll emit from that entity.
	if self:InWorld() then
		local ent=self:GetEntity();
		ent:EmitSound(sound,amp,pitch);
		return true;
	elseif self:IsHeld() then
		local w=self:GetWeapon();
		if !w then return false end
		
		w:EmitSound(sound,amp,pitch);
		return true;
	elseif self:InInventory() then
		local pos=self:GetPos();
		local postype=type(pos);
		if postype=="Vector" then
			WorldSound(sound,pos,amp,pitch);
		elseif postype=="table" then
			for k,v in pairs(pos) do
				WorldSound(sound,pos,amp,pitch);
			end
		end
		return true;
	end
	
	return false;
end
IF.Items:ProtectKey("EmitSound");

--[[
Creates and then plays a looping sound on this item.
sound should be a Sound("soundname")
uniqueID should be a unique name like "EngineSound" or "MagnetPull" or something.
	You can use this to stop the looping sound by calling self:StopLoopingSound() below.
	If there is a sound playing with this unique ID already, the old sound will be stopped and the new sound will start playing.
Only works while the item is in the world.
Returns true if the sound was created successfully.
Returns false otherwise
]]--
function ITEM:LoopingSound(sound,uniqueID)
	if !self:InWorld() then return false end
	
	--Create the looping sounds table if it hasn't been created already
	if !self.LoopingSounds then self.LoopingSounds={}; end
	
	local newSound=CreateSound(self:GetEntity(),sound);
	newSound:Play();
	if self:IsLoopingSound(uniqueID) then
		self:StopLoopingSound(uniqueID);
	end
	self.LoopingSounds[uniqueID]=newSound;
	
	return true;
end
IF.Items:ProtectKey("LoopingSound");

--[[
Is there a looping sound with the given unique ID playing on this item?
Returns true if there is, false otherwise.
]]--
function ITEM:IsLoopingSound(uniqueID)
	return (self.LoopingSounds!=nil && self.LoopingSounds[uniqueID]!=nil);
end
IF.Items:ProtectKey("IsLoopingSound");

--[[
Stops a specific looping sound by uniqueID.
uniqueID is the name of a sound being played on this item. This is given when self:LoopingSound() is called (see above)
Returns true if there was a sound by the given uniqueID that was stopped,
and false otherwise.
]]--
function ITEM:StopLoopingSound(uniqueID)
	if !self:IsLoopingSound(uniqueID) then return false end
	self.LoopingSounds[uniqueID]:Stop();
	self.LoopingSounds[uniqueID]=nil;
	return true;
end
IF.Items:ProtectKey("StopLoopingSound");

--[[
Stops all looping sounds on this item.
Returns true if all looping sounds were stopped, false otherwise.
]]--
function ITEM:StopAllLoopingSounds()
	if !self.LoopingSounds then return true end
	for k,v in pairs(self.LoopingSounds) do
		v:Stop();
	end
	self.LoopingSounds=nil;
	return true;
end
IF.Items:ProtectKey("StopAllLoopingSounds");