--[[
item_keyboard
SHARED

A musical keyboard.
]]--

if SERVER then AddCSLuaFile("shared.lua"); end

ITEM.Name			= "Keyboard";
ITEM.Description	= "An innocent keyboard.";
ITEM.WorldModel		= "models/props/kb_mouse/keyboard.mdl";
ITEM.Size			= 13;
ITEM.Weight			= 1000;
ITEM.MaxHealth		= 250;

ITEM.Spawnable		= true;
ITEM.AdminSpawnable	= true;

--Keyboard Item

--[[
Each keyboard key corresponds to a piano key.
The keyboard key is the index, and the piano key is the sound at that index.
I've tried to set it up like FL Studio.
]]--
ITEM.Keys = {
[KEY_Z]			= Sound( "piano/pk_1.wav" ),
[KEY_S]			= Sound( "piano/pk_2.wav" ),
[KEY_X]			= Sound( "piano/pk_3.wav" ),
[KEY_D]			= Sound( "piano/pk_4.wav" ),
[KEY_C]			= Sound( "piano/pk_5.wav" ),
[KEY_V]			= Sound( "piano/pk_6.wav" ),
[KEY_Z]			= Sound( "piano/pk_7.wav" ),
[KEY_G]			= Sound( "piano/pk_8.wav" ),
[KEY_B]			= Sound( "piano/pk_9.wav" ),
[KEY_H]			= Sound( "piano/pk_10.wav" ),
[KEY_N]			= Sound( "piano/pk_11.wav" ),
[KEY_J]			= Sound( "piano/pk_12.wav" ),
[KEY_M]			= Sound( "piano/pk_13.wav" ),
[KEY_Q]			= Sound( "piano/pk_14.wav" ),
[KEY_2]			= Sound( "piano/pk_15.wav" ),
[KEY_W]			= Sound( "piano/pk_16.wav" ),
[KEY_3]			= Sound( "piano/pk_17.wav" ),
[KEY_E]			= Sound( "piano/pk_18.wav" ),
[KEY_R]			= Sound( "piano/pk_19.wav" ),
[KEY_5]			= Sound( "piano/pk_20.wav" ),
[KEY_T]			= Sound( "piano/pk_21.wav" ),
[KEY_6]			= Sound( "piano/pk_22.wav" ),
[KEY_Y]			= Sound( "piano/pk_23.wav" ),
[KEY_7]			= Sound( "piano/pk_24.wav" ),
[KEY_U]			= Sound( "piano/pk_25.wav" ),
[KEY_I]			= Sound( "piano/pk_26.wav" ),
[KEY_9]			= Sound( "piano/pk_27.wav" ),
[KEY_O]			= Sound( "piano/pk_28.wav" ),
[KEY_0]			= Sound( "piano/pk_29.wav" ),
[KEY_P]			= Sound( "piano/pk_30.wav" ),
[KEY_LBRACKET]	= Sound( "piano/pk_31.wav" ),
[KEY_EQUAL]		= Sound( "piano/pk_32.wav" ),
[KEY_RBRACKET]	= Sound( "piano/pk_33.wav" ),
--[[
[KEY_Z]			= Sound( "piano/pk_34.wav" ),
[KEY_Z]			= Sound( "piano/pk_35.wav" ),
[KEY_Z]			= Sound( "piano/pk_36.wav" ),
[KEY_Z]			= Sound( "piano/pk_37.wav" ),
[KEY_Z]			= Sound( "piano/pk_38.wav" ),
[KEY_Z]			= Sound( "piano/pk_39.wav" ),
[KEY_Z]			= Sound( "piano/pk_40.wav" ),
[KEY_Z]			= Sound( "piano/pk_41.wav" ),
[KEY_Z]			= Sound( "piano/pk_42.wav" ),
[KEY_Z]			= Sound( "piano/pk_43.wav" ),
[KEY_Z]			= Sound( "piano/pk_44.wav" ),
[KEY_Z]			= Sound( "piano/pk_45.wav" ),
[KEY_Z]			= Sound( "piano/pk_46.wav" ),
[KEY_Z]			= Sound( "piano/pk_47.wav" ),
[KEY_Z]			= Sound( "piano/pk_48.wav" ),
[KEY_Z]			= Sound( "piano/pk_49.wav" ),
]]--
};

ITEM.KeyWasDown	= nil;

--[[
* SHARED

When a key is pressed, translates the keycode to the appropriate sound and plays it.
If called on the client, tells the server to play the sound for the clients.
]]--
function ITEM:PlayKeySound( pl, iKey )
	if !self:Event( "CanPlayerInteract", false, pl ) then return false end
	
	local v = self.Keys[iKey];
	if !v then return false end
	
	self:EmitSound( v, true );
	if CLIENT then self:SendNWCommand( "PlaySoundOnServer", iKey ); end
	
	return true;
end

if CLIENT then

ITEM.LightMat	= Material( "sprites/gmdm_pickups/light" );
ITEM.LightColor	= Color( 0, 255, 0 );
ITEM.LightPos	= Vector( -2.9948, 9.9641, 0.3541 );

--[[
* CLIENT
* Event

Makes a table that keeps track of key-was-downs (to detect when keys are pressed).
]]--
function ITEM:OnInit()
	self.KeyWasDown = {};
end

--[[
* CLIENT
* Event

Toggles the keyboard on / off.
]]--
function ITEM:OnUse()
	self:ToggleFocus();
	return false;
end

--[[
* CLIENT

Draws a light on the keyboard.
]]--
function ITEM:DrawLight( eEntity )
	render.SetMaterial( self.LightMat );
	render.DrawSprite( eEntity:LocalToWorld( self.LightPos ), 8, 8, self.LightColor );
end

--[[
* CLIENT
* Event

In addition to drawing the keyboard, if the keyboard is on, draws a light to indicate it.
]]--
function ITEM:OnDraw3D( eEntity, bTranslucent )
	self:BaseEvent( "OnDraw3D", nil, eEntity, bTranslucent );
	if self.HasFocus then	self:DrawLight( eEntity ); end
end

--[[
* CLIENT

Toggles the usage of the keyboard between on and off.
]]--
function ITEM:ToggleFocus()
	self.HasFocus = !self.HasFocus;
	if self.HasFocus then	self:StartThink();
	else					self:StopThink();	self.KeyWasDown = {};
	end
end

--[[
* CLIENT

Tracks keypress states on the player's keyboard, and detects when a player presses a key
When a key press is detected, plays a sound corresponding to that key.
]]--
function ITEM:OnThink()
	if !self.HasFocus then return end
	for k,v in pairs( self.Keys ) do
		local bKeyIsDown = input.IsKeyDown( k );
		
		if bKeyIsDown && !self.KeyWasDown[k] then
			self:PlayKeySound( LocalPlayer(), k );
		end
		
		self.KeyWasDown[k] = bKeyIsDown;
	end
end




IF.Items:CreateNWCommand( ITEM, "PlaySoundOnServer", nil, { "int" } );




else




IF.Items:CreateNWCommand( ITEM, "PlaySoundOnServer", function( self, pl, eKey ) self:PlayKeySound( pl, eKey ) end, { "int" } );




end

