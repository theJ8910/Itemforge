--[[
weapon_smg
SHARED

The Itemforge version of the Half-Life 2 SMG.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="H&K MP7";
ITEM.Description="This is a Heckler & Koch MP7, a German-manufactured submachine gun.\nThis weapon is designed for use with 4.6x30mm rounds.\nIt's also fitted with a grenade launcher.";
ITEM.Base="base_firearm";
ITEM.WorldModel="models/weapons/w_smg1.mdl";
ITEM.ViewModel="models/weapons/v_smg1.mdl";
ITEM.Weight=1900;		--1.9kg according to http://en.wikipedia.org/wiki/Heckler_&_Koch_MP7
ITEM.Size=13;
ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

ITEM.HoldType="smg";

--Overridden Base Weapon stuff
ITEM.PrimaryDelay=.08;
ITEM.SecondaryDelay=1;

--Overridden Base Ranged Weapon stuff
ITEM.Clips={};
ITEM.Clips[1]={Type="ammo_smg",Size=45};
ITEM.Clips[2]={Type="ammo_smggrenade",Size=3,BackColor=Color(0,115,183),BarColor=Color(0,159,255)};

ITEM.PrimaryClip=1;
ITEM.PrimaryFiresUnderwater=false;
ITEM.PrimaryFireSounds={	Sound("weapons/smg1/smg1_fire1.wav")	};

ITEM.SecondaryClip=2;
ITEM.SecondaryFiresUnderwater=false;
ITEM.SecondaryFireSounds={	Sound("weapons/grenade_launcher1.wav")	};

ITEM.ReloadDelay=1.5;
ITEM.ReloadSounds={			Sound("weapons/smg1/smg1_reload.wav")	};

--Overridden Base Firearm stuff
ITEM.BulletDamage=12;
ITEM.BulletSpread=Vector(0.04362,0.04362,0.04362); --Taken directly from modcode; this is 5 degrees deviation

--[[
When a player is holding it and tries to secondary attack
]]--
function ITEM:OnSWEPSecondaryAttack()
	--This does all the base ranged stuff - determine if we can fire, do cooldown, consume ammo, play sounds/animations, etc
	if !self["base_firearm"].OnSWEPSecondaryAttack(self) then return false end
	
	self:FireGrenade(1000);
	return true;
end


--[[
Fires a grenade from this gun if it is in the world or held. Doesn't consume ammo, just fires a grenade.
Clientside, this function does nothing; grenades must be created on the server.
If something is killed by the grenade...
	If this gun is held, kill credit goes to the player holding this gun.
	If this gun is in the world, kill credit goes to the gun entity.
This returns true if a grenade was created and launched.
False is returned otherwise.
]]--
function ITEM:FireGrenade(fVel)	
	if CLIENT then return false end
	if self:IsHeld() then
		local pOwner=self:GetWOwner();
		
		local pos=pOwner:GetShootPos();
		local ang=pOwner:GetAimVector();
		
		local nade=ents.Create("grenade_ar2");
		if !nade:IsValid() then return false end
		
		nade:SetPos(pos);
		nade:SetVelocity(ang*fVel);
		nade:SetOwner(pOwner);
		nade:Spawn();
		return true;
	elseif self:InWorld() then
		local eEnt=self:GetEntity();
		local posang=self:GetMuzzle(self:GetEntity());
		
		local pos = posang.Pos;
		local ang = posang.Ang:Forward();
		
		local nade=ents.Create("grenade_ar2");
		if !nade:IsValid() then return false end
		
		nade:SetPos(pos);
		nade:SetVelocity(ang*fVel);
		nade:SetOwner(eEnt);
		nade:Spawn();
		return true;
	end
end