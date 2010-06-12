--[[
ammo_pistol
SHARED

This is ammunition for the HL2 pistol.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="9mm Ammunition";
ITEM.Description="This is 9mm caliber ammunition.\n9mm rounds are a very common type of ammunition.\nMany pistols and submachine guns make use of this.";
ITEM.Base="base_ammo";
ITEM.Size=2;
ITEM.Weight=8;
ITEM.StartAmount=20;

ITEM.WorldModel="models/Items/BoxSRounds.mdl";

ITEM.HoldType="normal";

if CLIENT then

ITEM.WorldModelNudge=Vector(13,0,0);
ITEM.WorldModelRotate=Angle(90,0,90);

end

--Pistol Ammo
ITEM.BulletDamage=12;
ITEM.BulletsPerShot=1;
ITEM.BulletSpread=Vector(0.00873,0.00873,0.00873);				--Taken directly from modcode; this is 1 degree deviation
ITEM.BulletSpreadMax=Vector(0.05234,0.05234,0.05234);			--Taken directly from modcode; this is 6 degrees deviation