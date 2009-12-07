--[[
ammo_crossbow
SHARED

This is ammunition for the HL2 Crossbow.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="Rebar";
ITEM.Description="Steel rebar. Often used in construction to reinforce concrete.\nHowever, rumor has it that a new type of rebel weaponry uses this as ammunition.";
ITEM.Base="base_ammo";
ITEM.Size=9;
ITEM.Weight=2828.90732;			--This was calculated in two ways. Through eye traces I determined the rebar had a diameter of 1 inch. I estimated the length of a rebar segment to be 28 (due to it's physics model, eye traces told me it was bigger). From there I got the volume of a cylinder with that radius and multiplied it by the density of steel (first on http://hypertextbook.com/facts/2004/KarenSutherland.shtml). Then I double checked my answer with this page: http://www.sizes.com/materls/rebar.htm. I converted the weight of 1-inch diameter rebar from pounds/foot to grams/inch and multiplied by 28 to get an answer that was only 3 grams different. So this should be a pretty reasonable estimate.
ITEM.StartAmount=6;

ITEM.WorldModel="models/Items/CrossbowRounds.mdl";

if SERVER then

ITEM.HoldType="normal";

else

ITEM.WorldModelNudge=Vector(0,0,0);
ITEM.WorldModelRotate=Angle(0,0,0);

end