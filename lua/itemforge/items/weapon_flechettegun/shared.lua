--[[
weapon_flechettegun
SHARED

A gun that fires hunter flechettes. Adapted from the GMod flechette gun.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Flechette Gun";
ITEM.Description="A standard pistol, modified to fire hunter flechettes instead.";
ITEM.Base="base_ranged";
ITEM.Weight=850;			--This is somewhat arbitrary. It's heavier than the H&K USP Match, which the Flechette Gun resembles somewhat.
ITEM.Size=7;
ITEM.ViewModel = "models/weapons/v_pistol.mdl";
ITEM.WorldModel = "models/weapons/w_pistol.mdl";

if SERVER then
	ITEM.GibEffect = "metal";
end

ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

--Overridden Base Weapon stuff
ITEM.PrimaryDelay=.1;
ITEM.SecondaryDelay=.1;

--Overridden Base Ranged stuff
ITEM.Clips={};
ITEM.Clips[1]={Type="ammo_flechette",Size=30};
ITEM.PrimaryClip=1;
ITEM.PrimaryFireSounds={Sound("NPC_Hunter.FlechetteShoot")};

--[[
When a player is holding it and tries to primary attack
]]--
function ITEM:OnSWEPPrimaryAttack()
	--This does all the base ranged stuff - determine if we can fire, do cooldown, consume ammo, play sounds, etc
	if !self["base_ranged"].OnSWEPPrimaryAttack(self) then return false end
	
	self:ShootFlechette(2000);
	
	return true;
end

--[[
The secondary attack does nothing
]]--
function ITEM:OnSWEPSecondaryAttack()
	return false;
end

--[[
Fires a flechette from the gun at the given speed. Doesn't consume ammo, just fires a flechette.
Clientside, this function does nothing; flechettes must be created on the server.
If something is killed by the flechette...
	If this gun is held, kill credit goes to the player holding this gun.
	If this gun is in the world, kill credit goes to the gun entity.
This returns true if a flechette was created and fired.
False is returned otherwise.
]]--
function ITEM:ShootFlechette(speed)
	if CLIENT then return false end
	if self:IsHeld() then
		local pOwner=self:GetWOwner();
		
		local pos=pOwner:GetShootPos();
		local ang=pOwner:EyeAngles();
		local fwd=ang:Forward();
		
		local ent=ents.Create("hunter_flechette");
		if !ent || !ent:IsValid() then return false end
		ent:SetPos(pos+fwd*32);
		ent:SetAngles(ang);
		ent:SetVelocity(fwd*speed);
		ent:SetOwner(pOwner);
		ent:Spawn();
		return true;
	elseif self:InWorld() then
		local eEnt=self:GetEntity();
		local posang=self:GetMuzzle(self:GetEntity());
		
		local pos=posang.Pos;
		local ang=posang.Ang;
		local fwd=ang:Forward();
		
		local ent=ents.Create("hunter_flechette");
		if !ent || !ent:IsValid() then return false end
		ent:SetPos(pos+fwd*32);
		ent:SetAngles(ang);
		ent:SetVelocity(fwd*speed);
		ent:SetOwner(eEnt);
		ent:Spawn();
		return true;
	end
	return false;
end
