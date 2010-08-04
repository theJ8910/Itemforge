--[[
item_rope
SHARED

It's rope! You can rope things together with it.
This item is so poorly coded I don't even know where to begin.
TODO I'll come back and fix this up later.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Rope";
ITEM.Description="A rope woven from strands of hemp fibers. ";
ITEM.WorldModel="models/Items/CrossbowRounds.mdl";
ITEM.StartAmount=500;
ITEM.MaxHealth=2;

--[[
To determine the weight and density, http://compostablegoods.com/product_info.php?products_id=102 was used.
According to this page, 63 meters of 4mm diameter hemp rope was 1kg.
For what we are going to do, we want the radius, so we divide the diameter by half to get 2mm.
We convert 63 meters to 2480.31496 inches, and convert the 2 mm to 0.0787401575 inches.

This gives us 2480.31496 inches and .0787401575 inches, respectively.
By treating the rope as a very tall cylinder, we can get it's volume:
	PI * (.0787401575 inches)^2 * 2480.31496 inches = 48.31136004 inches^3
Density is mass/volume. We know the rope weighs 1 kg, or 1000 grams. We know that it's volume is 114.5158165 gu^3, so we can use this to calculate the density of the rope.
	d=1000 grams/48.31136004 inches^3 = 20.69906538 grams/inches^3
]]--
ITEM.Density = 20.69906538;

--[[
We then get the volume of our rope; we assume the rope is one inch tall and has a diameter of 1.5 inches (radius 0.75 inches):
	PI * (.75 inch)^2 * 1 inch = 1.767145868 inches^3
Then we mutliply the density of rope times the volume of our rope to get the mass of our rope:
	1.767145868 in^3 * 20.69906538 grams/in^3 = 36.57826785 grams
	
So, a one inch rope with a radius of 1.5 inches has a mass of ~37 grams.
]]--
ITEM.Weight=37;

--[[
I'm thinking the rope's "size" is it's diameter in game units.
This is 1.5 so it works out to 2. This fits into a container easily like you'd expect,
but the more rope you get the heavier the rope becomes so weight balances out having
"too much rope" in a container.
]]--
ITEM.Size=1;
ITEM.MaxAmount=0;

ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

ITEM.HoldType="normal";

if CLIENT then

ITEM.WorldModelNudge=Vector(2,0,5);
ITEM.WorldModelRotate=Angle(90,0,0);

end

--Rope Item
if SERVER then

ITEM.Width=1.5;						--The rope graphic appears to be this thick
ITEM.Material="cable/rope";			--The rope graphic uses this material
ITEM.Strength=40000;				--The rope breaks when this much force is applied to it (force being kg inches / s^2)
ITEM.Rigid=false;					--Not a rigid rope (like a metal pendulum rod) right?
ITEM.FirstEntity=nil;
ITEM.FirstBone=0;
ITEM.FirstAnchor=Vector(0,0,0);

end

--[[
* SHARED
* Event

Returns a dynamic description of the item. In addition to it's normal description,
we also return how long it is.
]]--
function ITEM:GetDescription()
	--Length of rope in meters
	local len=math.floor(IF.Util:InchesToCM(self:GetAmount()))*0.01;
	if len >= 1 then	return self.Description.."It is "..len..IF.Util:Pluralize(" meter",len).." long.";
	else				return self.Description.."It is "..(len*100)..IF.Util:Pluralize(" centimeter",len).." long."
	end
end

--[[
* SHARED
* Event

The player can't split the rope directly
]]--
function ITEM:CanPlayerSplit(pl)
	return false;
end

--[[
* SHARED
* Event

Ropes don't merge
]]--
function ITEM:CanMerge()
	return false;
end

if SERVER then

--[[
* SERVER

Ropes two entities together.
The length of the rope is determined by the amount of this item.

ent1 is the first entity you want to rope.
bone1 is a physics bone number on ent1 you want to rope to. For all non-ragdoll entities, this is pretty much always 0.
point1 is the local position on ent1 you want to anchor one end of the rope to.

ent2 is the second entity you want to rope.
bone2 is a physics bone number on ent2 you want to rope to. For all non-ragdoll entities, this is pretty much always 0.
point2 is the local position on ent2 you want to anchor the other end of the rope to.

The total length between point1 and point2 cannot be greater than the length (amount) of the rope. This function will return false if this is the case.

This function returns false if we couldn't rope the two entities, or true if we did.
]]--
function ITEM:RopeTogether(ent1,bone1,point1,ent2,bone2,point2)
	local len=self:GetAmount();
	
	local p1,p2=ent1:GetPhysicsObjectNum(bone1),ent2:GetPhysicsObjectNum(bone2);
	if !p1 || !p1:IsValid() || !p2 || !p2:IsValid() then return false end
	
	local w1,w2=p1:LocalToWorld(point1),p2:LocalToWorld(point2);
	local dis=w1:Distance(w2);
	if dis>len then return false end
	
	local dis=point1:Distance(point2);
	if !constraint.Rope(ent1,ent2,bone1,bone2,point1,point2,dis,len-dis,self.Strength,self.Width,self.Material,self.Rigid) then return false end
	
	self:Remove();
	return true;
end

--[[
* SERVER

Allows you to set rope properties all in one function
]]--
function ITEM:SetRopeProperties(iLength, fDiameter, strMaterial, fStrength, bRigid)
	self:SetAmount(math.floor(iLength));
	self:SetWidth(fDiameter);
	self.Material = strMaterial;
	self.Strength = fStrength;
	self.Rigid = bRigid;
end

--[[
* SERVER

Sets the rope diameter, and it's size and weight per unit length since they depend upon these quantities.
Weight is rounded to the nearest gram, and size is rounded to the nearest inch.
]]--
function ITEM:SetWidth(fDiameter)
	self.Width = fDiameter;
	self:SetSize(math.Round(fDiameter*0.5));
	self:SetWeight(math.Round(math.pi * fDiameter*fDiameter*.25 * self.Density));
end

--[[
* SERVER
* Event

We rope stuff together here
]]--
function ITEM:OnSWEPPrimaryAttack()
	local pl=self:GetWOwner();
	--TODO Minimum distance
	local traceRes=pl:GetEyeTrace();
	
	local ent=traceRes.Entity;
	if !ent:IsValid() then return false end
	
	local phys=ent:GetPhysicsObjectNum(traceRes.PhysicsBone);
	if !phys || !phys:IsValid() then return false end
	
	if !self.FirstEntity || !self.FirstEntity:IsValid() then
		self.FirstEntity=ent;
		self.FirstBone=traceRes.PhysicsBone;
		self.FirstAnchor=phys:WorldToLocal(traceRes.HitPos);
	else
		self:RopeTogether(self.FirstEntity,self.FirstBone,self.FirstAnchor,ent,traceRes.PhysicsBone,phys:WorldToLocal(traceRes.HitPos));
	end
	
	return true;
end

end