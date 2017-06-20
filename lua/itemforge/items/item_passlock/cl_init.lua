--[[
item_passlock
CLIENT

This item is a password lock. It attaches to doors.
This is a new version of an item that was in RPMod v2.
]]--

include( "shared.lua" );

--Password Lock
ITEM.BackMat	= Material( "models/debug/debugwhite" );
ITEM.BackColor	= Color( 136/255, 148/255, 140/255, 1 );





--Make a back polygon for this model using a mesh!
if true then

local vFwd = Vector( 1, 0, 0 );

local BackCoords = {
{ ["pos"] = Vector( 0,  3,  5.5 ),	["normal"] = vFwd },
{ ["pos"] = Vector( 0, -3,  5.5 ),	["normal"] = vFwd },
{ ["pos"] = Vector( 0, -3, -5.5 ),	["normal"] = vFwd },
nil,
{ ["pos"] = Vector( 0,  3, -5.5 ),	["normal"] = vFwd },
nil,
};

BackCoords[4] = BackCoords[3];
BackCoords[6] = BackCoords[1];

ITEM.Back = NewMesh();
ITEM.Back:BuildFromTriangles( BackCoords );

end

--[[
* CLIENT

Draws a back panel on an entity.
This is necessary because the keypad doesn't have a back panel.
That, and having a this in a function rather than a model means that we only draw the back when it needs to be drawn.
]]--
function ITEM:DrawBack( eEntity )
	--Make world matrix (NOTE: weird, the transformations were in the opposite order I expected them to be in...)
	local wm = Matrix();
	wm:Translate( eEntity:GetPos() );
	wm:Rotate( eEntity:GetAngles() );
	
	render.SetMaterial( self.BackMat );
	render.SetColorModulation( self.BackColor.r, self.BackColor.g, self.BackColor.b );
	render.SetBlend( self.BackColor.a );
	
	cam.PushModelMatrix( wm );
	self.Back:Draw();
	cam.PopModelMatrix();
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

Called when a model associated with this item needs to be drawn
]]--
function ITEM:OnDraw3D( eEntity, bTranslucent )
	self:BaseEvent( "OnDraw3D", nil, eEntity, bTranslucent );
	if !self:GetAttachedEnt() then self:DrawBack( eEntity ); end
end

--[[
* CLIENT
* Event

The lock can have it's password set through it's right-click menu.
Likewise it also has all the options the base_lock has.
]]--
function ITEM:OnPopulateMenu( pnlMenu )
	self:BaseEvent( "OnPopulateMenu", nil, pnlMenu );
	pnlMenu:AddOption( "Set Password", function( pnl ) self:SendNWCommand( "SetPassword" ) end );
end

--[[
* CLIENT

Runs whenever the server requests this client to enter a password for this item.
]]--
function ITEM:AskForPassword( iReqID, strQuestion )
	Derma_StringRequest( "Password Lock", strQuestion, "", function( str ) self:SendNWCommand( "ReturnPassword", iReqID, str ) end, nil, "OK", "Cancel" );
end

IF.Items:CreateNWCommand( ITEM, "AskForPassword", function( self, ... ) self:AskForPassword( ... ) end, { "short", "string" } );
IF.Items:CreateNWCommand( ITEM, "ReturnPassword", nil,													{ "short", "string" } );
IF.Items:CreateNWCommand( ITEM, "SetPassword"																				  );