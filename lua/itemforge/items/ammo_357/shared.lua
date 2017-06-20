--[[
ammo_357
SHARED

This is ammunition for the HL2 .357 Revolver.
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name				= ".357 Ammo";
ITEM.Description		= "This is .357 Smith & Wesson Magnum ammunition.\nRevolving pistols often use this.";
ITEM.Base				= "base_ammo_firearm";
ITEM.Weight				= 8;			--8 grams/bullet, based on Bonded Defense JHP at http://en.wikipedia.org/wiki/.357_Magnum
ITEM.StartAmount		= 6;

ITEM.SWEPHoldType			= "slam";

if CLIENT then

ITEM.Icon				= Material( "itemforge/items/ammo_357" );
ITEM.WorldModelNudge	= Vector( -1, -5, -2 );
ITEM.WorldModelRotate	= Angle( 0, 180, 0 );

end

ITEM.WorldModel			= "models/Items/357ammo.mdl";

--Overridden Base Firearm Ammo stuff
ITEM.BulletSounds		= Sound( "Weapon_357.Single" );

if CLIENT then




--[[
* CLIENT
* Event

We force the .357 ammo to be posed upright
]]--
function ITEM:OnPose3D( eEntity, pnlModelPanel )
	self:PoseUprightRotate( eEntity );
end




end