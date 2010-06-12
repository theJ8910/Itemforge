--[[
ammo_smggrenade
SHARED

This is ammunition for the SMG's grenade launcher.
]]--

if SERVER then AddCSLuaFile("shared.lua") end

ITEM.Name="SMG Grenade";
ITEM.Description="40x66mm grenades, fitted for an SMG grenade launcher.";
ITEM.Base="base_ammo";
ITEM.Size=5;
ITEM.Weight=240;		--Based on http://www.aalan.hr/Product-Catalogue/tabid/3622/articleType/ArticleView/articleId/11521/Grenade-for-Grenade-Launcher-40x46mm.aspx
ITEM.StartAmount=1;

ITEM.WorldModel="models/Items/AR2_Grenade.mdl";

ITEM.HoldType="slam";

if CLIENT then

ITEM.WorldModelNudge=Vector(2,0,0);
ITEM.WorldModelRotate=Angle(70,0,0);

end