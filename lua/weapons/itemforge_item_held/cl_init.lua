--[[
itemforge_item_held
CLIENT

This SWEP is an 'avatar' of an item. When an item is held, this weapon represents that item.
]]--
include( "shared.lua" );

language.Add( "itemforge_item_held_1", "Item (held)" );

SWEP.PrintName			= "Itemforge Item";

SWEP.Slot				= 0;
SWEP.SlotPos			= 5;
SWEP.DrawAmmo			= false;
SWEP.DrawCrosshair		= true;
SWEP.DrawWeaponInfoBox	= false;
SWEP.BounceWeaponIcon   = false;
SWEP.SwayScale			= 1.0;
SWEP.BobScale			= 1.0;
SWEP.RenderGroup 		= RENDERGROUP_OPAQUE;

SWEP.ViewModelFOV		= 62;
SWEP.ViewModelFlip		= false;

SWEP.HasInitialized		= false;			--This will be true if the weapon has already been initialized, or false if it hasn't.

local ItemEvents = {};						--Item events are SWEP events that call when an item is set
local ItemlessEvents = {};					--Itemless events are SWEP events that call when an item is not set

--[[
* CLIENT
* Event

When we remove the SWEP, we check to see if our item in question still exists.
If it does, we make sure that the item is still inside of the SWEP.
If it is, we remove the item along with the SWEP.
]]--
function SWEP:OnRemove()
	self.BeingRemoved = true;
	
	--HACK
	self:Unregister();

	--Clear the weapon's connection to the item (this weapon "forgets" this item was inside of it)
	local item = self:GetItem();
	if !item then return true end
	self:SetItem( nil );

	--Clear the item's connection to the weapon (the item "forgets" that this was it's weapon)
	item:ToVoid( false, self.Weapon, nil, false );
	
	return true;
end

--[[
* CLIENT
* Event

Draw weapon selection menu stuff
]]--
function ItemlessEvents:DrawWeaponSelection( fX, fY, fW, fH, fA )
end
function ItemEvents:DrawWeaponSelection( fX, fY, fW, fH, fA )
	return self:GetItem():Event( "OnSWEPDrawMenu", nil, fX, fY, fW, fH, fA );
end

--[[
* CLIENT
* Event

Draw view model, hooks into item's OnDrawViewmodel hook
]]--
function ItemlessEvents:ViewModelDrawn()
end
function ItemEvents:ViewModelDrawn()
	return self:GetItem():Event( "OnSWEPDrawViewmodel" );
end

--[[
* CLIENT
* Event

Does nothing (we use Itemforge Gear for the SWEP world model)
]]--
function SWEP:DrawWorldModel()
end

--[[
* CLIENT
* Event

Does nothing in either case (we use Itemforge Gear for the SWEP world model
]]--
function SWEP:DrawWorldModelTranslucent()
end

--[[
* CLIENT
* Event

Draw stuff on the HUD while holding this weapon
]]--
function ItemlessEvents:DrawHUD()
end
function ItemEvents:DrawHUD()
	return self:GetItem():Event( "OnSWEPDrawHUD" );
end

--[[
* CLIENT
* Event

Should a specific HUD element draw while holding this?
]]--
function ItemlessEvents:HUDShouldDraw( strElementName )
	return true;
end
function ItemEvents:HUDShouldDraw( strElementName )
	return self:GetItem():Event( "OnSWEPHUDShouldDraw", true, strElementName );
end

--[[
* CLIENT
* Event

Change player's FOV while holding this
]]--
function ItemlessEvents:TranslateFOV( fCurrentFOV )
	return fCurrentFOV;
end
function ItemEvents:TranslateFOV( fCurrentFOV )
	return self:GetItem():Event( "OnSWEPTranslateFOV", fCurrentFOV, fCurrentFOV );
end

--[[
* CLIENT
* Event

Freeze player's view rotation while holding this
]]--
function ItemlessEvents:FreezeMovement()
	return false;
end
function ItemEvents:FreezeMovement()
	return self:GetItem():Event( "OnSWEPFreezeMovement", false );
end

--[[
* CLIENT
* Event

Modify player's mouse sensitivity while holding this
]]--
function ItemlessEvents:AdjustMouseSensitivity()
	return 1;
end
function ItemEvents:AdjustMouseSensitivity()
	return self:GetItem():Event( "OnSWEPAdjustMouseSensitivity", 1 );
end

--[[
* CLIENT
* Event

Runs if the SWEP wants to draw a custom ammo display
]]--
function ItemlessEvents:CustomAmmoDisplay()
end
function ItemEvents:CustomAmmoDisplay()
	return self:GetItem():Event( "OnSWEPCustomAmmoDisplay" );
end

--[[
* CLIENT
* Event

Items can change the viewmodel position if they want to
]]--
function ItemlessEvents:GetViewModelPosition( vOldPos, angOldAng )
	return vOldPos, angOldAng;
end
function ItemEvents:GetViewModelPosition( vOldPos, angOldAng )
	local item = self:GetItem();
	
	--[[
	This is a rare case where I'll do special error handling because the event
	returns multiple variables, which my :Event function can't handle
	]]--
	local bSuccess, vNewPos, angNewAng = pcall( item.GetSWEPViewModelPosition, item, vOldPos, angOldAng );
	if !bSuccess then
		item:Error( "\"GetSWEPViewModelPosition\" failed: "..vNewPos );
		return vOldPos, angOldAng;
	end
	
	return vNewPos, angNewAng;
end

--The ItemEvents version of these functions are defined in shared.lua

function ItemlessEvents:IFHolster()
end
ItemEvents.IFHolster = SWEP.IFHolster;

function ItemlessEvents:Holster()
	return true;
end
ItemEvents.Holster = SWEP.Holster;

function ItemlessEvents:IFDeploy()
end
ItemEvents.IFDeploy = SWEP.IFDeploy;

function ItemlessEvents:Deploy()
	return true;
end
ItemEvents.Deploy = SWEP.Deploy;

function ItemlessEvents:PrimaryAttack()
end
ItemEvents.PrimaryAttack = SWEP.PrimaryAttack;

function ItemlessEvents:SecondaryAttack()
end
ItemEvents.SecondaryAttack = SWEP.SecondaryAttack;

function ItemlessEvents:CheckReload()
	return true;
end
ItemEvents.CheckReload = SWEP.CheckReload;

function ItemlessEvents:Reload()
end
ItemEvents.Reload = SWEP.Reload;

function ItemlessEvents:Think()
end
ItemEvents.Think = SWEP.Think;

function ItemlessEvents:ContextScreenClick( vAimVec, eMouseCode, bPressed, pl )
end
ItemEvents.ContextScreenClick = SWEP.ContextScreenClick;

--[[
* CLIENT
* Event

May allow items to take advantage of this later
Use GetNetworked* functions (entity) to restore data from a save-game
]]--
function SWEP:OnRestore()
end

--[[
* CLIENT

Reconfigures the SWEP to use Itemless events
]]--
function SWEP:SwapToItemlessEvents()
	for k, v in pairs( ItemlessEvents ) do
		self[k] = v;
	end
end

--[[
* CLIENT

Reconfigures the SWEP to use Item events
]]--
function SWEP:SwapToItemEvents()
	for k, v in pairs( ItemEvents ) do
		self[k] = v;
	end
end

--Calling this here makes the class itself default to itemless events
SWEP:SwapToItemlessEvents();