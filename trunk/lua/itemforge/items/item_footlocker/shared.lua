--[[
item_footlocker
SHARED

A lockable container.
]]--

include("inv_footlocker.lua");

if SERVER then

AddCSLuaFile("shared.lua");
AddCSLuaFile("inv_footlocker.lua")

end

ITEM.Name="Footlocker";
ITEM.Description="A sturdy wooden box with a lock to secure possessions.\n";
ITEM.Base="base_container";
ITEM.WorldModelOpen="models/props/CS_militia/footlocker01_open.mdl";
ITEM.WorldModelClosed="models/props/CS_militia/footlocker01_closed.mdl";
ITEM.WorldModel=ITEM.WorldModelOpen;
ITEM.Size=30;					--This is the bounding radius of the footlocker model.
ITEM.Weight=1000;				--Weighs 1kg (around 2 pounds)
ITEM.MaxHealth=500;

if SERVER then
	ITEM.GibEffect = "wood";
end

ITEM.Spawnable=true;
ITEM.AdminSpawnable=true;

--Overridden Base Container stuff
ITEM.InvTemplate="inv_footlocker";

--Footlocker
ITEM.LockSound=Sound("doors/handle_pushbar_locked1.wav");
ITEM.UnlockSound=Sound("doors/latchunlocked1.wav");
ITEM.CantOpenSound=Sound("doors/latchlocked2.wav");

--[[
Shows the inventory to the given player.
Unless of course it's locked - in that case we'll play a "Can't Open" sound.
]]--
function ITEM:ShowInventory(pl)
	if self:IsLocked() then
		self:EmitSound(self.CantOpenSound);
		return false;
	end
	return self["base_container"].ShowInventory(self,pl);
end

--[[
Is basically the same as Base Container's OnUse,
except if the footlocker is locked, we use the lock item instead.
]]--
function ITEM:OnUse(pl)
	if self:IsLocked() then
		if SERVER then
			local l=self:GetLock();
			if l then return l:Use(pl); end
		else
			return true;
		end
	else
		return self["base_container"].OnUse(self,pl);
	end
end

--[[
Dynamic item description. In addition to the "sturdy wooden box" text (self.Description),
we also tell whether or not the box is locked or not.
If a lock is attached, we include the name of the lock in the description.
]]--
function ITEM:GetDescription()
	local d=self.Description;
	local l=self:GetLock();
	if self:IsLocked() then	d=d.."It is locked.";
	else					d=d.."It is unlocked.";
	end
	if l then				d=d.."\nA "..l:Event("GetName","unknown lock").." is attached.";
	end
	
	return d;
end

--If the footlocker has a lock item, this function returns it.
function ITEM:GetLock()
	return self:GetNWItem("LockItem");
end

--If the footlocker is locked, returns true. False is returned otherwise.
function ITEM:IsLocked()
	if self.Inventory && self.Inventory:IsLocked() then return true end
	return false;
end

if SERVER then




--Runs when a lock item is attached
function ITEM:OnAttachLock(lockItem)
	if self:GetLock() then return false end
	
	lockItem:ToVoid();
	self:SetNWItem("LockItem",lockItem);
	
	return true;
end

--Locks the footlocker; runs when the lock item is locked
function ITEM:Lock()
	self:EmitSound(self.LockSound);
	self.Inventory:Lock();
	self:SetWorldModel(self.WorldModelClosed);
end

--Unlocks the footlocker; runs when the lock item is unlocked
function ITEM:Unlock()
	self:EmitSound(self.UnlockSound);
	self.Inventory:Unlock();
	self:SetWorldModel(self.WorldModelOpen);
end

--The lock can take damage.
function ITEM:OnEntTakeDamage(entity,dmgInfo)
	local lock=self:GetLock();
	
	if lock then
		local totalDamage=dmgInfo:GetDamage();
		local footlockerDamage=totalDamage*.60;
		
		self:Hurt(footlockerDamage,dmgInfo:GetAttacker());
		lock:Hurt(totalDamage-footlockerDamage,dmgInfo:GetAttacker());
	else
		self:Hurt(dmgInfo:GetDamage(),dmgInfo:GetAttacker());
	end
	
	--GetWeaponItem(eWep)
	entity:TakePhysicsDamage(dmgInfo);
end

--Remove any attached lock items
function ITEM:OnRemove()
	local l=self:GetLock();
	if l then l:Remove() end
end




else




function ITEM:OnPopulateMenu(pMenu)
	self["base_container"].OnPopulateMenu(self,pMenu);
	
	--If we have a lock attached, we'll create a submenu that contains everything on it's menu
	local l=self:GetLock();
	if l then
		local name=l:Event("GetName","Unknown Lock");
		local sub=pMenu:AddSubMenu(name);
		l:Event("OnPopulateMenu",nil,sub);
	end
end




end

IF.Items:CreateNWVar(ITEM,"LockItem","item");