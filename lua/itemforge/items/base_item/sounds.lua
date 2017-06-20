--[[
Itemforge Item Sounds
SHARED

This file implements functions to play and manage looping and non-looping sounds.
]]--

--Don't modify/override these. They're either set automatically, don't need to be changed, or are listed here so I can keep track of them.
ITEM.LoopingSounds		= nil;		--Whenever looping sounds are created, they are kept track of here.

--[[
* SHARED
* Protected

Causes the item to emit a sound.
If the item is in multiple locations (as it is when inside of an inventory linked to several objects) then the sound will be played at all of these locations.

To play a single sound you would do:
	item:EmitSound( "physics/metal/sawblade_stick1.wav" );

To play a random sound from a table, you would do:
	local SomeSounds = {
		Sound( "physics/metal/sawblade_stick1.wav" ),
		Sound( "physics/metal/sawblade_stick2.wav" ),
		Sound( "physics/metal/sawblade_stick3.wav" )
	}
		
	--...
		
	item:EmitSound( SomeSounds );

vSound is an optional value. If vSound is:
	nil / not given:
		No sound is played.
	A Sound( "path/file.wav" ):
		This sound is played.
	A table of Sound( "path/file.wav" ) (indexed by numbers in the normal 1, 2, 3, ..., n - 1, n way):
		A random sound in this table is played.

bPredicted is an optional true/false. The item must be held as a weapon for bPredicted to have any effect. If bPredicted is:
	true, when :EmitSound runs on the server it will play the sound on everybody except the owner, whose client is expected to play the sound seperately.
	false or not given, when :EmitSound runs on the server, the sound is played for everybody.
	The advantage of bPredicted is that it saves some bandwidth and the sound is heard immediately on the client if you predict it correctly.
	IMPORTANT NOTE: If you're playing a random sound from a table, and the sound is predicted (played seperately on the server and client), the person holding the item may hear one sound, and all other players may hear a different sound.
	
iAmp is an optional number that determines how much the volume of the sound should be amplified.
	This is expected to be an integer between 0 and 511, where
	0 results in a silent sound, and 511 results in the loudest possible version of this sound.
	100, the default, results in a sound at normal volume

iPitch is an optional number that determines the pitch of the sound.
	This is expected to be an integer between 0 and 255, where:
	0 is the lowest possible pitch and 255 is the highest possible pitch
	100, the default, results in a sound at normal pitch
	
true is returned if a sound is played as a result of this function.
false is returned if a sound is not played. This occurs in a few cases:
	The item is in the void or otherwise couldn't be located.
	An empty table is given for vSound.
	There were errors, in which case an error message is generated.
]]--
function ITEM:EmitSound( vSound, bPredicted, iAmp, iPitch )
	if !vSound					then return end
	if type( vSound ) == "table" then
		local c = #vSound;
		if c < 1				then return false end
		vSound = vSound[ math.random( 1, c ) ];
	end
	
	if type( vSound ) != "string"	then return self:Error("Couldn't play sound. The chosen sound filepath was a \""..type( vSound ).."\", not a \"string.\"") end
	
	--If the item is in the world, we'll emit from that entity.
	if self:InWorld() then
		local eEntity = self:GetEntity();
		eEntity:EmitSound( vSound, iAmp, iPitch );
		return true;
	elseif self:IsHeld() then
		local eEntity;
		if bPredicted then	eEntity = self:GetWeapon();
		else				eEntity = self:GetWOwner();
		end
		if !eEntity then return false end
		
		eEntity:EmitSound( vSound, iAmp, iPitch );
		return true;
	else
		local vPos = self:GetPos();
		local strPosType = type( vPos );
		if strPosType == "Vector" then
			WorldSound( vSound, vPos, iAmp, iPitch );
		elseif strPosType == "table" then
			for k, v in pairs( vPos ) do
				WorldSound( vSound, v, iAmp, iPitch );
			end
		else
			return false;
		end
		return true;
	end
end
IF.Items:ProtectKey( "EmitSound" );

--[[
* SHARED
* Protected

Creates and then plays a looping sound on this item.
Only works while the item is in the world.

vSound should be a Sound( "path/file.wav" ) or a table of Sound( "path/file.wav" ) (indexed by numbers in the normal 1, 2, 3, ..., n - 1, n way).
	For example, to play a single looping sound you would do:
		item:EmitSound( "weapons/physcannon/superphys_hold_loop.wav" );
	Or, to play a random sound from a table, you would do:
		local SomeSounds = {
			Sound( "weapons/physcannon/superphys_hold_loop.wav" ),
			Sound( "ambient/levels/citadel/extract_loop1.wav" )
		}
		
		--...
		
		item:LoopingSound( SomeSounds, "SomeUniqueID" );
strUniqueID should be a unique name like "EngineSound" or "MagnetPull" or something.
	Only one looping sound attached to this item can have this name at a time.
	You can use this to stop the looping sound by calling self:StopLoopingSound() below.
	If there is a sound playing with this unique ID already, the old sound will be stopped and the new sound will start playing.

Returns a CSoundPatch object if successful.
Returns nil otherwise.
]]--
function ITEM:LoopingSound( vSound, strUniqueID )
	if !vSound						then return self:Error( "Couldn't play looping sound. Sound filepath / sound table was not given!" ) end
	if !strUniqueID					then return self:Error( "Couldn't play looping sound. A unique ID was not given." ) end
	
	if type( vSound ) == "table" then
		local c = #vSound;
		if c < 1					then return self:Error( "Couldn't play looping sound. A sound table was given but was empty." ) end
		vSound = vSound[math.random( 1, c )];
	end
	
	if type( vSound ) != "string"	then return self:Error( "Couldn't play looping sound. The chosen sound filepath was a \""..type( vSound ).."\", not a \"string.\"") end
	
	--Create the looping sounds table if it hasn't been created already
	if !self.LoopingSounds then self.LoopingSounds = {}; end
	
	local eEntity = self:GetEntity() or self:GetWOwner();
	if !eEntity then return nil end
	
	local newSound = CreateSound( eEntity, vSound );
	newSound:Play();
	self:StopLoopingSound( strUniqueID );
	
	self.LoopingSounds[strUniqueID] = newSound;
	
	return newSound;
end
IF.Items:ProtectKey( "LoopingSound" );

--[[
* SHARED
* Protected

Is there a looping sound with the given unique ID playing on this item?
Returns true if there is, false otherwise.
]]--
function ITEM:IsLoopingSound( strUniqueID )
	return ( self.LoopingSounds != nil && self.LoopingSounds[strUniqueID] != nil );
end
IF.Items:ProtectKey( "IsLoopingSound" );

--[[
* SHARED
* Protected

Sets the volume of a looping sound to the given volume.
strUniqueID is the name of a sound being played on this item.
	This is given when self:LoopingSound() is called (see above)
iVolume is the number to set the volume to.
	100 is a normal volume. The volume ranges from 0 (silent) to 255 (extremely loud).
]]--
function ITEM:SetLoopingSoundVolume( strUniqueID, iVolume )
	if !self:IsLoopingSound( strUniqueID ) then return false end
	
	self.LoopingSounds[strUniqueID]:ChangeVolume( math.Clamp( iVolume, 0, 255 ) );
end
IF.Items:ProtectKey( "SetLoopingSoundVolume" );

--[[
* SHARED
* Protected

Sets the pitch of a looping sound to the given pitch.
strUniqueID is the name of a sound being played on this item.
	This is given when self:LoopingSound() is called (see above)
iPitch is the number to set the pitch to.
	100 is a normal pitch. The pitch ranges from 0 (inaudibly deep) to 255 (extremely high pitched).
]]--
function ITEM:SetLoopingSoundPitch( strUniqueID, iPitch )
	if !self:IsLoopingSound( strUniqueID ) then return false end
	
	self.LoopingSounds[strUniqueID]:ChangePitch( math.Clamp( iPitch, 0, 255 ) );
end
IF.Items:ProtectKey( "SetLoopingSoundPitch" );

--[[
* SHARED
* Protected

Stops a specific looping sound by strUniqueID.
strUniqueID is the name of a sound being played on this item.
	This is given when self:LoopingSound() is called (see above)
Returns true if there was a sound by the given strUniqueID that was stopped,
and false otherwise.
]]--
function ITEM:StopLoopingSound( strUniqueID )
	if !self:IsLoopingSound( strUniqueID ) then return false end
	self.LoopingSounds[strUniqueID]:Stop();
	self.LoopingSounds[strUniqueID] = nil;
	return true;
end
IF.Items:ProtectKey( "StopLoopingSound" );

--[[
* SHARED
* Protected

Stops all looping sounds on this item.
Returns true if all looping sounds were stopped, false otherwise.
]]--
function ITEM:StopAllLoopingSounds()
	if !self.LoopingSounds then return true end
	for k, v in pairs( self.LoopingSounds ) do
		v:Stop();
	end
	self.LoopingSounds = nil;
	return true;
end
IF.Items:ProtectKey( "StopAllLoopingSounds" );