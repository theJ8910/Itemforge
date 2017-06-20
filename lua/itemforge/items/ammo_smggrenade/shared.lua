--[[
ammo_smggrenade
SHARED

This is ammunition for the SMG's grenade launcher.
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name				= "SMG Grenade";
ITEM.Description		= "40x66mm grenades, fitted for an SMG grenade launcher.\nHighly explosive - use with caution.";
ITEM.Base				= "base_ammo_explosive";
ITEM.Size				= 5;
ITEM.Weight				= 240;			--Based on http://www.aalan.hr/Product-Catalogue/tabid/3622/articleType/ArticleView/articleId/11521/Grenade-for-Grenade-Launcher-40x46mm.aspx
ITEM.StartAmount		= 1;

ITEM.WorldModel			= "models/Items/AR2_Grenade.mdl";

ITEM.SWEPHoldType		= "slam";

if CLIENT then




ITEM.Icon				= Material( "itemforge/items/ammo_smggrenade" );
ITEM.WorldModelNudge	= Vector( 2, 0, 0 );
ITEM.WorldModelRotate	= Angle( 70, 0, 0 );




end

--Overridden Base Explosive Ammo stuff
ITEM.ExplodeDamage		= 30;
ITEM.ExplodeRadius		= 128;