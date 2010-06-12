--[[
item_ammobelt
SHARED

Ammunition belts link containers and weapons.
Linking a weapon to a container will allow the weapon to source ammo from that container.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Ammunition Belt";
ITEM.Description="An ammuntion belt. This allows weapons to reload from a linked container.";
ITEM.StartAmount=500;
ITEM.MaxAmount=0;
ITEM.Weight=3;
ITEM.Size=5;

ITEM.WorldModel="models/props_interiors/pot01a.mdl";

ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

ITEM.HoldType="slam";

if SERVER then

resource.AddFile("materials/itemforge/items/item_ammobelt_belt.vtf");
resource.AddFile("materials/itemforge/items/item_ammobelt_belt.vmt");

else

ITEM.WorldModelNudge=Vector(0,-5,0);
ITEM.WorldModelRotate=Angle(90,0,90);

end

--Ammo Belt
ITEM.Width=5;													--The belt is about this wide (in game units).
ITEM.Length=2*ITEM.Width;										--This is actually related more to the texture. For every ITEM.Length game units, the texture needs to repeat, and this number helps us determine what UV coordinates we need to use to acheive this effect.

--Returns the length of the ammo belt.
function ITEM:GetDescription()
	--Length of ammo belt
	local len=self:GetAmount()*0.01905;
	if len > 1 then		return self.Description.."It is "..len.." meters long.";
	else				return self.Description.."It is "..(len*100).." centimeters long."
	end
end

if CLIENT then

--[[
The ammo belt model is a spiral. We create one segment (two polygons) per.
The higher this number is the crappier it looks, but it's also easier to draw.
I divide this into 2 kinds of detail. 
]]--
ITEM.BeltMaterial=Material("itemforge/items/item_ammobelt_belt");	--We use this material for our model
ITEM.ModelDetail=2;			--Level of detail - smaller is more detailed (good looking, but more expensive to draw)
ITEM.SpiralSpacing=1.2;		--A point at theta=0 degrees and a point at theta=360 degrees are spaced this far apart
ITEM.Spirals=5;

local function GenerateMesh(detail,spacing,spirals)
	--Width constant
	local w=ITEM.Width*.5;
	
	--Spacing constant; 6.2831853071796 = 2 PI
	local c=spacing/6.2831853071796;
	
	--Finished when b exceeds this number
	local f=spirals*6.2831853071796;
	
	local r=0;
	local b=0;
	local lastx=0;
	local lasty=0;
	local x=0;
	local y=0;
	local v=0;
	local normal=Vector(1,0,0);
	
	local MeshCoords={};
	
	table.insert(MeshCoords,{["pos"]=Vector(0,0,w),		["normal"]=normal,		["u"]=0, ["v"]=0});
	table.insert(MeshCoords,{["pos"]=Vector(0,0,-w),	["normal"]=normal,		["u"]=1, ["v"]=0});
	
	repeat
		--We're going to generate new x/y coords for the next segment but need to remember what the last set of coords were
		lastx=x;
		lasty=y;
		
		--[[
		Some calculus and trigonometry here, we're trying to figure where the next segment should go on the archimedes spiral.
		To do this we need to know find "b", the parameter that determines both the angle and the radius.
		The angle will be "b" itself.
		From that we can calculate the normal with basic trigonometry.
		The radius "r" of the spiral at that point will be = to spacing*b/2PI (in other words, how far the spiral "travels" after one loop is determined by the spacing)
		]]--
		b=math.sqrt(12.566370614359*detail/spacing + math.pow(b,2));	--12.566370614359 = 4 PI
		normal=Vector(math.cos(b),math.sin(b),0);
		r=c*b;
		
		--Calculate new coords
		x=r*math.cos(b);
		y=r*math.sin(b);
		
		--v is the next v texture coordinate that will be used
		--This is calculated with v+ d/l.
		v=v+math.sqrt(math.pow(x-lastx,2)+math.pow(y-lasty,2))/ITEM.Length;
		
		table.insert(MeshCoords,{["pos"]=Vector(x,y,w),		["normal"]=normal,		["u"]=0, ["v"]=v});
		table.insert(MeshCoords,MeshCoords[table.getn(MeshCoords)]);
		table.insert(MeshCoords,MeshCoords[table.getn(MeshCoords)-2]);
		table.insert(MeshCoords,{["pos"]=Vector(x,y,-w),	["normal"]=normal,		["u"]=1, ["v"]=v});
		table.insert(MeshCoords,MeshCoords[table.getn(MeshCoords)-3]);
		table.insert(MeshCoords,MeshCoords[table.getn(MeshCoords)-1]);
		
	--6.2831854071796 = 2 PI
	until b>f
	
	--These are extra coordinates that we'll get rid of
	MeshCoords[table.getn(MeshCoords)]=nil;
	MeshCoords[table.getn(MeshCoords)]=nil;

	local mesh=NewMesh();
	mesh:BuildFromTriangles(MeshCoords);
	return mesh;
end

ITEM.Mesh=GenerateMesh(ITEM.ModelDetail,ITEM.SpiralSpacing,ITEM.Spirals);


--[[
Draws the ammo belt mesh on an entity.
]]--
function ITEM:DrawMesh(ent)
	--Make world matrix
	local wm=Matrix();
	wm:Translate(ent:GetPos());
	wm:Rotate(ent:GetAngles());
	
	render.SetMaterial(self.BeltMaterial);
	
	cam.PushModelMatrix(wm);
	self.Mesh:Draw();
	cam.PopModelMatrix();
end

--Called when a model associated with this item needs to be drawn
function ITEM:OnDraw3D(eEntity,bTranslucent)
	--self["base_item"].OnDraw3D(self,eEntity,bTranslucent);
	self:DrawMesh(eEntity);
end

end