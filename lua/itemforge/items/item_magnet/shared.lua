--[[
item_magnet
SHARED

This item attracts other items to it. It can be turned on or off.

Icon by Karolis O.
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name			= "Item Magnet";
ITEM.Description	= "An object of mysterious origin, it attracts any items to it when turned on.";
ITEM.Size			= 8;
ITEM.WorldModel		= "models/Items/combine_rifle_ammo01.mdl";
ITEM.MaxHealth		= 300;
ITEM.Strength		= 150;
ITEM.Sounds			= {
	Sound( "buttons/button18.wav" ),
	Sound( "buttons/button19.wav" ),
	Sound( "ambient/levels/citadel/extract_loop1.wav" ),
};

if SERVER then
	ITEM.GibEffect	=	"metal";
else
	ITEM.Icon		=	Material( "itemforge/items/item_magnet" );
end

--Server only
if SERVER then




--[[
* SERVER
* Event

When the player uses the magnet it toggles it on / off.
]]--
function ITEM:OnUse( pl )
	self:Toggle();
	return true;
end

--[[
* SERVER

Turns the magnet on.
]]--
function ITEM:TurnOn()
	if self:GetNWBool( "On" ) == true then return true end
	
	self:SetNWBool( "On", true );
	self:StartThink();
	self:EmitSound( self.Sounds[1] );
	self:LoopingSound( self.Sounds[3], "MagnetPull" );
	self:WireOutput( "On", 1 );
end

--[[
* SERVER

Turns the magnet off.
]]--
function ITEM:TurnOff()
	if self:GetNWBool( "On" ) == false then return true end
	
	self:SetNWBool( "On", false );
	self:StopThink();
	self:EmitSound( self.Sounds[2] );
	self:StopLoopingSound( "MagnetPull" );
	self:WireOutput( "On", 0 );
end

--[[
* SERVER

Toggles the magnet on / off.
]]--
function ITEM:Toggle()
	if self:GetNWBool( "On" ) == true then	self:TurnOff();
	else									self:TurnOn();
	end
end

--[[
* SERVER
* Event

Each frame, grabs a list of items in the world and applies a force on them towards the magnet.

TODO: Getting a list of world items every frame can be laggy (due to table creation / garbage collection).
A better solution might be to update the list of world items on a timer, and eliminate all world items outside a certain range of the magnet.
]]--
function ITEM:OnThink()
	local t = IF.Items:GetWorld();
	t[ self:GetID() ] = nil;

	for k,v in pairs( t ) do
		local ent = v:GetEntity();
		if ent then
			local phys = ent:GetPhysicsObject();
			if phys && phys:IsValid() then
				local vDir = self:GetPos() - ent:GetPos();
				phys:ApplyForceCenter( ( self.Strength * ( 1 / math.log( 0.2 * ( vDir:Length() + 5 ) ) ) ) * vDir:GetNormal() );
			end
		end
	end
end

--[[
* SERVER
* Event
* WIRE

Wiremod can turn the magnet on / off.
]]--
function ITEM:GetWireInputs( eEntity )
	return Wire_CreateInputs( eEntity, { "On" } );
end

--[[
* SERVER
* Event
* WIRE

Wiremod can observe whether or not the magnet is on / off.
]]--
function ITEM:GetWireOutputs( eEntity )
	return Wire_CreateOutputs( eEntity, { "On" } );
end

--[[
* SERVER
* Event
* WIRE

When Wiremod wants to turn the magnet on / off we make it happen here.
]]--
function ITEM:OnWireInput( eEntity, strInput, vValue )
	if strInput == "On" then
		if value == 0 then	self:TurnOff();
		else				self:TurnOn();
		end
	end
end

--[[
* SERVER

The player can set the strength of the magnet with the slider on it's context menu.
This sends a console command to the server, which is reacted to here.
]]--
function ITEM:PlayerSetStrength( pl, iTo )
	if !self:Event( "CanPlayerInteract", false, pl ) then return false end
	self.Strength = math.Clamp( iTo, 0, 1000 );
end


IF.Items:CreateNWCommand( ITEM, "PlayerSetStrength", function( self, ... ) self:PlayerSetStrength( ... ) end, { "int" } );




--Client only
else




ITEM.GlowMat		= Material( "sprites/gmdm_pickups/light" );
ITEM.GlowColor		= Color( 255, 200, 0, 255 );
ITEM.GlowOffset		= Vector( 0, 0, 6.5 );

--[[
* CLIENT

Draws a glow sprite on an entity.
]]--
function ITEM:DrawGlow( eEntity )
	render.SetMaterial( self.GlowMat );
	render.DrawSprite( eEntity:LocalToWorld( self.GlowOffset ), 32, 32, self.GlowColor );
end

--[[
* CLIENT
* Event

In addition to drawing the magnet's model, we also draw a glow sprite if the magnet is on.
]]--
function ITEM:OnDraw3D( eEntity, bTranslucent )
	self:BaseEvent( "OnDraw3D", nil, eEntity, bTranslucent );

	if self:GetNWBool( "On" ) then
		self:DrawGlow( eEntity );
	end
	
end

--[[
* CLIENT
* Event
]]--
function ITEM:OnPopulateMenu( pnlMenu )
	local Slider = vgui.Create( "DSlider" );
		Slider:SetTrapInside( true );
		Slider:SetImage( "vgui/slider" );
		Slider:SetLockY( 0.5 );
		Slider:SetSize( 100, 13 );
		Slider:SetSlideX( 0.001 * self.Strength );
		Derma_Hook( Slider, "Paint", "Paint", "NumSlider" );
		Slider.TranslateValues = function( p, x, y )
			self:SendNWCommand( "PlayerSetStrength", x * 1000 );
			return x, y;
		end
	pnlMenu:AddPanel( Slider );
	self:BaseEvent( "OnPopulateMenu", nil, pnlMenu );
end

IF.Items:CreateNWCommand( ITEM, "PlayerSetStrength", nil, { "int" } );




end

IF.Items:CreateNWVar( ITEM, "On", "bool", false );

