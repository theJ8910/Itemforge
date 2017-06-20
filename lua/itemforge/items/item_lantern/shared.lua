--[[
item_lantern
SHARED

This item generates dynamic light. It can be turned on or off.
Set the color of the lantern to set the color of the light ( self:SetColor( Color( r, g, b, a ) ) )
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name					= "Lantern";
ITEM.Description			= "An electric lantern.";
ITEM.Weight					= 7000;
ITEM.Size					= 14;
ITEM.WorldModel				= "models/props/cs_italy/it_lantern1.mdl";


ITEM.SWEPHoldType			= "normal";

if SERVER then




ITEM.GibEffect				= "glass";




else




ITEM.WorldModelNudge		= Vector( 0, 0, 8 );




end

--Lantern
ITEM.Sounds			= {
	Sound( "buttons/button1.wav" ),
	Sound( "buttons/button4.wav" )
};

if CLIENT then

ITEM.GlowMat				= Material( "sprites/gmdm_pickups/light" );		--This glow sprite is drawn on the item while the item is on
ITEM.GlowOffset				= Vector( 0, 0, 3 );							--The glow sprite is offset from the center of the entity by this much.
ITEM.WorldModelNudgeHip		= Vector( -10, 0, 0 );
ITEM.WorldModelRotateHip	= Angle( 0, 0, -45 );

end

--Server only
if SERVER then




--[[
* SERVER

Whenever the lantern is used it's turned on or off.
]]--
function ITEM:OnUse( pl )
	self:Toggle();
	return true;
end

--[[
* SERVER

Turns the lantern on.
Nothing happens if it's already on.
]]--
function ITEM:TurnOn()
	if self:GetNWBool( "On" ) then return end
	
	self:SetNWBool( "On", true );
	self:EmitSound( self.Sounds[1] );
	self:WireOutput( "On", 1 );
end

--[[
* SERVER

Turns the lantern off.
Nothing happens if it's already off.
]]--
function ITEM:TurnOff()
	if !self:GetNWBool( "On" ) then return end
	
	self:SetNWBool( "On", false );
	self:EmitSound( self.Sounds[2] );
	self:WireOutput( "On", 0 );
end

--[[
* SERVER

If the lantern is on, turns it off, and vice versa.
]]--
function ITEM:Toggle()
	if self:GetNWBool( "On" ) then	self:TurnOff();
	else							self:TurnOn();
	end
end

--[[
* SERVER
* Event

The lantern can report whether or not it is on to Wiremod
]]--
function ITEM:GetWireOutputs( eEntity )
	return Wire_CreateOutputs( eEntity, { "On" } );
end

--[[
* SERVER
* Event

The lantern can be turned on/off with wiremod
]]--
function ITEM:GetWireInputs( eEntity )
	return Wire_CreateInputs( eEntity, { "On" } );
end

--[[
* SERVER
* Event

The lantern can be turned on/off with wiremod
]]--
function ITEM:OnWireInput( eEntity, strInputName, vValue )
	if strInputName == "On" then
		if vValue == 0 then	self:TurnOff();
		else				self:TurnOn();
		end
	end
end




--Client only
else




--[[
* CLIENT
* Event

We think clientside
]]--
function ITEM:OnInit()
	self:StartThink();
end

--[[
* CLIENT
* Event

For a constant glow, dynamic lights must be created/refreshed every frame.
The item must be on and in the world/held by a player.
]]--
function ITEM:OnThink()
	if !self:GetNWBool( "On" ) then return false end
	
	local eEntity = self:GetEntity() || self:GetWeapon();
	if !eEntity then return false end
	
	local dlight = DynamicLight( eEntity:EntIndex() );
	if !dlight then return end

	eEntity = ( self.WMAttach && self.WMAttach.ent ) || eEntity;
		
	local t				= CurTime() + self:GetRand();
	local r				= 256 + 8 * math.sin( 50 * t);
	local c				= self:GetColor();
	dlight.Pos			= eEntity:GetPos();
	dlight.r			= c.r;
	dlight.g			= c.g;
	dlight.b			= c.b;
	dlight.Brightness	= 5;
	dlight.Decay		= 2 * r;
	dlight.Size			= r;
	dlight.DieTime		= CurTime() + 0.2;
end

--[[
* CLIENT
* Event

Pose model in item slot.
I want it posed a certain way (standing upright)
]]--
function ITEM:OnPose3D( eEntity, pnlModelPanel )
	self:PoseUprightRotate( eEntity );
end

--[[
* CLIENT
* Event

Draws a glow sprite on an entity.
The entity varies depending on what is drawing.
]]--
function ITEM:DrawGlow( eEntity )
	local x = 62 + 2 * math.sin( 50 * ( CurTime() + self:GetRand() ) ) ;
	render.SetMaterial( self.GlowMat );
	render.DrawSprite( eEntity:LocalToWorld( self.GlowOffset ), x, x, self:GetColor() );
end

--[[
* CLIENT

Moves the lantern gear to the player's hand
]]--
function ITEM:SwapToHand()
	if self.WMAttach && self.WMAttach:ToAP( "anim_attachment_RH" ) then
		self.WMAttach:Show();
		self.WMAttach:SetOffset( self.WorldModelNudge );
		self.WMAttach:SetOffsetAngles( self.WorldModelRotate );		
	end
end

--[[
* CLIENT

Moves the lantern gear to the player's hip
]]--
function ITEM:SwapToHip()
	if self.WMAttach && self.WMAttach:ToBone( "ValveBiped.Bip01_Pelvis" ) then
		self.WMAttach:Show();
		self.WMAttach:SetOffset( self.WorldModelNudgeHip );
		self.WMAttach:SetOffsetAngles( self.WorldModelRotateHip );
	end
end

--[[
* CLIENT

When the player holds the lantern
]]--
function ITEM:OnHold( pl, eWeapon )
	self:BaseEvent( "OnHold", nil, pl, eWeapon );
	self:SimpleTimer( 0, self.DelayedHoldAction, pl, eWeapon );
end

--[[
* CLIENT

Calls shortly after a hold.
The world model attachment may not exist when OnHold calls,
so for the code in this function to work it needs to call a short amount of time after a hold.
]]--
function ITEM:DelayedHoldAction( pl, eWeapon )
	if pl:GetActiveWeapon() == eWeapon then	self:SwapToHand();
	else									self:SwapToHip();
	end
end

--[[
* CLIENT

Deploying the lantern moves the world model attachment to the player's hand
]]--
function ITEM:OnSWEPDeployIF()
	self:SwapToHand();
	
	if self.ItemSlot then self.ItemSlot:SetVisible( true ); end
end

--[[
* CLIENT

Holstering the lantern moves the world model attachment to the player's hip (Legend of Zelda: Twilight Princess anyone?)
]]--
function ITEM:OnSWEPHolsterIF()
	self:SwapToHip();
	
	if self.ItemSlot then self.ItemSlot:SetVisible( false ); end
end

--[[
* CLIENT
* Event

Draws a lantern glow
]]--
function ITEM:OnDraw3D( eEntity, bTranslucent)
	self:BaseEvent( "OnDraw3D", nil, eEntity, bTranslucent );
	if self:GetNWBool( "On" ) then self:DrawGlow( eEntity ) end
end




end

IF.Items:CreateNWVar( ITEM, "On", "bool", false );

