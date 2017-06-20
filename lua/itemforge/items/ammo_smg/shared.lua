--[[
ammo_smg
SHARED

Submachine Gun ammo.
]]--

if SERVER then AddCSLuaFile( "shared.lua" ) end

ITEM.Name				= "SMG Ammo";
ITEM.Description		= "A bucket of 4.6x30mm rounds; brass-jacketed, steel core.";
ITEM.Base				= "base_ammo_firearm";
ITEM.Weight				= 2;			--Two grams per bullet, based upon the "DM11 Penetrator" type taken from http://en.wikipedia.org/wiki/4.6x30mm
ITEM.Size				= 2;
ITEM.StartAmount		= 45;

ITEM.WorldModel			= "models/Items/BoxMRounds.mdl";

ITEM.SWEPHoldType		= "normal";

if CLIENT then




ITEM.Icon				= Material( "itemforge/items/ammo_smg" );
ITEM.WorldModelNudge	= Vector( 12, 0, 8 );
ITEM.WorldModelRotate	= Angle( 0, 90, 180 );




end

--Overridden Base Firearm Ammo stuff
ITEM.BulletSounds		= Sound( "Weapon_SMG1.Single" );

--[[
* CLIENT
* Event

We force the SMG ammo to be posed upright.
]]--
function ITEM:OnPose3D( eEntity, pnlModelPanel )
	self:PoseUprightRotate( eEntity );
end