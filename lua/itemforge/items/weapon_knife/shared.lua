--[[
weapon_knife
SHARED

Kind of sharp.
When the combination stuff comes in the knife could be a useful tool for things like
cutting rope, slicing fruit, etc.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Combat Knife";
ITEM.Description="A combat knife. It's blade may also prove useful for other purposes.";
ITEM.Base="base_melee";
ITEM.Size=10;
ITEM.Weight=238;		--Weight from http://www.crkt.com/Ultima-5in-Black-Blade-Veff-Combo-Edge

ITEM.WorldModel = "models/weapons/w_knife_t.mdl";
ITEM.ViewModel = "models/weapons/v_knife_t.mdl";

if SERVER then
	ITEM.GibEffect = "metal";
end

ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

--Overridden Base Weapon stuff
ITEM.PrimaryDelay=.4;

--Overridden Base Melee stuff
ITEM.HitRange=75;
ITEM.HitForce=1;
ITEM.HitDamage=10;
ITEM.ViewKickMin=Angle(0.5,1.0,0);
ITEM.ViewKickMax=Angle(0.-5,-1.0,0);

--Combat Knife
ITEM.DamageScaleSpeedFactor = 0.01;	--1/100. Speed * this = damage multiplier
ITEM.RopeEndClass="rope_end";

--[[
* SHARED
* Event

If the player is moving fast when he hits the target,
the damage is scaled with repect to speed
]]--
function ITEM:GetHitDamage(traceRes)
	local pl = self:GetWOwner();
	return self.HitDamage + ((pl && pl:GetVelocity():Length() * self.DamageScaleSpeedFactor) || 0);
end

--[[
* SHARED
* Event

Basically same rules as base_melee but we also ignore rope ends
]]--
function ITEM:IsValidHit(vShoot,vAimDir,eHit)
	if eHit:GetClass() == self.RopeEndClass then return false end
	return self:BaseEvent("IsValidHit",nil,vShoot,vAimDir,eHit);
end


if SERVER then

local vZero = Vector(0,0,0);

--[[
* SERVER
Returns the point that a line intersects with a plane.

vPointOnPlane is a point on the plane; if you think of the plane
	as a plate resting on a needle, this is the needle point
vNormalOfPlane is the normal of the plane; this is perpendicular to the
	surface of the plane.


vLineStart is a point on the line.
vLineEnd is another point on the line. They can't be the same point.

This function will fail if the line is parallel to the plane (i.e. the line will never
	intersect).
The function will also fail if vLineEnd and vLineStart are exactly the same.
In either of these cases nil is returned.

Otherwise, the intersection point and the intersect fraction are returned.

The intersect fraction is how far between the intersection point is between
vLineStart and vLineEnd.
	If this is 0, it means the cut is at vLineStart.
	If this is 1, it means the cut is at vLineEnd.
	This can possibly be more than 1 or less than 0. If it is, that means the
	intersection point occured outside of the segment. You can check this if you
	want it to occur on the segment.
]]--
local function LinePlaneIntersect(vPointOnPlane,vNormalOfPlane,vLineStart,vLineEnd)
	local vSlope = vLineEnd - vLineStart;
	if vLineEnd == vLineStart then return nil end
	
	local fNormalVsSlopeDot = vNormalOfPlane:Dot(vSlope);
	if fNormalVsSlopeDot == 0 then return nil end
	
	local t = (vNormalOfPlane:Dot(vPointOnPlane-vLineStart) / fNormalVsSlopeDot);
	return vLineStart + (vSlope* t ), t;
end

--[[
* SERVER

Makes a rope-end at the given position and returns the rope end entity
]]--
function ITEM:MakeRopeHalf(eOriginalRope,eAttachedEnt,iBoneAttachedTo,vLocalPos,fLength,vCutPos)
	--We only bother creating rope segments if they're long enough
	if fLength > 16 then
		local eEnd=ents.Create(self.RopeEndClass);
		if IsValid(eEnd) then
			eEnd:SetPos(vCutPos);
			eEnd:Spawn();
			
			local eRope=constraint.Rope(eAttachedEnt,eEnd,iBoneAttachedTo,0,vLocalPos, vZero, fLength, 0, eOriginalRope.forcelimit, eOriginalRope.width, eOriginalRope.material, eOriginalRope.rigid);
			if IsValid(eRope) && eRope:GetClass() == "phys_lengthconstraint" then
				eEnd:SetAssociatedRope(eRope);
				if eAttachedEnt:GetClass() == self.RopeEndClass then eAttachedEnt:SetAssociatedRope(eRope) end
			else
				self:Error("Couldn't create rope segment.");
				eEnd:Remove();
			end
		else
			self:Error("Couldn't create rope end.");
		end
	end
end


--[[
* SERVER

Takes an entity, bone, and a local position and returns the world position
If the entity is invalid the local position is considered a world position and is returned
If an invalid bone is passed nil is returned.
]]--
local function ConvertLocalToWorld(e,iBone,vLocalPos)
	if !IsValid(e) then return vLocalPos; end
	
	local physbone = e:GetPhysicsObjectNum(iBone);
	if IsValid(physbone) then return physbone:LocalToWorld(vLocalPos) end
	return nil;
end

--[[
* SERVER

Returns true if the rope is a gmod rope (i.e. is not naturally a part of the map).
Also caches whether the rope is a gmod rope or not so the test isn't done twice.
]]--
local function IsGMODRope(eLC)
	if eLC.ItemforgeGMODRope==nil then
		eLC.ItemforgeGMODRope=(nil!=(eLC.Bone1 && eLC.Bone2 && eLC.LPos1 && eLC.LPos2 && eLC.length && eLC.forcelimit && eLC.width && eLC.material && eLC.rigid));
	end
	
	return eLC.ItemforgeGMODRope;
end

--[[
* SERVER

This function cuts any ropes the knife can see.
The cut is performed if it's determined the knife has cut the rope.

The way this is done is by testing the rope as a line against the planes whose normals are the other vectors given.
]]--
function ITEM:CutRopes(vShoot,vAim,...)
	local vUp = vAim:Angle():Up();
	
	for k,v in pairs(ents.FindByClass("phys_lengthconstraint")) do
		if IsGMODRope(v) then
			local eAttached1 = v.Ent1;
			local eAttached2 = v.Ent2;
			
			local vWorldPos1 = ConvertLocalToWorld(eAttached1, v.Bone1, v.LPos1);
			local vWorldPos2 = ConvertLocalToWorld(eAttached2, v.Bone2, v.LPos2);
			
			--[[
			Rope has to be taut for a cut to work because I don't have any reliable way
			of knowing where the rope segments are in any other case. The 30 inches here is
			kind of arbitrary and could be determined dynamically based on rope length I think
			(i.e. if the distance between the two world positions is close to the actual length of the rope, it appears as fairly straight)
			]]--
			if vWorldPos1 && vWorldPos2 && vWorldPos1:Distance(vWorldPos2) >= v.length-30 then
				local vCutPos,fFrac = LinePlaneIntersect(vShoot,vUp,vWorldPos1,vWorldPos2);
				
				--[[
				The intersect needs to occur on the rope, and the cut has to be possible given the melee weapon's range of attack and the player's facing direction.
				Another way of thinking of these tests is as a shape.
				A plane is like an infinite piece of paper. The distance check cuts a circle out from that,
				and the dot product cuts off all but 90 degrees worth of that circle. If the rope, which can
				be visualized as a line segment intersects with this shape, a cut has occured.
				The > 0 and < 1 checks are to ensure that the intersection actually occured on the line seg and not off of it.
				NOTE: 0.70721 = cos(45 degrees)
				]]--
				if fFrac > 0 && fFrac < 1 && vAim:Dot((vCutPos-vShoot):Normalize()) > 0.70721 && vShoot:Distance(vCutPos) <= self:Event("GetHitRange",75) then
					local l = v.length + v.addlength;
					
					--Make two halves on either side of the cut position
					self:MakeRopeHalf(v,eAttached1,v.Bone1,v.LPos1,l*fFrac,vCutPos);
					self:MakeRopeHalf(v,eAttached2,v.Bone2,v.LPos2,l*(1-fFrac),vCutPos);
					
					--Remove the original rope
					v:Remove();
				end
			end
		end
	end
end

--[[
* SERVER
* Event

Does everything a normal hit does but we also cut ropes
]]--
function ITEM:OnHit(vShoot,vAim,traceRes,bIndirectHit)
	self:BaseEvent("OnHit",nil,vShoot,vAim,traceRes,bIndirectHit);
	self:CutRopes(vShoot,vAim);
end

--[[
* SERVER
* Event

Does everything a normal miss does but we also cut ropes
]]--
function ITEM:OnMiss(vShoot,vAim,traceRes)
	self:BaseEvent("OnMiss",nil,vShoot,vAim,traceRes);
	self:CutRopes(vShoot,vAim);
end



end