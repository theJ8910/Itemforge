--[[
weapon_axe
SHARED

A hatchet! For chopping wood or as a general purpose melee weapon?
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Axe";
ITEM.Description="A steel hatchet with a sturdy wooden handle.\nNot only is it good for chopping wood, it looks like it could serve as a decent weapon!";
ITEM.Base="base_melee";
--There are actually two copies of this axe's world model; one belongs to Counter-Strike: Source, the other belongs to Half-Life 2: Episode 2. I chose CS:S because I figured more people had that game.
ITEM.WorldModel="models/props/CS_militia/axe.mdl";
ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

--Overridden Base Weapon stuff
ITEM.PrimaryDelay=0.8;

--Overridden Base Melee stuff
ITEM.HitRange=75;
ITEM.HitForce=6;
ITEM.HitDamage=50;

--Axe Weapon
ITEM.FleshyImpactSounds={
	Sound("ambient/machines/slicer1.wav"),
	Sound("ambient/machines/slicer2.wav"),
	Sound("ambient/machines/slicer3.wav"),
	Sound("ambient/machines/slicer4.wav")
}

if CLIENT then
	ITEM.WorldModelNudge=Vector(0,0,7);
	ITEM.WorldModelRotate=Angle(0,90,-90);
end

--Probably could add some wood-chopping function here
function ITEM:OnHit(pOwner,hitent,hitpos,traceRes)
end

--Play a fleshy hit sound if we chopped into flesh, or the standard sound if we didn't
function ITEM:HitSound(traceRes)
	if traceRes.MatType==MAT_FLESH || traceRes.MatType==MAT_BLOODYFLESH || traceRes.MatType==MAT_ALIENFLESH || traceRes.MatType==MAT_ANTLION then
		return self:EmitSound(self.FleshyImpactSounds[math.random(1,#self.FleshyImpactSounds)]);
	end
	return self["base_melee"].HitSound(self);
end