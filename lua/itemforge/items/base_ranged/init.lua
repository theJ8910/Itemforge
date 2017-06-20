--[[
base_ranged
SERVER

base_ranged is a base. That means that other items borrow code from this so they can be created easier.
Any item that inherits from this has everything this item has, and can override anything this item has.

The base_ranged has two purposes:
	It's designed to help you create ranged weapons easier. You just have to change/override some variables or replace some stuff with your own code.
	You can tell if an item is a ranged weapon (like a pistol or RPG) by checking to see if it inherits from base_ranged.
Some features the base_ranged has:
	Ammunition: 
		You can load base_ranged weapons with other items
		The primary/secondary attack consumes ammo from a clip you set (you can also set primary/secondary not to consume ammo)
		You can set how much ammo the primary/secondary consumes per shot
		You can specify how many clips you want your weapon to have (including none).
		You can specify what type of ammo goes in a clip and how much can be loaded into it at a given time (including no limit)
		If ammo is drag-dropped onto the item, it loads it with that ammo; if two or more clips use the same kind of ammo, then it will load whichever clip is empty first.
		A list of reload functions let you set up where the item looks for ammo when it reloads.
	Cooldowns:
		This is based off of base_weapon so you can set primary/secondary delay and auto delay
		You can set a reload delay
		You can set a "dry delay" for when the gun is out of ammo or underwater (for example, the SMG's primary has a 0.08 second cooldown, but if you're out of ammo, it has a 0.5 second cooldown instead)
	Other:
		The item's right click menu has several functions for dealing with ranged weapons; you can fire it's primary/secondary, unload clips, reload, etc, all from the menu.
		Wiremod can fire the gun's primary/secondary attack. It can also reload the gun, if there is ammo nearby.
		You can set whether or not you want the gun's primary/secondary to work underwater
]]--

AddCSLuaFile( "shared.lua" );
AddCSLuaFile( "cl_init.lua" );
AddCSLuaFile( "clips.lua" );
AddCSLuaFile( "ammo.lua" );
AddCSLuaFile( "findammo.lua" );

include( "shared.lua" );
include( "wire.lua" );

ITEM.PrimaryFiring		= false;
ITEM.SecondaryFiring	= false;
ITEM.WasTryingToReload	= false;
ITEM.TryingToReload		= false;




--[[
* SERVER
* Event

When the gun gets removed, also remove any loaded ammo
]]--
function ITEM:OnRemove()
	for i = 1, #self.Clips do
		local itemCurAmmo = self:GetAmmoSource( i );
		if itemCurAmmo then itemCurAmmo:Remove(); end
	end
end

IF.Items:CreateNWCommand( ITEM, "SetAmmoSource",		nil,															 { "int", "item" }	);
IF.Items:CreateNWCommand( ITEM, "Unload",				nil,															 { "int" }			);
IF.Items:CreateNWCommand( ITEM, "PlayerFirePrimary",	function( self, ... ) self:Event( "OnSWEPPrimaryAttack" )	end, {}					);
IF.Items:CreateNWCommand( ITEM, "PlayerFireSecondary",	function( self, ... ) self:Event( "OnSWEPSecondaryAttack" )	end, {}					);
IF.Items:CreateNWCommand( ITEM, "PlayerReload",			function( self, ... ) self:PlayerReload( ... )				end, {}					);
IF.Items:CreateNWCommand( ITEM, "PlayerLoadAmmo",		function( self, ... ) self:PlayerLoadAmmo( ... )			end, { "int", "item" }	);
IF.Items:CreateNWCommand( ITEM, "PlayerUnloadAmmo",		function( self, ... ) self:PlayerUnloadAmmo( ... )			end, { "int" }			);