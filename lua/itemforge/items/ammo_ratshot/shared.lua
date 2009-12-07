--[[
ammo_ratshot
SHARED

This is ammunition for the HL2 pistol.
It's Ratshot; these special shells fire pellets like a shotgun.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="9mm Ratshot Ammunition";
ITEM.Description="This is 9mm caliber \"Ratshot\" ammunition.\nRatshot ammunition is loaded with lead shot, causing the pistol to fire like a shotgun.";
ITEM.Base="ammo_pistol";
ITEM.Weight=12;
ITEM.Color=Color(100,100,255,255);	--Purpleish

--Overridden pistol ammo stuff
ITEM.BulletDamage=3;
ITEM.BulletsPerShot=5;
ITEM.BulletSpread=Vector(0.06976,0.06976,0.06976);		--8 degrees of deviation
ITEM.BulletSpreadMax=Vector(0.06976,0.06976,0.06976);	--8 degrees of deviation