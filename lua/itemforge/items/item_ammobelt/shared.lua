--[[
item_ammobelt
SHARED

Ammunition belts link containers and weapons.
Linking a weapon to a container will allow the weapon to source ammo from that container.
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name			= "Ammunition Belt";
ITEM.Description	= "An ammuntion belt. This allows weapons to reload from a linked container.\n";
ITEM.StartAmount	= 500;
ITEM.MaxAmount		= 0;
ITEM.Weight			= 3;
ITEM.Size			= 5;

ITEM.WorldModel		= "models/props_interiors/pot01a.mdl";

ITEM.Spawnable		= true;
ITEM.AdminSpawnable	= true;

ITEM.SWEPHoldType	= "slam";

if SERVER then

resource.AddFile( "materials/itemforge/items/item_ammobelt_belt.vtf" );
resource.AddFile( "materials/itemforge/items/item_ammobelt_belt.vmt" );

else

ITEM.WorldModelNudge	= Vector( 0, -5, 0 );
ITEM.WorldModelRotate	= Angle( 90, 0, 90 );

end

--Ammo Belt
ITEM.Width				= 5;									--The belt is about this wide (in game units).
ITEM.Length				= 2 * ITEM.Width;						--This is actually related more to the texture. For every ITEM.Length game units, the texture needs to repeat, and this number helps us determine what UV coordinates we need to use to acheive this effect.

--[[
* SHARED
* Event

Returns the length of the ammo belt.
]]--
function ITEM:GetDescription()
	--Length of ammo belt in meters
	local len = 0.01 * math.floor( IF.Util:InchesToCM( self:GetAmount() ) );
	if len >= 1 then	return self.Description.."It is "..len..IF.Util:Pluralize( " meter", len ).." long.";
	else				return self.Description.."It is "..( 100 * len )..IF.Util:Pluralize(" centimeter", len ).." long."
	end
end

if CLIENT then




ITEM.BeltMaterial	= Material( "itemforge/items/item_ammobelt_belt" );	--We use this material for our model
ITEM.ModelDetail	= 2;												--Level of detail - smaller is more detailed (good looking, but more expensive to draw)
ITEM.SpiralSpacing	= 1.2;												--A point at theta = 0 degrees and a point at theta = 360 degrees are spaced this far apart (in game units)
ITEM.Spirals		= 5;												--This is the minimum # of spirals we want the ammo belt to have (the belt must pass through the x axis this many times in addition to the first time it touches it)

local vEast = Vector( 1, 0, 0 );

--[[
* CLIENT

Generates an archimedes spiral mesh for the ammo belt.

We create one segment (two polygons) per radial segment. Each radial segments have an arc-length equal to ModelDetail.
So, basically, the more spirals there are, the more spacing between spirals, and the lower the ModelDetail, the more polygons that get created.

fDetail should be the arc-length of the radial segments that polygons will be created between.
	The higher this number is the crappier it looks, but it's also easier to draw.
fSpacing should be the distance between any point at angle "t" and another point at angle "t + 2PI"
	For example, consider the two points on the spiral at angle 0 and angle 360.
	The distance between these two points is fSpacing.
fSpirals is the max number of revolutions that polygons are generated for.
	e.g. if this is 5, then it stops when the angle reaches 5 * 2PI.

Returns the new spiral Mesh().
]]--
local function GenerateSpiralMesh( fDetail, fSpacing, fSpirals )
	--Width constant
	local fW		= 0.5 * ITEM.Width;
	
	--Spacing constant; 0.1591549431 = 1 / (2 PI)
	local c			= 0.1591549431 * fSpacing;
	
	--Finished when fB exceeds this number; 6.2831853071796 = 2 PI
	local fFinished = 6.2831853071796 * fSpirals;
	
	local fR		= 0;
	local fB		= 0;
	local fLastX	= 0;
	local fLastY	= 0;
	local fX		= 0;
	local fY		= 0;
	local fV		= 0;
	local vNormal	= vEast;
	
	local MeshCoords = {};
	
	table.insert( MeshCoords, { ["pos"] = Vector( 0, 0, fW ),	["normal"] = vNormal,		["u"] = 0, ["v"] = 0 } );
	table.insert( MeshCoords, { ["pos"] = Vector( 0, 0, -fW ),	["normal"] = vNormal,		["u"] = 1, ["v"] = 0 } );
	
	repeat
		--We're going to generate new x/y coords for the next segment but need to remember what the last set of coords were
		fLastX	= fX;
		fLastY	= fY;
		
		--[[
		Some calculus and trigonometry here, we're trying to figure where the next segment should go on the archimedes spiral.
		To do this we need to know find "fB", the parameter that determines both the angle and the radius.
		The angle will be "fB" itself.
		From that we can calculate the normal with basic trigonometry.
		The radius "fR" of the spiral at that point will be equal to fSpacing * fB / 2PI (in other words, how far the spiral "travels" after one loop is determined by the spacing)
		]]--
		fB		= math.sqrt( 12.566370614359 * fDetail / fSpacing + fB * fB );	--12.566370614359 = 4 PI
		vNormal = Vector( math.cos( fB ), math.sin( fB ), 0 );
		fR		= c * fB;
		
		--Calculate new coords (vNormal.x and vNormal.y are cos( fB ) and sin( fB ) respectively; we don't bother recalculating them)
		fX		= fR * vNormal.x;
		fY		= fR * vNormal.y;
		
		--fV is the next v texture coordinate that will be used
		--This is calculated with fV + d / l.
		fV		= fV + math.sqrt( ( fX - fLastX ) * ( fX - fLastX ) + ( fY - fLastY ) * ( fY - fLastY ) ) / ITEM.Length;
		
		table.insert( MeshCoords, { ["pos"] = Vector( fX, fY, fW ),		["normal"] = vNormal,			["u"] = 0, ["v"] = fV }	);
		table.insert( MeshCoords, MeshCoords[#MeshCoords]																		);
		table.insert( MeshCoords, MeshCoords[#MeshCoords - 2]																	);

		table.insert( MeshCoords, { ["pos"] = Vector( fX, fY, -fW ),	["normal"] = vNormal,			["u"] = 1, ["v"] = fV }	);
		table.insert( MeshCoords, MeshCoords[#MeshCoords - 3]																	);
		table.insert( MeshCoords, MeshCoords[#MeshCoords - 1]																	);
		
	until fB > fFinished
	
	--These are extra coordinates that we'll get rid of
	MeshCoords[ #MeshCoords ] = nil;
	MeshCoords[ #MeshCoords ] = nil;

	local mesh = NewMesh();
	mesh:BuildFromTriangles( MeshCoords );
	return mesh;
end

ITEM.Mesh = GenerateSpiralMesh( ITEM.ModelDetail, ITEM.SpiralSpacing, ITEM.Spirals );


--[[
* CLIENT

Draws the ammo belt mesh on an entity.
]]--
function ITEM:DrawSpiralMesh( eEntity )
	--Make world matrix
	local wm = Matrix();
	wm:Translate( eEntity:GetPos() );
	wm:Rotate( eEntity:GetAngles() );
	
	render.SetMaterial( self.BeltMaterial );
	
	cam.PushModelMatrix( wm );
	self.Mesh:Draw();
	cam.PopModelMatrix();
end

--[[
* CLIENT
* Event

Makes the spiral ammo belt mesh model draw instead of the "real" model
]]--
function ITEM:OnDraw3D( eEntity, bTranslucent )
	--self:BaseEvent( "OnDraw3D", nil, eEntity, bTranslucent );
	self:DrawSpiralMesh( eEntity );
end

end