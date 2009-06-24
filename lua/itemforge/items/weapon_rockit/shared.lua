--[[
weapon_rockit
SHARED

A gun that fires random crap from it's inventory.
]]--

ITEM.Name="Rock-It Launcher";
ITEM.Description="An odd device that propels ordinary objects at deadly speed.\nThe words \"Vault Dweller\" are etched into the stock. You're not sure who that is.";
ITEM.Base="base_ranged";
ITEM.ViewModel = "models/weapons/v_physcannon.mdl";
ITEM.WorldModel = "models/weapons/w_physics.mdl";
ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

--Overridden Base Weapon stuff
ITEM.PrimaryDelay=.4;
ITEM.SecondaryDelay=.4;

--Overridden Base Ranged stuff
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


--Returns the gun's inventory.
function ITEM:GetInventory()
	if self.Inventory && !self.Inventory:IsValid() then
		self.Inventory=nil;
	end
	return self.Inventory;
end


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
	
	if self:IsHeld() then
		local pOwner=self:GetWOwner();
		
		local pos=pOwner:GetShootPos();
		local ang=pOwner:EyeAngles();
		local fwd=ang:Forward();
		
		local ent=item:ToWorld(pos,ang);
		
		local phys=ent:GetPhysicsObject();
		if phys && phys:IsValid() then
			phys:SetVelocity(fwd*speed);
			phys:AddAngleVelocity(Angle(math.Rand(-100,100),math.Rand(-100,100),math.Rand(-100,100)));
		end
		ent:SetPhysicsAttacker(pOwner);
		
		return true;
	elseif self:InWorld() then
		local eEnt=self:GetEntity();
		local posang=self:GetMuzzle();
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

IF.Items:CreateNWVar(ITEM,"Unloading","bool",false);