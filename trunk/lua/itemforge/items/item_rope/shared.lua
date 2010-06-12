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

--[[
To determine the weight, http://compostablegoods.com/product_info.php?products_id=102 was used.
According to this page, 63 meters of 4mm diameter hemp rope was 1kg.
For what we are going to do, we want the radius, so we divide the diameter by half to get 2mm.
We convert 63 meters to 2480.31496 inches, and convert the 2 mm to 0.0787401575.
We then convert from inches to game units, according to http://developer.valvesoftware.com/wiki/Dimensions, by dividing both numbers by .75 (1 game unit = .75 inches).

This gives us 3307.086613 gu and .1049868767 gu, respectively.
By treating the rope as a very tall cylinder, we can get it's volume:
	PI * (0.1049868767 gu)^2 * 3307.086613 gu = 114.5158165 gu^3
Density is mass/volume. We know the rope weighs 1 kg, or 1000 grams. We know that it's volume is 114.5158165 gu^3, so we can use this to calculate the density of the rope.
	d=1000 grams/114.5158165 gu^3 = 8.732418198 grams/gu^3
We then get the volume of our rope; we assume the rope is one gu tall:
	PI * (1.5 gu)^2 * 1 gu = 7.068583471 gu^3
Then we mutliply the density of rope times the volume of our rope to get the mass of our rope:
	7.06883471 gu^3 * 8.732418198 grams/gu^3 = 61.72582693 grams
	
	so, a one unit rope with a radius of 3 has a mass of ~62 grams.
]]--
ITEM.Weight=62;
ITEM.Size=2;			--I'm thinking the rope's "size" is it's radius in game units... this works out to about 1.5.
ITEM.MaxAmount=0;

ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

ITEM.HoldType="normal";

if CLIENT then

ITEM.WorldModelNudge=Vector(2,0,5);
ITEM.WorldModelRotate=Angle(90,0,0);

end

--Rope Item
ITEM.Strength=40000;				--The rope breaks when this much force is applied to it
ITEM.Width=3;						--The rope graphic appears to be this thick
ITEM.Material="cable/rope";			--The rope graphic uses this material
ITEM.FirstEntity=nil;
ITEM.FirstBone=0;
ITEM.FirstAnchor=Vector(0,0,0);

function ITEM:GetDescription()
	--Length of rope in meters
	local len=self:GetAmount()/0.01905;
	if len > 1 then		return self.Description.."It is "..len.." meters long.";
	else				return self.Description.."It is "..(len*100).." centimeters long."
	end
end

--The player can't split the rope directly
function ITEM:CanPlayerSplit(pl)
	return false;
end

if SERVER then

--[[
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
	if !constraint.Rope(ent1,ent2,bone1,bone2,point1,point2,dis,len-dis,self.Strength,self.Width,self.Material,false) then return false end
	
	self:Remove();
	return true;
end

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