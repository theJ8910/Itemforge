--[[
itemforge_item_held
CLIENT

This SWEP is an 'avatar' of an item. When an item is held, this weapon represents that item.
]]--
include("shared.lua")

language.Add("itemforge_item_held_1","Item (held)");

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

--[[
* CLIENT

When we remove the SWEP, we check to see if our item in question still exists.
If it does, we make sure that the item is still inside of the SWEP.
If it is, we remove the item along with the SWEP.
]]--
function SWEP:OnRemove()
	self.BeingRemoved=true;
	
	--HACK
	self:Unregister();
	
	--Don't re-acquire an item.
	self.Weapon:SetDTInt("i",0);
	
	--Clear the weapon's connection to the item (this weapon "forgets" this item was inside of it)
	local item=self:GetItem();
	if !item then return true end
	self.Item=nil;
	
	--Clear the item's connection to the weapon (the item "forgets" that this was it's weapon)
	item:ToVoid(false,self.Weapon,nil,false)
	
	return true;
end

--[[
* CLIENT

Draw weapon selection menu stuff, hooks into item's OnDrawWeaponSelection hook
]]--
function SWEP:DrawWeaponSelection(x,y,w,h,a)
	local item=self:GetItem();
	if !item then return false end
	
	item:Event("OnSWEPDrawMenu",nil,x,y,w,h,a);
	
	return true;
end

--[[
* CLIENT

Draw view model, hooks into item's OnDrawViewmodel hook
]]--
function SWEP:ViewModelDrawn()
	local item=self:GetItem();
	if !item then return false end
	
	item:Event("OnSWEPDrawViewmodel");
	return true;
end

--[[
* CLIENT

Draw world model, hooks into item's Draw3D hook
]]--
function SWEP:DrawWorldModel()
	local item=self:GetItem();
	if !item then return false end
	
	return true;
end

--[[
* CLIENT

Draw world model, hooks into item's Draw3D hook
]]--
function SWEP:DrawWorldModelTranslucent()
	local item=self:GetItem();
	if !item then return false end
	
	return true;
end

--[[
* CLIENT

Draw HUD while holding this
]]--
function SWEP:DrawHUD()
	local item=self:GetItem();
	if !item then return false end
	
	item:Event("OnSWEPDrawHUD");
	
	return true;
end

--[[
* CLIENT

Should a specific HUD element draw while holding this?
]]--
function SWEP:HUDShouldDraw(name)
	local item=self:GetItem();
	if !item then return true end
	
	return item:Event("OnSWEPHUDShouldDraw",true,name)
end

--[[
* CLIENT

Change player's FOV while holding this
]]--
function SWEP:TranslateFOV(current_fov)
	local item=self:GetItem();
	if !item then return current_fov end
	
	return item:Event("OnSWEPTranslateFOV",current_fov,current_fov);
end

--[[
* CLIENT

Freeze player's view rotation while holding this
]]--
function SWEP:FreezeMovement()
	local item=self:GetItem();
	if !item then return false end
	
	return item:Event("OnSWEPFreezeMovement",false);
end

--[[
* CLIENT

Modify player's mouse sensitivity while holding this
]]--
function SWEP:AdjustMouseSensitivity()
	local item=self:GetItem();
	if !item then return 1 end
	
	return item:Event("OnSWEPAdjustMouseSensitivity",1);
end

--[[
* CLIENT

Runs if the SWEP wants to draw a custom ammo display
]]--
function SWEP:CustomAmmoDisplay()
	local item=self:GetItem();
	if !item then return nil end
	
	return item:Event("OnSWEPCustomAmmoDisplay");
end

--[[
* CLIENT

Items can change the viewmodel position if they want to
]]--
function SWEP:GetViewModelPosition(pos,ang)
	local item=self:GetItem();
	if !item then return pos,ang end
	
	--item:Event("GetSWEPViewModelPosition",false,pos,ang);
	
	--[[
	This is a rare case where I'll do special error handling because the event
	returns multiple variables, which my :Event function can't handle
	]]--
	local bSuccess, newPos, newAng = pcall(item.GetSWEPViewModelPosition,item,pos,ang);
	if !bSuccess then
		ErrorNoHalt("");
		return pos,ang;
	end
	
	return newPos, newAng;
end

--[[
* CLIENT

May allow items to take advantage of this later
Use GetNetworked* functions (entity) to restore data from a save-game
]]--
function SWEP:OnRestore()
end