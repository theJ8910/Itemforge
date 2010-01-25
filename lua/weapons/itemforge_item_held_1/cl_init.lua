--[[
itemforge_item_held_1
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
When we remove the SWEP, we check to see if our item in question still exists.
If it does, we make sure that the item is still inside of the SWEP.
If it is, we remove the item along with the SWEP.
]]--
function SWEP:OnRemove()
	self.BeingRemoved=true;
	
	--HACK
	self:Unregister();
	
	--Don't re-acquire an item.
	self.Weapon:SetNWInt("i",0);
	
	--Clear the weapon's connection to the item (this weapon "forgets" this item was inside of it)
	local item=self:GetItem();
	if !item then return true end
	self.Item=nil;
	
	--Clear the item's connection to the weapon (the item "forgets" that this was it's weapon)
	item:ToVoid(false,self.Weapon,nil,false)
	
	return true;
end

--Draw weapon selection menu stuff, hooks into item's OnDrawWeaponSelection hook
function SWEP:DrawWeaponSelection(x,y,w,h,a)
	local item=self:GetItem();
	if !item then return false end
	
	item:Event("OnSWEPDrawMenu",nil,x,y,w,h,a);
	
	return true;
end

--Draw view model, hooks into item's OnDrawViewmodel hook
function SWEP:ViewModelDrawn()
	local item=self:GetItem();
	if !item then return false end
	
	item:Event("OnSWEPDrawViewmodel");
	return true;
end

--Draw world model, hooks into item's Draw3D hook
function SWEP:DrawWorldModel()
	local item=self:GetItem();
	if !item then return false end
	
	return true;
end

--Draw world model, hooks into item's Draw3D hook
function SWEP:DrawWorldModelTranslucent()
	local item=self:GetItem();
	if !item then return false end
	
	return true;
end

--Draw HUD while holding this
function SWEP:DrawHUD()
	local item=self:GetItem();
	if !item then return false end
	
	item:Event("OnSWEPDrawHUD");
	
	return true;
end

--Change player's FOV while holding this
function SWEP:TranslateFOV(current_fov)
	local item=self:GetItem();
	if !item then return current_fov end
	
	return item:Event("OnSWEPTranslateFOV",current_fov,current_fov);
end

--Freeze player's view rotation while holding this
function SWEP:FreezeMovement()
	local item=self:GetItem();
	if !item then return false end
	
	return item:Event("OnSWEPFreezeView",false);
end

--Modify player's mouse sensitivity while holding this
function SWEP:AdjustMouseSensitivity()
	local item=self:GetItem();
	if !item then return 1 end
	
	return item:Event("OnSWEPAdjustMouseSensitivity",1);
end

--May allow items to take advantage of this later
function SWEP:CustomAmmoDisplay()
end

--[[
May allow items to take advantage of this later
Use GetNetworked* functions (entity) to restore data from a save-game
]]--
function SWEP:OnRestore()
end

--May allow items to take advantage of this later
function SWEP:GetViewModelPosition(pos,ang)
	return pos,ang;
end