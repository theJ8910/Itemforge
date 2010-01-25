--[[
weapon_rockit
SHARED

A gun that fires random crap from it's inventory.
]]--

ITEM.Name="Rock-It Launcher";
ITEM.Description="An odd device that propels ordinary objects at deadly speed.\nThe words \"Vault Dweller\" are etched into the stock. You're not sure who that is.";
ITEM.Base="base_ranged";
ITEM.Weight=6000;		--This thing easily weighs 6kg / over 12 pounds, unloaded.
ITEM.Size=20;
ITEM.ViewModel = "models/weapons/v_physcannon.mdl";
ITEM.WorldModel = "models/weapons/w_physics.mdl";
ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

--Overridden Base Weapon stuff
ITEM.PrimaryDelay=.4;
ITEM.SecondaryDelay=.4;

--Overridden Base Ranged stuff
ITEM.PrimaryClip=1;					--This gun doesn't use clips, but if PrimaryClip is 0, base_ranged thinks the primary doesn't use ammo. We override :GetAmmo so it looks in the clip instead.
ITEM.PrimaryTakes=0;				--This gun doesn't require the item to have any amount

ITEM.PrimaryFireSounds={
Sound("weapons/physcannon/superphys_launch1.wav"),
Sound("weapons/physcannon/superphys_launch2.wav"),
Sound("weapons/physcannon/superphys_launch3.wav"),
Sound("weapons/physcannon/superphys_launch4.wav"),
};

ITEM.DryFireSounds={
	Sound("weapons/physcannon/physcannon_dryfire.wav")
}

ITEM.ReloadDelay=0.5;
ITEM.ReloadSounds={
	Sound("npc/dog/dog_pneumatic1.wav"),
	Sound("npc/dog/dog_pneumatic2.wav")
}

ITEM.MuzzleName="core";			--The gravity gun model has "core" instead of "muzzle"

--Rock-It Launcher
ITEM.UnloadSound=Sound("weapons/physcannon/superphys_hold_loop.wav");


--[[
When a player is holding it and tries to primary attack
]]--
function ITEM:OnPrimaryAttack()
	--This does all the base ranged stuff - determine if we can fire, do cooldown, consume ammo, play sounds, etc
	if !self["base_ranged"].OnPrimaryAttack(self) then return false end
	
	self:Chuck(2000);
	
	return true;
end

--[[
TODO rightclick loads
]]--
function ITEM:OnSecondaryAttack()
	return false;
end

function ITEM:OnReload()
	if !self:CanReload() then return false end

	return self:FindAmmo(function(self,item)
		return self:Load(item,i);
	end);
end

--[[
Overridden from base_ranged.
When this function is called we load items into the gun's inventory instead of the clip.
]]--
function ITEM:Load(item,clip,amt)
	if !self:CanReload() then return false end
	
	local pl=item:GetWOwner();
	
	--TODO when clientside prediction comes the item==self check won't be necessary since the inv will deny it
	if !item || !item:IsValid() || (pl && pl==item:GetWOwner()) || item==self then return false end
	
	--Can't load items into a non-existent inventory
	local inv=self:GetInventory();
	if !inv then return false end
	
	--If we don't insert the item successfully we fail.
	if SERVER then
		if !item:ToInv(inv) && item:IsValid() then return false end
		self:UpdateWireAmmoCount();
	end
	
	self:ReloadEffects();
	self:SetNextBoth(CurTime()+self:GetReloadDelay());
	
	return true;
end

--Returns the gun's inventory.
function ITEM:GetInventory()
	if self.Inventory && !self.Inventory:IsValid() then
		self.Inventory=nil;
	end
	return self.Inventory;
end

--[[
Override so we look in the inventory instead of clips
]]--
function ITEM:GetAmmo(clip)
	local inv=self:GetInventory();
	if !inv then return nil end
	
	return inv:GetFirst();
end

--[[
Chucks an item in the inventory at the given speed.
Clientside, this function does nothing; items have to be sent to world on the server.
If something is killed by the flying object...
	If this gun is held, kill credit goes to the player holding this gun.
	If this gun is in the world, kill credit goes to the gun entity.
This returns true if an item was sent to world and fired.
False is returned otherwise.
]]--
function ITEM:Chuck(speed)
	if CLIENT then return false end
	
	local item=self:GetAmmo(self.PrimaryClip);
	if !item then return false end
	
	local clump=item:GetStartAmount();
	if item:GetAmount()>clump then
		item=item:Split(clump,false);
		if !item then return false end
	end
	
	if self:IsHeld() then
		local pOwner=self:GetWOwner();
		
		local pos=pOwner:GetShootPos();
		local ang=pOwner:EyeAngles();
		local fwd=ang:Forward();
		
		local ent=item:ToWorld(pos,ang);
		
		local phys=ent:GetPhysicsObject();
		if phys && phys:IsValid() then
			phys:SetVelocity(fwd*speed);
			phys:AddAngleVelocity(Angle(math.Rand(-200,200),math.Rand(-200,200),math.Rand(-200,200)));
		end
		ent:SetPhysicsAttacker(pOwner);
		
		return true;
	elseif self:InWorld() then
		local eEnt=self:GetEntity();
		local posang=self:GetMuzzle(self:GetEntity());
		local fwd=posang.Ang:Forward();
		
		local ent=item:ToWorld(posang.Pos,posang.Ang);
		
		local phys=ent:GetPhysicsObject();
		if phys && phys:IsValid() then
			phys:SetVelocity(fwd*speed);
			phys:AddAngleVelocity(Angle(math.Rand(-200,200),math.Rand(-200,200),math.Rand(-200,200)));
		end
		ent:SetPhysicsAttacker(eEnt);
		
		return true;
	elseif self:InInventory() then
		local inv=self:GetContainer();
		item:ToInv(inv);
	end
	return false;
end

--[[
Applies suction force to objects in a funnel positioned at a given origin at given angles.

vOrigin is the origin of the funnel. 
vDir is a vector describing the direction the funnel is facing.

When the funnel is facing Vector(1,0,0) the funnel opens to the right like so (where o s in origin):

         :
       _.
    __`
 ```
o
 ```--._
        `
         :
]]--

local aZero=Angle(0,0,0);
local vZero=Vector(0,0,0);
local fSuctionPower=300
--The funnel begins at x=0, ends at x=fFunnelLength. At it's origin (x=0) it has a radius of fInnerRadius+1 units. At it's wide end, it has a radius of fFunnelWideRadius units.
local fFunnelLength=1000;
local fFunnelLengthInv=1/fFunnelLength;
local fInnerRadius=10;
local fFunnelWideRadius=3000;
--The equation we use to generate the funnel: y=fInnerRadius + fA^x. "fA" must be this number if we want y=fFunnelWideRadius when x=fFunnelLength.
local fA=math.pow(fFunnelWideRadius-fInnerRadius,fFunnelLengthInv);
local BoxBounds=Vector(fFunnelWideRadius,fFunnelWideRadius,fFunnelWideRadius)

function ITEM:Suction(vOrigin,vDir)
	--[[
	--We'll start by eliminating any entities that definitely aren't in the funnel by detecting entities in a box around the funnel
	local vEnd=vOrigin+vDir*fFunnelLength;
	
	local ents=ents.FindInBox(vEnd-BoxBounds,vEnd+BoxBounds);
	local aAng=vDir:Angle();
	local p,e,r,m,phys;
	
		
	for k,v in ipairs(ents) do
		for i=0,v:GetPhysicsObjectCount()-1 do
			phys=v:GetPhysicsObjectNum(i);
			
			
			if phys && phys:IsValid() then
				p=WorldToLocal(phys:GetPos(),aZero,vOrigin,aAng);
				e=math.pow(fA,p.x);
				r=math.sqrt(p.y*p.y+p.z*p.z);
				
				--The radius of the funnel, y, at a given x value from the start, is y=fInnerRadius + fA^x.
				if p.x>=0 && p.x<=400 && r<=fInnerRadius+e then
					if r > fInnerRadius then	m=e*math.log(fA)*(r/e);
					else						m=0;
					end
					phys:ApplyForceCenter(LocalToWorld(Vector(-1,0,-m):Normalize()*fSuctionPower*((fFunnelLength-p.x)*fFunnelLengthInv),aZero,vZero,aAng));
				end
			end
		end
	end
	
	return true;
	]]--
end

IF.Items:CreateNWVar(ITEM,"Unloading","bool",false);