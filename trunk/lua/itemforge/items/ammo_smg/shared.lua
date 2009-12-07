--[[
ammo_smg
SHARED

Submachine Gun ammo.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="SMG Ammo";
ITEM.Description="A bucket of 4.6x30mm rounds; brass-jacketed, steel core.";
ITEM.Base="base_ammo";
ITEM.Weight=2;		--Two grams per bullet, based upon the "DM11 Penetrator" type taken from http://en.wikipedia.org/wiki/4.6x30mm
ITEM.Size=2;
ITEM.StartAmount=45;

ITEM.WorldModel="models/Items/BoxMRounds.mdl";

if SERVER then

ITEM.HoldType="normal";

else

ITEM.WorldModelNudge=Vector(12,0,8);
ITEM.WorldModelRotate=Angle(0,90,180);

end