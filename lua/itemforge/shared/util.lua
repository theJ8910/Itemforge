--[[
Itemforge Utilities module
SERVER

This module has a few extra bits of functionality that don't belong elsewhere
TODO: Datatype recognition could possibly be improved by comparing against an object's metatable
]]--

MODULE.Name			= "Util";										--Our module will be stored at IF.Util
MODULE.Disabled		= false;										--Our module will be loaded
MODULE.RopeEndClass	= "rope_end";									--Loose rope end entity created after a rope is cut

--These are enums corresponding to types of data
local DTYPE_BOOLEAN		= 1;
local DTYPE_NUMBER		= 2;
local DTYPE_STRING		= 3;
local DTYPE_TABLE		= 4;
local DTYPE_FUNCTION	= 5;
local DTYPE_VECTOR		= 6;
local DTYPE_ANGLE		= 7;
local DTYPE_PANEL		= 8;

--Every datatype beneath here needs to be an entity datatype
local DTYPE_ENTITY		= 8;
local DTYPE_PLAYER		= 9;
local DTYPE_WEAPON		= 10;
local DTYPE_NPC			= 11;
local DTYPE_VEHICLE		= 12;

--Lookup table for faster type comparisons
local StringToType = {
	["boolean"]		=	DTYPE_BOOLEAN,
	["number"]		=	DTYPE_NUMBER,
	["string"]		=	DTYPE_STRING,
	["table"]		=	DTYPE_TABLE,
	["function"]	=	DTYPE_FUNCTION,
	["Vector"]		=   DTYPE_VECTOR,
	["Angle"]		=	DTYPE_ANGLE,
	["Panel"]		=	DTYPE_PANEL,
	["Entity"]		=   DTYPE_ENTITY,
	["Player"]		=   DTYPE_PLAYER,
	["Weapon"]		=	DTYPE_WEAPON,
	["NPC"]			=	DTYPE_NPC,
	["Vehicle"]		=	DTYPE_VEHICLE
};

--These folders are not valid
local BadFolders = {
	[".."]		= true,
	["."]		= true,
	[".svn"]	= true
};

--Vars related to File Cache and FileSend
local FileCache				= {};
local FileSendInProgress	= false;
local FileSendCurrentFile	= "";
local FileSendCurrentChar	= 0;
local FileSendTotalChars	= 0;
local FileSendCharsPerTick	= 230;
local FileSendPlayer		= nil;

--Taskqueue class
local _TASKQUEUE = {};

--Frequently used variables / constants
local strRopeClass	= "phys_lengthconstraint";		--Rope physic constraint classname
local strGlassClass = "func_breakable_surf";		--Breakable, fragmented glass entity classname

local vZero		= Vector(  0,  0,  0 );
local vPosX		= Vector(  1,  0,  0 );
local vNegX		= Vector( -1,  0,  0 );
local vPosY		= Vector(  0,  1,  0 );
local vNegY		= Vector(  0, -1,  0 );
local vPosZ		= Vector(  0,  0,  1 );
local vNegZ		= Vector(  0,  0, -1 );

local tSamplePoints = {								--Reused by the FindGlassPlane function so new table / vectors don't have to be created every time
	Vector( 0, 0, 0 ),
	Vector( 0, 0, 0 ),
	Vector( 0, 0, 0 ),
	Vector( 0, 0, 0 ),
	Vector( 0, 0, 0 ),
	Vector( 0, 0, 0 ),
	Vector( 0, 0, 0 ),
	Vector( 0, 0, 0 ),
	Vector( 0, 0, 0 )
};

--[[
* SHARED

Helper function; sets an existing vector v's components to x, y, z
]]--
local function SetVector( v, x, y, z )
	v.x = x;
	v.y = y;
	v.z = z;
end

--[[
* SHARED

Initilize util module.
Miscellaneous hooks are added here.
]]--
function MODULE:Initialize()
	IF.Base:RegisterClass( _TASKQUEUE, "TaskQueue" );
	hook.Add( "OnEntityCreated", "itemforge_util_entcreated", function( ... ) self:EntityCreated( ... ) end );
end

--[[
* SHARED

Cleanup util module
]]--
function MODULE:Cleanup()
	hook.Remove( "OnEntityCreated", "itemforge_util_entcreated" );
end

--[[
* SHARED
* Event

If a window is created we need to cache it's glass pane
]]--
function MODULE:EntityCreated( eNewEnt )
	if eNewEnt:IsValid() && eNewEnt:GetClass() == strGlassClass then
		timer.Simple( 0, self.CacheGlassPlane, self, eNewEnt );
	end
end

--[[
* SHARED

Used for checking arguments for errors.
Returns true if the parameter is a boolean or false otherwise
]]--
function MODULE:IsBoolean( vParam )
	return StringToType[type( vParam )] == DTYPE_BOOLEAN;
end

--[[
* SHARED

Used for checking arguments for errors.
Returns true if the parameter is a number or false otherwise
]]--
function MODULE:IsNumber( vParam )
	return StringToType[type( vParam )] == DTYPE_NUMBER;
end

--[[
* SHARED

Checks to see if a given parameter falls on one of or between the two given numbers.
Used for checking arguments for errors.
Expects fNum to be a number.

Returns true if fNum is
	above or equal to fMin,
	and below or equal to fMax

and false otherwise.
]]--
function MODULE:IsInRange( fNum, fMin, fMax )
	return fNum >= fMin && fNum <= fMax;
end

--[[
* SHARED

Returns true if the parameter is a number and is greater than 0, and false otherwise.
]]--
function MODULE:IsPositive( vParam )
	return self:IsNumber( vParam ) && vParam > 0;
end

--[[
* SHARED

Returns true if the parameter is a number and is less than 0, and false otherwise.
]]--
function MODULE:IsNegative( vParam )
	return self:IsNumber( vParam ) && vParam < 0;
end

--[[
* SHARED

Returns true if the parameter is a string.
]]--
function MODULE:IsString( vParam )
	return StringToType[type( vParam )] == DTYPE_STRING;
end

--[[
* SHARED

Takes a string (such as "rock") and a count of how many
of these things there are (such as 5).

fCount is a number that can possibly be fractional. If fCount isn't 1:
	If no plural string was given, "s" is added to the end of the first string given
	("rocks" in our case), and then returned; or, if a plural string was given, that string is returned instead (such as "gravel").

Returns the pluralized string.
]]--
function MODULE:Pluralize( strSingular, fCount, strPlural )
	return ( fCount != 1 && ( strPlural || strSingular.."s" ) ) || strSingular;
end

--[[
* SHARED

If you're going to set the text on a VGUI / Derma label, run it through this function first.
Some characters (like &) have special meaning to VGUI, and need to be sanitized to be displayed on a label.

strLabel is the original text.

Returns a sanitized version of the original text.
]]--
function MODULE:LabelSanitize( strLabel )
	return string.gsub( strLabel, "&", "&&" );
end

--[[
* SHARED
Takes a table, and returns a string listing the contents of the table like so:
	Element 1, Element 2, Element 3

tList should be the table you want to list the contents of.
	The contents are automatically converted to strings with tostring(),
	so the actual data stored in the table can be whatever you want.
bOrdered is an optional true/false.
	If bOrdered is false / not given, then you're saying the order the contents are listed in is not important.
	If bOrdered is true, then the contents are listed according to their #.
	NOTE: If bOrdered is true, only the numbered contents are output (e.g. table[1], table[2], etc)

If the given table is empty, or a table wasn't given, returns an empty string.
Otherwise, returns a string describing the contents, each seperated by a comma and a space.
]]--
function MODULE:CommaSeperatedList( tList, bOrdered )
	if !self:IsTable( tData ) then return "" end

	if bOrdered == true then

		return table.concat( tList, ", " );

	else

		local iListLength = table.Count( tList );
		local strCommaList = "";

		for k, v in pairs( tList ) do
			if iListLength > 1 then	strCommaList = strCommaList..tostring( v )..", " 
			else					strCommaList = strCommaList..tostring( v )
			end

			iListLength = iListLength - 1;
		end

		return strCommaList;

	end
end

--[[
* SHARED

Returns true if the parameter is a table, and false otherwise.
]]--
function MODULE:IsTable( vParam )
	return StringToType[type( vParam )] == DTYPE_TABLE;
end

--[[
* SHARED

Returns true if the parameter is a color, and false otherwise.
]]--
function MODULE:IsColor( vParam )
	return self:IsTable( vParam ) && self:IsNumber( vParam.r ) && self:IsNumber( vParam.g ) && self:IsNumber( vParam.b ) && self:IsNumber( vParam.a );
end

--[[
* SHARED

Takes a color and makes sure the values are clamped between 0 and 255.
Doesn't return a new color, just modifies the one you give it.

tColor should be a color table (it should contain r, g, b, a, each a number)
]]--
function MODULE:ClampColor( tColor )
	tColor.r = math.Clamp( tColor.r, 0, 255 );
	tColor.g = math.Clamp( tColor.g, 0, 255 );
	tColor.b = math.Clamp( tColor.b, 0, 255 );
	tColor.a = math.Clamp( tColor.a, 0, 255 );
end

--[[
* SHARED

Returns true if the parameter is a function, and false otherwise.
]]--
function MODULE:IsFunction( vParam )
	return StringToType[type( vParam )] == DTYPE_FUNCTION;
end

--[[
* SHARED

Returns true if the parameter is a vector, and false otherwise.
]]--
function MODULE:IsVector( vParam )
	return StringToType[type( vParam )] == DTYPE_VECTOR;
end

--[[
* SHARED

Returns a random point in the given AABB.

vAABBMins and vAABBMaxs are vectors containing the mins and maxs of the AABB (respectively).
]]--
function MODULE:RandomVectorInAABB( vMin, vMax )
	return Vector( math.Rand( vMin.x, vMax.x ),
				   math.Rand( vMin.y, vMax.y ),
				   math.Rand( vMin.z, vMax.z )
				 );
end

--[[
* SHARED

Returns true if the parameter is an angle, and false otherwise.
]]--
function MODULE:IsAngle( vParam )
	return StringToType[type( vParam )] == DTYPE_ANGLE;
end

--[[
* SHARED

Returns an angle, whose pitch, yaw, and roll are random values that fall
between the two pitches, two yaws, and two rolls from angMin and angMax.

angMin and angMax can have the same values, but angMin's pitch/yaw/roll values
should never be more than the corresponding values in angMax.

angMin is an optional angle.
	If this is not given, the returned angle will be an angle whose
	pitch/yaw/roll is a random number between 0 and 360.
angMax is an angle that must be given if angMin is given.
]]--
function MODULE:RandomAngle( angMin, angMax )
	if !angMin then
		return Angle( math.Rand( 0, 360 ),
					  math.Rand( 0, 360 ),
					  math.Rand( 0, 360 )
					);
	end
	return Angle( math.Rand( angMin.p, angMax.p ),
				  math.Rand( angMin.y, angMax.y ),
				  math.Rand( angMin.r, angMax.r )
				);
end

--[[
* SHARED

Returns true if the parameter is a panel, and false otherwise.
]]--
function MODULE:IsPanel( vParam )
	return StringToType[type( vParam )] == DTYPE_PANEL;
end

--[[
* SHARED

Returns true if the given param is a valid entity of any type.
]]--
function MODULE:IsEntity( vParam )
	local n = StringToType[type( vParam )];
	return n != nil && n >= DTYPE_ENTITY && vParam:IsValid();
end

--[[
* SHARED

Returns true if the given param is a valid player, and false otherwise.
]]--
function MODULE:IsPlayer( vParam )
	return StringToType[type( vParam )] == DTYPE_PLAYER && vParam:IsValid();
end

--[[
* SHARED

Returns true if the given param is a valid weapon, and false otherwise.
]]--
function MODULE:IsWeapon( vParam )
	return StringToType[type( vParam )] == DTYPE_WEAPON && vParam:IsValid();
end

--[[
* SHARED

Returns true if the given param is a valid NPC, and false otherwise.
]]--
function MODULE:IsNPC( vParam )
	return StringToType[type( vParam )] == DTYPE_NPC && vParam:IsValid();
end

--[[
* SHARED

Returns true if the given param is a valid Vehicle, and false otherwise.
]]--
function MODULE:IsVehicle( vParam )
	return StringToType[type( vParam )] == DTYPE_VEHICLE && vParam:IsValid();
end

--[[
* SHARED

Returns true if the given param is a valid Itemforge object, and false otherwise.
TODO: This function isn't particularly reliable at the moment... any table with an IsValid that returns true would pass...
]]--
function MODULE:IsIFObject( vParam )
	return ( self:IsTable( vParam ) && self:IsFunction( vParam.IsValid ) && vParam:IsValid() );
end

--Note to self: the bottom two functions assume that InheritsFrom exists, and it should so long as IsIFObject() correctly identifies an IF object.

--[[
* SHARED

Returns true if the given param is a valid Itemforge item, and false otherwise.
]]--
function MODULE:IsItem( vParam )
	--Items are valid IF objects that inherit from the base item type. 
	return ( self:IsIFObject( vParam ) && vParam:InheritsFrom( IF.Items:GetBaseItemType() ) );
end

--[[
* SHARED

Returns true if the given param is a valid Itemforge inventory, and false otherwise.
]]--
function MODULE:IsInventory( vParam )
	--Inventories are valid IF objects that inherit from the base inventory. 
	return ( self:IsIFObject( vParam ) && vParam:InheritsFrom( IF.Inv:GetBaseInventoryType() ) );
end

--A shorter alias
MODULE.IsInv = MODULE.IsInventory;

--[[
* SHARED

Returns true if the given point is inside of the AABB (inclusive).
Returns false otherwise.
]]--
function MODULE:IsPointInAABB( vPoint, vAABBMins, vAABBMaxs )
	return ( vPoint.x >= vAABBMins.x && vPoint.x <= vAABBMaxs.x ) &&
		   ( vPoint.y >= vAABBMins.y && vPoint.y <= vAABBMaxs.y ) &&
		   ( vPoint.z >= vAABBMins.z && vPoint.z <= vAABBMaxs.z );
end

--[[
* SHARED

This function returns true if a line segment is intersecting the given axis-aligned bounding box, and false otherwise.

This function uses the Seperating Axis Theorem, with a lot of help from these particular sources (in fact, I even posted in the first one):
http://www.gamedev.net/topic/338987-aabb---line-segment-intersection-test/
http://www.metanetsoftware.com/technique/tutorialA.html
http://en.wikipedia.org/wiki/Separating_axis_theorem
http://www.magic-software.com/Documentation/MethodOfSeparatingAxes.pdf

Basically, the tests performed in this code work by reducing the problem into 6 sphere collision tests.
The radii of these "spheres" and the distances between them are found by projecting vectors onto a limited # of specific axes.
]]--
function MODULE:DoesLineSegIntersectAABB( vSegmentStart, vSegmentEnd, vAABBMins, vAABBMaxs )
	--These vectors represent half of the offset between the AABB max/min and seg start/end (respectively)
	local vAABBHalves	 = 0.5 * ( vAABBMaxs - vAABBMins );
	local vSegHalves	 = 0.5 * ( vSegmentEnd - vSegmentStart );

	--[[
	If we move the line segment and AABB in such a way that the AABB winds up at the origin,
	this vector would be located where the midpoint of the line segment is now.
	]]--
	local vRelSegMidpoint = ( vSegmentStart + vSegHalves - 0.5 * ( vAABBMins + vAABBMaxs ) );

	
	--[[
	In the tests below, we make use of absolute values so we don't have to do two comparisons for each test.
	vAABBHalves is never negative so we need not math.abs() it.
	vAbsSegHalves is the same as vSegHalves, but components are guaranteed not to be negative. This is used in the comparisons.
	]]--
	local vAbsSegHalves  = Vector( math.abs( vSegHalves.x ),
								   math.abs( vSegHalves.y ),
								   math.abs( vSegHalves.z )
								 );

	--These tests occur on the AABB's faces' normals. Since this is an AABB, this corresponds to the world axes ( <1, 0, 0>, <0, 1, 0>, and <0, 0, 1> ).
	--Projections of vectors onto these axes are x, y, and z respectively.
	if math.abs( vRelSegMidpoint.x ) > vAABBHalves.x + vAbsSegHalves.x then return false end
	if math.abs( vRelSegMidpoint.y ) > vAABBHalves.y + vAbsSegHalves.y then return false end
	if math.abs( vRelSegMidpoint.z ) > vAABBHalves.z + vAbsSegHalves.z then return false end

	--[[
	These tests occur on the cross products between the segment direction vector and the AABB's edges.
	Since this is an AABB, edge directions also correspond to world axes ( < 1, 0, 0 >, < 0, 1, 0 >, and < 0, 0, 1 > ).
	The cross products between these axes and a segment direction vector "d" are as follows:

	<1, 0, 0> x d	=	< 0,   -d.z,  d.y>
	<0, 1, 0> x d	=	< d.z,  0,   -d.x>
	<0, 0, 1> x d	=	<-d.y,  d.x,  0  >

	Because this is a cross product involving the segment vector, when the segment is projected onto that axis it occupies a single point.
	Therefore, we only need to test that the box's "radius" against the distance from the center of the box to that point.

	The 0.0001 being added here is to deal with degenerate cross products (due to floating point error).
	This helps prevent a false positive (i.e. it says the segment didn't intersect, but it really should have).
	If this number is set too high, a real miss may be ignored. If this number is too low, an incorrect miss may occur. So, adjust if necessary.
	]]--
	if math.abs( vSegHalves.y * vRelSegMidpoint.z - vSegHalves.z * vRelSegMidpoint.y ) > vAbsSegHalves.y * vAABBHalves.z + vAbsSegHalves.z * vAABBHalves.y + 0.0001 then return false end
	if math.abs( vSegHalves.z * vRelSegMidpoint.x - vSegHalves.x * vRelSegMidpoint.z ) > vAbsSegHalves.z * vAABBHalves.x + vAbsSegHalves.x * vAABBHalves.z + 0.0001 then return false end
	if math.abs( vSegHalves.x * vRelSegMidpoint.y - vSegHalves.y * vRelSegMidpoint.x ) > vAbsSegHalves.x * vAABBHalves.y + vAbsSegHalves.y * vAABBHalves.x + 0.0001 then return false end

	return true;
end

--[[
* SHARED

Returns the point that a line intersects with a plane.

vPointOnPlane is a point on the plane; if you think of the plane
	as a plate resting on a needle, this is the needle point
vNormalOfPlane is the normal of the plane; this is a vector perpendicular to the
	surface of the plane.
vLineStart is a point on the line.
vLineEnd is another point on the line. They can't be the same point.

This function will fail if the line is parallel to the plane (i.e. the line will never
	intersect).
The function will also fail if vLineEnd and vLineStart are exactly the same.
In either of these cases nil is returned.

Otherwise, the intersection point and the intersect fraction are returned.

The intersect fraction is a measure of where between vLineStart and vLineEnd the intersection point is.
	If this is 0, it means the cut is at vLineStart.
	If this is 1, it means the cut is at vLineEnd.
	This can possibly be more than 1 or less than 0. If it is, that means the
	intersection point occured outside of the segment. You can check this if you
	want it to occur on the segment.
]]--
function MODULE:LinePlaneIntersect( vPointOnPlane, vNormalOfPlane, vLineStart, vLineEnd )
	local vSlope = vLineEnd - vLineStart;
	if vLineEnd == vLineStart then return nil end
	
	local fNormalVsSlopeDot = vNormalOfPlane:Dot( vSlope );
	if fNormalVsSlopeDot == 0 then return nil end
	
	local t = ( vNormalOfPlane:Dot( vPointOnPlane - vLineStart ) / fNormalVsSlopeDot );
	return vLineStart + ( t * vSlope ), t;
end

--[[
* SHARED

Runs the provided function once for each element in the provided table.

fnRunThis should be the function you want to run. Each time the function runs:
	The first argument given to this function will be an element that hasn't yet been picked from the provided table, tData.
	The remaining arguments will be the same as the arguments you provided after tData.
tData is an optional value that defaults to nil.
	If this is nil or an empty table, the provided function doesn't run at all.
	If this is a non-empty table, the provided function runs once for each element in the table.
... are additional arguments to provide to the function each call.

Returns true if the provided function evaluates to true (i.e. not nil, not false) on every call.
Also returns true if tData was empty or nil.
Returns false otherwise.
]]--
function MODULE:RunForEach( fnRunThis, tData, ... )
	if tData == nil then return true end

	local bAllSuccess = true;
	for k, v in pairs( tData ) do
		if !fnRunThis( v, ... ) then bAllSuccess = false end
	end
	return bAllSuccess;
end

--[[
* SHARED

Runs the provided function once for each player.

fnRunThis should be the function you want to run. Each time the function runs:
	The first argument given to this function will be a player that hasn't been chosen yet.
	The remaining arguments will be the same as the arguments you provided after fnRunThis.
... are additional arguments to provide to the function each call.

Returns true only if the provided function returned true on every call.
Returns false otherwise.
]]--
function MODULE:RunForEachPlayer( fnRunThis, ... )
	return self:RunForEach( fnRunThis, player.GetAll(), ... );
end

--[[
* SHARED

Given a table of functions and a peice of data, calls a particular function from the table, passing the arguments that come after vData (...).

tFunctions should be a table of functions mapped to by datatype strings, set up like so:
		local tMyFunctions = {
			["string"] = function( a, b, c )
				--Do something here
			end,

			["number"] = function( a, b, c )
				--Do something else here
			end,

			["table"] = function( a, b, c )
				--etc
			end,

			["nil"] = function( a, b, c )
				--etc
			end,
		}

	NOTE: If a datatype is mapped to something other than a function in this table (e.g. if your table had something like ["Vector"] = "HI!!"),
	an error will occur when data of that kind is given (e.g. you gave a Vector() for vData).

vData can be anything, including nil. We will get it's type with type(), and then look in the table for a function corresponding to it.
vDefaultReturn is the value that will be returned in the case that the table does not contain a function for that datatype.
The other arguments passed to this function (in ...) are the arguments that get passed to the chosen function.

This function then returns whatever the chosen function returns.
If the table does not have a function corresponding to vData's particular datatype, then no function is ran and nil is returned.
]]--
function MODULE:CallByDatatype( tFunctions, vData, vDefaultReturn, ... )
	local f = tFunctions[type( vData )];
	if !f then return vDefaultReturn end

	return f( ... );
end

--[[
* SHARED

Same function as above more or less, but with support for error checking.
If an error occurs, an error message is generated and the default value is returned.

tFunctions, vData, vDefaultReturn, and ... all play the same role as they do in CallByDatatype.

Unlike the above function, this function returns only two peices of data: vReturn, bSuccess (in that order).
vReturn differs depending on whether or not errors occured.
	If a function exists, and ran without errors, this will be the FIRST value returned by the chosen function.
	Otherwise, this will be equal to vDefaultReturn.
bSuccess will be true only if a function for that particular type of data exists, and it ran without any errors.
	It will be false in any other case.
]]--
function MODULE:PCallByDatatype( tFunctions, vData, vDefaultReturn, ... )
	local f = tFunctions[type( vData )];
	if !f then return vDefaultReturn, false end

	local s, r = pcall( f, ... );
	if s then	return r, true
	else
		ErrorNoHalt( "Itemforge Util: PCallByDatatype for \""..type( vData ).."\" failed: "..r.."\n" );
		return vDefaultReturn, false
	end

end

--[[
* SHARED

Returns true if the given folder name is bad (e.g. goes upward in hierarchy or is
an svn folder)

This should be the name of a folder (such as "myfolder"), not a path (such as "itemforge/hello/myfolder").
]]--
function MODULE:IsBadFolder( strName )
	return BadFolders[strName] == true;
end

--[[
* SHARED

Picks a random direction inside of a right circular cone that has an angle of fConeAperture between any pair of opposing sides.
The cone is centered around it's axis, vAxis, and fans out in the direction vAxis points.

This is useful for projectile spread for guns (e.g. you fire the object, but it's potentially a little off course each time).

This returns the random direction picked (as a vector).
]]--
function MODULE:RandomDirectionInCone( vAxis, fConeAperture )
	if fConeAperture == nil then fConeAperture = 0 end

	--The aperture angle needs to be in radians. We halve it so when we randomize it,
	--only the part above the cone axis (a triangle growing in the direction implied by theta) is utilized
	fConeAperture = math.Rand( 0, math.Deg2Rad( 0.5 * fConeAperture ) );
	
	local ang	   = vAxis:Angle();
	local fTheta   = math.Rand( 0, 2 * math.pi );
	local fSpread  = math.sin( fConeAperture );
	local vForward = math.cos( fConeAperture )		  * ang:Forward() +
					 ( fSpread * math.cos( fTheta ) ) * ang:Right() +
					 ( fSpread * math.sin( fTheta ) ) * ang:Up();
	return vForward;
end

--[[
* SHARED

Takes an entity, bone, and a position relative to that bone, then returns it's position in the world.

eEntity is an optional entity. If eEntity is:
	a valid entity, then the returned world position will be converted from a local position relative to a bone on this entity.
	nil / an invalid entity, the local position is considered a world position and is returned instead.
iBone is a physbone ID corresponding to a bone on the given entity.
	If an invalid bone is passed, nil is returned.
	However, if eEntity is nil / invalid, the bone is ignored and can be set to anything.
vLocalPos is a position relative to the given bone on the given entity.

Returns the world position as a vector,
or nil if a valid entity and an invalid bone was given.
]]--
function MODULE:ConvertLocalToWorld( eEntity, iBone, vLocalPos )
	if !IsValid( eEntity ) then return vLocalPos end
	
	local physBone = eEntity:GetPhysicsObjectNum( iBone );
	if IsValid( physBone ) then return physBone:LocalToWorld( vLocalPos ) end
	return nil;
end

--[[
* SHARED

Returns the classname of entities used for loose rope ends.
]]--
function MODULE:GetRopeEndClass()
	return self.RopeEndClass;
end

--[[
* SHARED

Returns true if the given entity is a GMod rope (i.e. it is not naturally a part of the map).
Also caches whether the rope is a GMod rope or not so the test isn't done twice.
]]--
function MODULE:IsGMODRope( eLC )
	if eLC.ItemforgeGMODRope == nil then
		eLC.ItemforgeGMODRope = ( nil != ( eLC.Bone1 && eLC.Bone2 && eLC.LPos1 && eLC.LPos2 && eLC.length && eLC.forcelimit && eLC.width && eLC.material && eLC.rigid ) );
	end
	
	return eLC.ItemforgeGMODRope;
end

--[[
* SERVER

Returns true if the given point is inside of a spherical cone.

A spherical cone consists of all points that are both inside of a sphere and a right circular cone.
See http://mathworld.wolfram.com/SphericalCone.html for more info.

vPoint is the point to check.
vSphereCenterConeApex is both the center of the sphere and the apex of the cone (the point the cone narrows down to).
vConeAxis is the cone's axis. The cone is centered around it's axis and fans out in the direction vAxis points.
fSphereRadius is the radius of the sphere.
fCosOfHalfConeAperture should be the cosine of half of the cone's aperture.
	The cone's aperture is the angle between any two opposing sides on the cone (in radians).
	Half of this will give you the angle between the cone's axis and any side of the cone.
	Taking the cosine of this number will give you what you need for this parameter.

	So for example, if your cone always has an aperture of 90 degrees, that's equal to PI/2 radians.
	Half of that is PI/4 radians. The cosine of PI/4 = 0.70711, So you'd give 0.70711.

	If you don't know what the aperture is, you can do the following:
		If you know it's going to be in degrees:	math.cos( 0.5 * math.Deg2Rad( APERTURE IN DEGREES ) )
		If you know it's going to be in radians:	math.cos( 0.5 * APERTURE IN RADIANS )
]]--
function MODULE:IsPointInSphericalCone( vPoint, vSphereCenterConeApex, vConeAxis, fSphereRadius, fCosOfHalfConeAperture )
	return ( vCutPos:Distance( vSphereCenterConeApex ) <= fSphereRadius && vConeAxis:Dot( ( vPoint - vSphereCenterConeApex ):Normalize() ) > fCosOfHalfConeAperture );
end

if SERVER then




--[[
* SERVER

Runs IF.Util:CutRope() on every rope in the map.

See CutRope below for a description of this function's arguments.

Returns true if at least one rope was cut.
Returns false otherwise.
]]--
function MODULE:CutRopes( vPlanePoint, vPlaneNormal, fMaxSlack, fnIsValidCut, ... )
	local bAnyCut = false;
	for k, v in pairs( ents.FindByClass( strRopeClass ) ) do
		if self:CutRope( v, vPlanePoint, vPlaneNormal, fMaxSlack, fnIsValidCut, ... )  then	bAnyCut = true	end
	end
	return bAnyCut;
end

--[[
* SERVER

This function cuts a given rope if it both:
	A. Intersects the given plane
	B. Passes the fnIsValidCut test.

The way rope cuts are done is by finding the intersect of a taut rope (treated as a straight line) against the plane with normal vNormal, containing vPlanePoint.

eLCRope should be a valid, taut phys_lengthconstraint entity created by GMod (e.g. with the rope toolgun).
	This function will return false if this is not a GMod rope.
	GMod ropes contain information about the rope necessary to split it (such as the rope width, material, etc).
	"Taut" means "pulled tight". In other words, the rope needs to be as straight as possible.
	For instance, if the rope is 50 units long, the distance between the two endpoints the rope is attached to should be around 50 units.
vPlanePoint should be a point on the cut plane.
	In the case of cutting melee weapons like knives, this is usually something like a player's shoot position (the position the player's eyes are at).
vPlaneNormal is a vector perpendicular to the cut plane.
	In the case of cutting melee weapons like knives, the player's aim direction can be thought of as the direction of a line residing on the cut plane.
	Since the line resides on the cut plane, getting a vector perpendicular to this line will give you a vector perpendicular to the cut plane.
	The direction the player is the looking is the aim direction. The "forward" direction of the player's eye angles will give you the aim direction,
	so the "up" and "right" direction of the player's eye angles will give you vectors perpendicular to the aim direction.
	You'll want to choose Up or Right depending on what how you want the cut plane oriented (if Up, the cut plane is horizontal, if Right, the cut plane is vertical).
fMaxSlack is an optional number that defaults to 30.
	If the distance between the two rope ends is less than ( the length of the rope - fMaxSlack ), the rope cannot be cut.
	The smaller this number is, the tigher the rope needs to be to be cut.
	However, the larger this number is, cuts are more likely to appear in "weird" positions,
	since the code assumes the rope lies along a straight line, and a slack rope will stray from that line.
fnIsValidCut is an optional function.
	This function should return true if the cut is allowed,
	or false if the cut should not be allowed.

	This function only calls if the cut location occurs on the rope (you don't have to test if the cut position is between the two rope points).
	One thing this function can be used for is to only allow cuts if they're inside of a certain shape (like a wedge of a circle for instance).
	You could do this by checking the distance between a point on the plane and the cut location (for the circle),
	and the by testing the angle between the aim vector and the vector from the center of the circle to the cut location (for a wedge on the circle).

	Syntax: fnIsValidCut( eLCRope, vCutPos, ... )
		eLCRope is the rope that we're trying to cut
		vCutPos is the world position the cut is occuring at
		... are extra arguments passed to this function by CutRope
	
... are extra arguments that will be passed to fnIsValidCut.

Returns four things: eEnd1, eLCRope1, eEnd2, eLCRope2.
	eEnd1 is the loose rope end entity for the first rope half.
	eLCRope1 is the phys_lengthconstraint entity for the first rope half.
	eEnd2 is the loose rope end entity for the second rope half.
	eLCRope2 is the phys_lengthconstraint entity for the second rope half.

	If two rope halves were created, all four values will be non-nil.
	If only one rope half was created, eEnd2 and eLCRope2 will be nil.
	If no rope halves were created, all four values will be nil.
]]--
function MODULE:CutRope( eLCRope, vPlanePoint, vPlaneNormal, fMaxSlack, fnIsValidCut, ... )
	if !self:IsGMODRope( eLCRope )							then return end
	if fnIsValidCut && !self:IsFunction( fnIsValidCut ) then ErrorNoHalt( "Itemforge Util: CutRope Error: fnIsValidCut was given, but was not a valid function." ); return end
	if !fMaxSlack										then fMaxSlack = 30 end

	local eAttached1 = eLCRope.Ent1;
	local eAttached2 = eLCRope.Ent2;
	
	local vWorldPos1 = self:ConvertLocalToWorld( eAttached1, eLCRope.Bone1, eLCRope.LPos1 );
	local vWorldPos2 = self:ConvertLocalToWorld( eAttached2, eLCRope.Bone2, eLCRope.LPos2 );
	
	--[[
	Rope has to be taut for a cut to work because I don't have any reliable way
	of knowing where the rope segments are in any other case. The default value of fMaxSlack is
	kind of arbitrary and could be determined dynamically based on rope length I think
	(i.e. if the distance between the two world positions is close to the actual length of the rope, it appears as fairly straight)
	]]--
	if !vWorldPos1 || !vWorldPos2 || vWorldPos1:Distance( vWorldPos2 ) < eLCRope.length - fMaxSlack then return end
	
	--If an intersect was found, it needs to occur on the rope
	local vCutPos, fFrac = IF.Util:LinePlaneIntersect( vPlanePoint, vPlaneNormal, vWorldPos1, vWorldPos2 );
	if !vCutPos || !self:IsInRange( fFrac, 0, 1 ) then return end

	--The cut has to be possible according to fnIsValidCut
	if fnIsValidCut then
		local s, r = pcall( fnIsValidCut, eLCRope, vCutPos, ... );
		if	   !s	then ErrorNoHalt( "Itemforge Util: CutRope Error: fnIsValidCut failed: "..r ); return;
		elseif !r	then return;
		end
	end

	local l = eLCRope.length + eLCRope.addlength;
	
	--Make two halves on either side of the cut position.
	local eEnd1, eLCRope1 = self:MakeRopeHalf( eLCRope, eAttached1, eLCRope.Bone1, eLCRope.LPos1, l * fFrac,		 vCutPos );
	local eEnd2, eLCRope2 = self:MakeRopeHalf( eLCRope, eAttached2, eLCRope.Bone2, eLCRope.LPos2, l * ( 1 - fFrac ), vCutPos );

	--If the first half didn't spawn but the second did, the second and first halves switch places
	if eEnd1 == nil then	eEnd1, eLCRope1, eEnd2, eLCRope2 = eEnd2, eLCRope2, nil, nil	end
	--TODO make rope ends fly apart

	--Remove the original rope
	eLCRope:Remove();
	return eEnd1, eLCRope1, eEnd2, eLCRope2;
end

--[[
* SERVER

When a rope is cut, two new ropes are created and the original rope is disposed of.
This function creates a single new rope, attaching the loose end to an invisible, dangling rope-end entity at the cut position.

eOriginalRope should be the length constraint entity corresponding to the rope that was cut.
eAttachedEnt should be the entity that the new rope should be attached to.
iBoneAttachedTo should be the physics bone ID on the attached ent that the rope will attach to.
vLocalPos should be the position relative to the bone that the rope is being attached to.
fLength should be the total length of the new rope.
vCutPos should be the position the rope was cut at.
	The rope end entity is created here.

Returns two things: eEnd, eRope
	eEnd is the rope end entity.
	eRope is the length constraint (the rope half).

or if there was an error, returns nil.
]]--
function MODULE:MakeRopeHalf( eOriginalRope, eAttachedEnt, iBoneAttachedTo, vLocalPos, fLength, vCutPos )
	--We only bother creating rope segments if they're long enough
	if fLength < 16 then return end

	local eEnd = ents.Create( self:GetRopeEndClass() );
	if !IsValid( eEnd ) then ErrorNoHalt( "Itemforge Util: Error calling MakeRopeHalf: Couldn't create rope end." ); return end

	eEnd:SetPos( vCutPos );
	eEnd:Spawn();
			
	local eRope = constraint.Rope( eAttachedEnt, eEnd, iBoneAttachedTo, 0, vLocalPos, vZero, fLength, 0, eOriginalRope.forcelimit, eOriginalRope.width, eOriginalRope.material, eOriginalRope.rigid );
	if !IsValid( eRope ) || !eRope:GetClass() == strRopeClass then ErrorNoHalt( "Itemforge Util: Error calling MakeRopeHalf: Created rope was not a valid "..strRopeClass.."." ); eEnd:Remove(); return end

	eEnd:SetAssociatedRope( eRope );
	if eAttachedEnt:GetClass() == self:GetRopeEndClass() then eAttachedEnt:SetAssociatedRope( eRope ) end
	
	return eEnd, eRope;
end




end

--[[
* SHARED

Caches the plane that a func_breakable_surf's glass face resides on.
If the plane has already been cached, doesn't bother finding it again.

Note that this function only works if the func_breakable_surf has not yet been broken.
Therefore, make sure this is called before a player has the opportunity to break the window
(right after the window is spawned is a good time).

eGlass should be a func_breakable_surf.

Returns true if the plane was already cached, or was successfully located and cached.
Returns false otherwise.
]]--
function MODULE:CacheGlassPlane( eGlass )
	--Don't bother caching if we're already cached
	if eGlass.ItemforgeGPCenter then return true end

	eGlass.ItemforgeGPCenter, eGlass.ItemforgeGPNormal = self:FindGlassPlane( eGlass );
end

--[[
* SHARED

If the given entity has cached glass-plane info, returns two things: vCenter, vNormal:
	vCenter is a point on the plane.
	vNormal is the normal of the plane.
Otherwise, returns nil, nil.
]]--
function MODULE:GetCachedGlassPlane( eGlass )
	return eGlass.ItemforgeGPCenter, eGlass.ItemforgeGPNormal
end

--[[
* SHARED

Given a func_breakable_surf, finds the plane of the face the glass is on.
This is mostly only useful for Itemforge's melee weapons (they need to know the plane
to find the correct location the glass should be broken).

Note that this function only works if the func_breakable_surf has not yet been broken.
Therefore, make sure this is called before a player has the opportunity to break the window
(right after the window is spawned is a good time).

eGlass should be a func_breakable_surf.

If the plane is found, returns two things: vCenter, vNormal
	vCenter is a point on the plane
	vNormal is the normal of the plane
Otherwise, returns nil, nil. 
]]--
function MODULE:FindGlassPlane( eGlass )
	local vMin, vMax = eGlass:WorldSpaceAABB();
	local fRadius = 0.5 * vMin:Distance( vMax ) + 1;
	

	--[[
	Set sample points in the func_breakable_surface's AABB. These are points that the traces are targetted at (in order of preference).
	If one of these just cannot be hit (due to world brushes blocking it most likely) it tries the tracing the
	lines to a different sample point.
	]]--
	local vCenter = 0.5  * ( vMin + vMax );
	local vOffset = 0.25 * ( vMax - vMin );
	SetVector( tSamplePoints[1],	vCenter.x,				vCenter.y,				vCenter.z			  );
	SetVector( tSamplePoints[2],	vCenter.x - vOffset.x,	vCenter.y - vOffset.y,	vCenter.z - vOffset.z );
	SetVector( tSamplePoints[3],	vCenter.x - vOffset.x,	vCenter.y - vOffset.y,	vCenter.z + vOffset.z );
	SetVector( tSamplePoints[4],	vCenter.x - vOffset.x,	vCenter.y + vOffset.y,	vCenter.z - vOffset.z );
	SetVector( tSamplePoints[5],	vCenter.x - vOffset.x,	vCenter.y + vOffset.y,	vCenter.z + vOffset.z );
	SetVector( tSamplePoints[6],	vCenter.x + vOffset.x,	vCenter.y - vOffset.y,	vCenter.z - vOffset.z );
	SetVector( tSamplePoints[7],	vCenter.x + vOffset.x,	vCenter.y - vOffset.y,	vCenter.z + vOffset.z );
	SetVector( tSamplePoints[8],	vCenter.x + vOffset.x,	vCenter.y + vOffset.y,	vCenter.z - vOffset.z );
	SetVector( tSamplePoints[9],	vCenter.x + vOffset.x,	vCenter.y + vOffset.y,	vCenter.z + vOffset.z );

	local tr		= {};
	tr.filter		= {};
	tr.mask			= MASK_SOLID_BRUSHONLY;		--Unbroken windows are solid brushes

	--vPerp is a vector perpendicular to the exploratory trace direction
	local vPerp = vPosY;


	--We don't know where the first side of the window is. In the worst case this will take 6 traces to find.
				  local traceRes	= self:TraceToEntity( eGlass, tSamplePoints, vNegX, fRadius, tr );
	if traceRes == nil then
						traceRes	= self:TraceToEntity( eGlass, tSamplePoints, vPosX, fRadius, tr );

		if traceRes == nil then
			vPerp = vPosX;
			
						traceRes	= self:TraceToEntity( eGlass, tSamplePoints, vPosY, fRadius, tr );

			if traceRes == nil then
						traceRes	= self:TraceToEntity( eGlass, tSamplePoints, vNegY, fRadius, tr );

				if traceRes == nil then	
						traceRes	= self:TraceToEntity( eGlass, tSamplePoints, vPosZ, fRadius, tr );

					if traceRes == nil then
						traceRes	= self:TraceToEntity( eGlass, tSamplePoints, vNegZ, fRadius, tr );

						if traceRes == nil then
							return nil
						end
					end
				end
			end

		end
	end

	if traceRes.MatType == MAT_GLASS then	return traceRes.HitPos, traceRes.HitNormal; end
	local vForward = traceRes.HitNormal;



	--Try the opposite side
	traceRes	= self:TraceToEntity( eGlass, tSamplePoints, vForward, fRadius, tr );
	if traceRes == nil then return nil end

	if traceRes.MatType == MAT_GLASS then	return traceRes.HitPos, traceRes.HitNormal; end



	--We didn't hit glass. The glass must be on a face perpendicular to the sides we've already tested.
	--Assuming a box, this narrows it down to one of four faces.
	traceRes	= self:TraceToEntity( eGlass, tSamplePoints, ( vForward:Dot( vPerp ) * vForward - vPerp ):Normalize(), fRadius, tr );
	if traceRes == nil then return nil end

	if traceRes.MatType == MAT_GLASS then	return traceRes.HitPos, traceRes.HitNormal; end
	local vLeftward = traceRes.HitNormal;



	--Try the opposite side
	traceRes	= self:TraceToEntity( eGlass, tSamplePoints, vLeftward, fRadius, tr );
	if traceRes == nil then return nil end

	if traceRes.MatType == MAT_GLASS then	return traceRes.HitPos, traceRes.HitNormal; end

	
	
	--We STILL haven't hit glass. That narrows it down to two faces.
	local vUpward = vForward:Cross( vLeftward );

	traceRes	= self:TraceToEntity( eGlass, tSamplePoints, -vUpward, fRadius, tr );
	if traceRes == nil then return nil end
	
	if traceRes.MatType == MAT_GLASS then	return traceRes.HitPos, traceRes.HitNormal; end
	


	--Try the opposite side
	traceRes	= self:TraceToEntity( eGlass, tSamplePoints, vUpward, fRadius, tr );
	if traceRes == nil then return nil end

	if traceRes.MatType == MAT_GLASS then	return traceRes.HitPos, traceRes.HitNormal; end

	return nil;
end

--[[
* SHARED

Repeats a line trace until the given entity is hit.

This is mostly a utility function for IF.Util:FindGlassPane above,
but there are probably other uses it would be good for.

Whenever a "wrong" entity is hit (meaning any entity other than the given one),
the "wrong" entity is added to the trace's filter and the trace is repeated.

If a world brush is hit, the trace is repeated, starting behind the face
of the brush that was hit allowing the trace to pass through the world brush (this can be
done up to iMaxWorldPenetration times per sample point).

If a world brush is hit more than iMaxWorldPenetration times while attempting to trace to the entity through
a particular sample point, the function switches to a new sample point and attempts to trace
to the entity through that point instead.
If no more sample points are available, the function fails and returns nil.

eEntity should be the entity you want the trace to hit.
tSamplePoints should be a table of world positions, in normal 1, 2, 3, ..., n ordering.
	A "sample point" is basically a point inside the entity's AABB that traces are targeted towards.
	The traceline's start and end positions are set according to the current sample point and the
	direction the trace is travelling (vnDir).
vnDir is the direction the trace should travel, start to end.
	For example, if you wanted to hit the right side of a box, you'd make vnDir point to the left.
fRadius should be the distance away from the sample point you want to start the trace at.
	Generally, it's best to use the entity's bounding radius for this value.
	If this is too large, your traces may hit a lot of entities and world brushes, which will slow the function down.
	If this is too small, your traces may start within the entity and never hit it.
tr should be the trace table you want to use.
	This function will override tr.start and tr.endpos.
	This function will add entries to tr.filter.
	Because of this, tr.filter must be a table. It does not have to be empty.

	NOTE: If you plan to call this function several times, reusing the trace
	table can cut down on the number of traces that need to be performed (since the
	filter will have already been built, and will know to ignore these entities).
iMaxWorldPenetration is an optional max number of times a trace can hit a world brush
	before switching to a different sample point. This defaults to 5.

If the trace finally hits the entity, the trace results are returned.
If the trace hits nothing, false is returned.
]]--
function MODULE:TraceToEntity( eEntity, tSamplePoints, vnDir, fRadius, tr, iMaxWorldPenetration )
	if iMaxWorldPenetration == nil then iMaxWorldPenetration = 5 end

	local v;
	local bUseThisSample;
	local iCounter;
	for i = 1, #tSamplePoints do
		
		v = tSamplePoints[i];
		bUseThisSample = true;
		iCounter = 0;

		tr.start  = v - fRadius * vnDir;
		tr.endpos = v + fRadius * vnDir;

		while bUseThisSample do
		
			--(Re)trace
			traceRes = util.TraceLine( tr );

			--If we hit the entity we're done
			if traceRes.Entity == eEntity then
				return traceRes;

			--Try a new sample point if this one missed
			elseif !traceRes.Hit then
				bUseThisSample = false;

			--If we hit the world, penetrate through it
			elseif traceRes.Entity:IsWorld() then
				iCounter = iCounter + 1;

				--Try a new sample point if we've encountered the world too much
				if iCounter > iMaxWorldPenetration then		bUseThisSample = false;
				else										tr.start = traceRes.HitPos + vnDir;
				end

			--If we hit an entity, filter it out
			else
				table.insert( tr.filter, traceRes.Entity );
			end

		end
	end

	return nil;
end

--[[
* SHARED

This function returns the y coordinate of a point on a sine wave with
the given amplitude, wavelength, and "zero time" (if fCurrentTime = fZeroTime, the returned value is zero)
]]--
function MODULE:CosWave( fCurrentTime, fAmplitude, fWaveLength, fZeroTime )
	return 0.5 * fAmplitude * ( 1 + math.sin( fCurrentTime - fZeroTime ) );
end

--[[
* SHARED

This function returns the y coordinate of a point on a triangle wave with
the given amplitude, wavelength and "zero time" (if fCurrentTime = fZeroTime, the returned value is zero)

The following graph shows what a triangle wave looks like:

				   fWaveLength
			         __^__
			        |     |
		     y
		     |
fAmplitude ->|.     .     .
			 | \   / \   /
			 |	\ /   \ /
		 0 ->|___._____.___	t (fCurrentTime)
			     ^
			 fZeroTime
]]--
function MODULE:TriangleWave( fCurrentTime, fAmplitude, fWaveLength, fZeroTime )

end

--[[
* SHARED

Cosine interpolate function. Transitions smoothly from fStart to fEnd. If you were to graph
this function return value vs time it would look something like this:

      return
       value
fStart ->|--..__
		 |      `_
		 |        .
fEnd   ->|         `--..__
		 |________________ time
		 ^                ^
	 fTimeStart		  fTimeEnd

NOTE: fTimeStart, fCurTime, and fTimeEnd are usually thought of as having units of time (like seconds),
but they can have any kind of unit, like meters. (If, for example, you were interpolating an object's color
by interpolating it's "current" distance between a "close" distance to "far" distance; e.g. maybe the object glows red when it's close,
blue when it's far?)

fStart should be the value that is returned when fCurTime is equal to fTimeStart.
	An example of this is the angle a rotating object starts at.
fEnd should be the value that is returned when fCurTime is equal to fTimeEnd.
	An example of this is the angle a rotating object ends at.
fTimeStart is the start time.
	An example of this is the time that an object's rotation should start.
fTimeEnd is the end time.
	An example of this is the time that an object's rotation should end.
fCurTime is usually the current time, but it can represent any parameter.
	This is usually CurTime(), or RealTime().
]]--
function MODULE:CosInterpolate( fStart, fEnd, fTimeStart, fTimeEnd, fCurTime )
	return fStart + ( fEnd - fStart ) * 0.5 * (1 - math.cos( math.pi * ( fCurTime - fTimeStart ) / ( fTimeEnd - fTimeStart ) ) );
end

--[[
* SHARED

Converts from inches (also known as game units) to meters.
fInches is the number of inches.
]]--
function MODULE:InchesToMeters( fInches )
	return 0.0254 * fInches;
end

--[[
* SHARED

Converts from inches (also known as game units) to centimeters.
fInches is the number of inches.
]]--
function MODULE:InchesToCM( fInches )
	return 2.54 * fInches;
end

--[[
* SHARED

Converts from meters to inches (also known as game units).
fMeters is the number of meters.
]]--
function MODULE:MetersToInches( fMeters )
	return 39.3700787 * fMeters;
end

--[[
* SHARED

Converts from centimeters to inches (also known as game units).
fCM is the number of centimeters.
]]--
function MODULE:CMToInches( fCM )
	return 0.393700787 * fCM;
end

--[[
* SHARED

Converts from pounds to grams.
fPounds is the number of pounds.
NOTE: Pounds is a unit of weight, which is a force (mass * gravitational acceleration).
	  Grams is a unit of mass.
	  The conversion assumes that these are pounds in Earth's gravity (Earth's gravity is g = 9.81 m/(s^2)).
	  If these pounds were measured on a planet that had, say, 2 times the gravity of Earth,
	  you'd have to divide the pounds by 2 before passing it to this function.
]]--
function MODULE:PoundsToGrams( fPounds )
	return 453.59237 * fPounds;
end

--[[
* SHARED

Convert from grams to pounds.
fGrams is the number of grams.
NOTE: Pounds is a unit of weight, which is a force (mass * gravitational acceleration).
	  Grams is a unit of mass.
	  The conversion assumes that these are pounds in Earth's gravity (Earth's gravity is g = 9.81 m/(s^2)).
	  If you wanted pounds on a planet that had, say, 2 times the gravity of Earth,
	  you'd have to multiply the grams by 2 before passing it to this function.
]]--
function MODULE:GramsToPounds( fGrams )
	return 0.00220462262 * fGrams;
end

--[[
* SHARED

Given a single lua file, will generate a list of all files included by that file,
and those files' inclusions, and those files' inclusions, and so on.

strFilepath is the path of the .lua file to check for, relative to the garrysmod/ folder.
tIncludeList should be a table to store the file paths of included files in.
	strFilepath is guaranteed to be in tIncludeList.
	It's a good idea to make sure the table is empty before you pass it in, but
	this isn't necessary.
]]--
function MODULE:BuildIncludeList( strFilepath, tIncludeList )
	if FileCache[strFilepath] then ErrorNoHalt( "Itemforge Util: Building include list failed - \""..strFilepath.."\" has already been included; possible include loop?\n" ); return false end
	
	FileCache[strFilepath] = file.Read( "../"..strFilepath );
	if FileCache[strFilepath] == nil then ErrorNoHalt( "Itemforge Util: Building include list failed - couldn't read from \""..strFilepath.."\".\n" ); return false end
	
	--Add this file to the list of included files now that we've verified it exists
	table.insert( tIncludeList, strFilepath );
	
	--We strip comment blocks and comment lines from the file here
	FileCache[strFilepath] = string.gsub( FileCache[strFilepath], "%-%-%[%[.-%]%]", ""   );
	FileCache[strFilepath] = string.gsub( FileCache[strFilepath], "/%*.-%*/",		""   );
	FileCache[strFilepath] = string.gsub( FileCache[strFilepath], "//.-\n",			"\n" );
	FileCache[strFilepath] = string.gsub( FileCache[strFilepath], "%-%-.-\n",		"\n" );
	
	local strDir = string.GetPathFromFilename( strFilepath );
	local ExpressionStart, IncludeStart, IncludeEnd, ExpressionEnd = 0, 0, 0, 0;
	
	--We'll keep looping until we can no longer find an include statement
	while true do
		--Start pattern explanation: Any amount of spacing, the word include, then any amount of spacing, plus an optional left parenthesis and then any amount of spacing followed by a single or double quote
		--Example: include ( "
		ExpressionStart, IncludeStart	= string.find( FileCache[strFilepath], "%s*include%s*%(?%s*[\"']", ExpressionEnd + 1 );
		if ExpressionStart == nil then return end

		--End pattern explanation: a single or double quote, then any amount of spacing, plus an optional right parenthesis, then any amount of spacing, then an optional ;.
		--Example: " )   ;
		IncludeEnd, ExpressionEnd		= string.find( FileCache[strFilepath], "[\"']%s*%)?%s*;?", IncludeStart + 1 );
		if IncludeEnd == nil then return end
		
		self:BuildIncludeList( strDir..string.sub( FileCache[strFilepath], IncludeStart + 1, IncludeEnd - 1 ), tIncludeList );
	end
end

--[[
* SHARED

Sets the contents of the given file (relative to the garrysmod/ folder)
This just affects the cache, not the actual file.

strContents should be a string containing the contents of the file.
]]--
function MODULE:FileCacheSet( strFilepath, strContents )
	FileCache[strFilepath] = strContents;
end

--[[
* SHARED

Appends the given contents to the existing cached content
for the file with the given path (relative to the garrysmod/ folder)
]]--
function MODULE:FileCacheAppend( strFilepath, strContents )
	FileCache[strFilepath] = FileCache[strFilepath]..strContents;
end

--[[
* SHARED

Clears the file with the given path (relative to garrysmod/) out of the cache.
]]--
function MODULE:FileCacheClear( strFilepath )
	FileCache[strFilepath] = nil;
end

--[[
* SHARED

Returns the contents of the cached file with the given path (relative to garrysmod/)
Returns nil if the file is not cached.
]]--
function MODULE:FileCacheGet( strFilepath )
	return FileCache[strFilepath];
end

--[[
* SHARED

Returns true if there is a file cached under this name or false otherwise.
]]--
function MODULE:FileIsCached( strFilepath )
	return FileCache[strFilepath] != nil;
end




if SERVER then




--[[
* SERVER

Sends the indicated file to the given player.
This function can't send a file if another file send is in progress.

strFilepath is the path of the file (starts in lua/)
pl is the player to send to. If this is nil/not given then sends to all players.

Returns true if the file send was started successfully or false otherwise.
]]--
function MODULE:FileSendStart( strFilepath, pl )
	if FileSendInProgress == true then return false end
	
	FileSendInProgress = true;
	FileSendPlayer = pl;
	FileSendCurrentFile = strFilepath;
	FileSendCurrentChar = 1;
	FileSendTotalChars = string.len( self:FileCacheGet( FileSendCurrentFile ) );

	IF.Network:ServerOut( IFN_MSG_FILESENDSTART, FileSendPlayer, FileSendCurrentFile, FileSendTotalChars );
	return true;
end

--[[
* SERVER

Sends the next part of the current file.
Returns true if there is still data to be sent.
Returns false if a file send is not in progress or the send has completed.
]]--
function MODULE:FileSendTick()
	if FileSendInProgress == false then return false end
	
	local LastChar = FileSendCurrentChar + FileSendCharsPerTick;
	local strFragment = string.sub( self:FileCacheGet( FileSendCurrentFile ), FileSendCurrentChar, LastChar );
	FileSendCurrentChar = LastChar + 1;
	
	IF.Network:ServerOut( IFN_MSG_FILESEND, FileSendPlayer, strFragment );
	
	if FileSendCurrentChar >= FileSendTotalChars then
		self:FileSendEnd();
		return false;
	end
	
	return true;
end

--[[
* SERVER

Called when the file has been completely sent.
Sends a message to the player telling him that the file has ended.
]]--
function MODULE:FileSendEnd()
	FileSendInProgress = false;
	self:FileCacheClear( FileSendCurrentFile );
	
	IF.Network:ServerOut( IFN_MSG_FILESENDEND, FileSendPlayer );
end




else




--[[
* CLIENT

Called when a file transfer has started
]]--
function MODULE:FileSendStart( strFilepath, iChars )
	FileSendInProgress = true;
	FileSendCurrentFile = strFilepath;
	FileSendCurrentChar = 0;
	FileSendTotalChars = iChars;
	
	self:FileCacheSet( FileSendCurrentFile, "" );
end

--[[
* CLIENT

Called when a fragment of the file has been recieved
]]--
function MODULE:FileSendTick( strFragment )
	if FileSendInProgress == false then ErrorNoHalt( "Itemforge Util: File fragment received but no file was being sent...\n" ); return false end
	
	self:FileCacheAppend( FileSendCurrentFile, strFragment );
	FileSendCurrentChar = FileSendCurrentChar + string.len( strFragment );
	
	return true;
end

--[[
* CLIENT

Called after the file send has ended.
]]--
function MODULE:FileSendEnd()
	if FileSendCurrentChar != FileSendTotalChars then
		ErrorNoHalt( "Itemforge Util: File send ended but only transferred "..FileSendCurrentChar.." out of expected "..FileSendTotalChars.." characters.\n" );
		self:FileCacheClear( FileSendCurrentFile, nil );
	end
	FileSendInProgress = false;
	FileSendCurrentFile = nil;
	FileSendCurrentChar = 0;
	FileSendTotalChars = iChars;
end




end





--[[
* SHARED

Adds a new task to the back of the queue.

fnTask should be a function that returns true if the associated task isn't complete yet, and false when it's completed.
]]--
function _TASKQUEUE:Add( fnTask )
	if self.Tasks == nil then self.Tasks = {} end
	
	for i = #self.Tasks, 1, -1 do
		self.Tasks[i + 1] = self.Tasks[i];
	end
	self.Tasks[1] = fnTask;
end

--[[
* SHARED

Removes the current task from the queue.
]]--
function _TASKQUEUE:Dequeue()
	if self:IsEmpty() then return end
	self.Tasks[ #self.Tasks ] = nil;
end

--[[
* SHARED

Runs the current task.
Dequeues it if the task returns false to indicate the task has completed.
]]--
function _TASKQUEUE:Process()
	if self:IsEmpty() then return end
	if !self.Tasks[ #self.Tasks ]() then self:Dequeue() end
end

--[[
* SHARED

Returns true if the task queue is empty (i.e. there are no tasks)
]]--
function _TASKQUEUE:IsEmpty()
	return self.Tasks == nil || #self.Tasks == 0;
end